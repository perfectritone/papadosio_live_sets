defmodule BandcampScraper.Music.DateExtractor do
  @moduledoc """
  Extracts dates from set titles.

  Supports common date formats found in set titles:
  - M.D.YY or MM.DD.YY (e.g., "6.21.25", "12.31.24", "01.25.25")
  - M.D.YYYY or MM.DD.YYYY (e.g., "6.21.2025")
  - M/D/YY or MM/DD/YY (e.g., "6/21/25")
  - M-D-YY or MM-DD-YY (e.g., "6-21-25")
  - YYYY-MM-DD (e.g., "2014-04-05")
  - YYYY - M.D (e.g., "2016 - 9.24")
  - Dates in parentheses (e.g., "(12.20.14)")
  - Dates at beginning of title (e.g., "4.7.18. The Orange Peel")
  - Bullet separators (e.g., "• 12.13.14 •")
  """

  # Zero-width characters that Bandcamp sometimes inserts
  @zero_width_chars [
    "\u200B",  # zero-width space
    "\u200C",  # zero-width non-joiner
    "\u200D",  # zero-width joiner
    "\uFEFF"   # zero-width no-break space (BOM)
  ]

  @doc """
  Strips zero-width Unicode characters from a string.
  """
  def strip_zero_width(nil), do: nil
  def strip_zero_width(str) do
    Enum.reduce(@zero_width_chars, str, fn char, acc ->
      String.replace(acc, char, "")
    end)
  end

  @doc """
  Extracts a date from a set title.

  Returns `{:ok, date}` if a valid date is found, or `:error` if not.

  ## Examples

      iex> extract_date("Summer Sequence | Pisgah Brewing | 6.21.25")
      {:ok, ~D[2025-06-21]}

      iex> extract_date("Holidosio Night Three | 12.21.24")
      {:ok, ~D[2024-12-21]}

      iex> extract_date("2014-04-05 - Concord Music Hall")
      {:ok, ~D[2014-04-05]}

      iex> extract_date("Some Title Without Date")
      :error

  """
  def extract_date(nil), do: :error
  def extract_date(title) do
    # Strip zero-width chars and normalize bullet separators
    clean_title = title
      |> strip_zero_width()
      |> String.replace("•", "-")

    # Try different patterns (order matters - most specific first)
    with :error <- try_iso_date(clean_title),
         :error <- try_dotted_date_end(clean_title),
         :error <- try_dotted_date_middle(clean_title),
         :error <- try_dotted_date_start(clean_title),
         :error <- try_parenthetical_date(clean_title),
         :error <- try_year_then_md(clean_title),
         :error <- try_multidate(clean_title),
         :error <- try_slashed_date(clean_title),
         :error <- try_dashed_mdy_date(clean_title),
         :error <- try_merged_day_year(clean_title) do
      :error
    end
  end

  @doc """
  Extracts a date from a title, returning nil if not found.

  ## Examples

      iex> extract_date!("Show | 6.21.25")
      ~D[2025-06-21]

      iex> extract_date!("No date here")
      nil

  """
  def extract_date!(title) do
    case extract_date(title) do
      {:ok, date} -> date
      :error -> nil
    end
  end

  # Pattern: YYYY-MM-DD or YYYY-M-D (ISO format, usually at start)
  defp try_iso_date(title) do
    case Regex.run(~r/(\d{4})-(\d{1,2})-(\d{1,2})/, title) do
      [_, year, month, day] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: M.D.YY or MM.DD.YY at end of title
  defp try_dotted_date_end(title) do
    case Regex.run(~r/(\d{1,2})\.(\d{1,2})\.(\d{2,4})\s*$/, title) do
      [_, month, day, year] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: M.D.YY in middle of title (e.g., "Festival - 8.26.16 - Location")
  defp try_dotted_date_middle(title) do
    case Regex.run(~r/[|\-]\s*(\d{1,2})\.(\d{1,2})\.(\d{2,4})\s*[|\-]/, title) do
      [_, month, day, year] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: M.D.YY at start of title (e.g., "4.7.18. The Orange Peel")
  defp try_dotted_date_start(title) do
    case Regex.run(~r/^(\d{1,2})\.(\d{1,2})\.(\d{2,4})\.?\s/, title) do
      [_, month, day, year] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: M/D/YY or MM/DD/YY
  defp try_slashed_date(title) do
    case Regex.run(~r/(\d{1,2})\/(\d{1,2})\/(\d{2,4})/, title) do
      [_, month, day, year] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: M-D-YY or MM-DD-YY (but not YYYY-MM-DD which is handled above)
  defp try_dashed_mdy_date(title) do
    case Regex.run(~r/(\d{1,2})-(\d{1,2})-(\d{2})(?!\d)/, title) do
      [_, month, day, year] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: (M.D.YY) - date in parentheses (e.g., "Earth Night IV: CBUS (12.20.14)")
  defp try_parenthetical_date(title) do
    case Regex.run(~r/\((\d{1,2})\.(\d{1,2})\.(\d{2,4})\)/, title) do
      [_, month, day, year] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: YYYY - M.D (e.g., "Live at Resonance 2016 - 9.24 - Thornville, OH")
  defp try_year_then_md(title) do
    case Regex.run(~r/(\d{4})\s*-\s*(\d{1,2})\.(\d{1,2})(?:\s*-|$)/, title) do
      [_, year, month, day] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: M.D.YY + M.D.YY (multi-date, take the first one)
  defp try_multidate(title) do
    case Regex.run(~r/(\d{1,2})\.(\d{1,2})\.(\d{2,4})\s*\+/, title) do
      [_, month, day, year] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  # Pattern: M.DDYY - merged day and year (e.g., "10.1924" = 10/19/24)
  defp try_merged_day_year(title) do
    case Regex.run(~r/(\d{1,2})\.(\d{2})(\d{2})(?!\d)/, title) do
      [_, month, day, year] -> parse_date(month, day, year)
      nil -> :error
    end
  end

  defp parse_date(month_str, day_str, year_str) do
    with {month, ""} <- Integer.parse(month_str),
         {day, ""} <- Integer.parse(day_str),
         {year, ""} <- Integer.parse(year_str),
         year <- normalize_year(year),
         {:ok, date} <- Date.new(year, month, day) do
      {:ok, date}
    else
      _ -> :error
    end
  end

  # Convert 2-digit year to 4-digit
  # Assumes 00-49 = 2000-2049, 50-99 = 1950-1999
  defp normalize_year(year) when year < 50, do: 2000 + year
  defp normalize_year(year) when year < 100, do: 1900 + year
  defp normalize_year(year), do: year
end
