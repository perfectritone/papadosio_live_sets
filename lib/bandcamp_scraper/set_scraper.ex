defmodule BandcampScraper.SetScraper do
  alias BandcampScraper.Music.DateExtractor

  @bandcamp_domain "https://papadosio.bandcamp.com"

  @doc """
  Scrapes a set page and returns songs and release date.

  Returns `{songs, release_date}` where release_date is the Bandcamp upload date.
  """
  def scrape_set(urn) do
    html = set_url(urn) |> page_body()
    {extract_songs(html), extract_release_date(html)}
  end

  @doc """
  Scrapes only the songs from a set page (legacy compatibility).
  """
  def scrape_songs(urn) do
    set_url(urn)
    |> page_body
    |> extract_songs
  end

  defp set_url(urn) do
    @bandcamp_domain
    |> URI.parse
    |> Map.put(:path, urn)
    |> URI.to_string()
  end

  defp page_body(url) do
    HTTPoison.get!(url).body
  end

  defp extract_songs(html) do
    {:ok, doc} = Floki.parse_document(html)

    Floki.find(doc, "td.title-col .title")
    |> Enum.map(&extract_song/1)
    |> Enum.reject(fn item -> item[:duration] == nil end)
  end

  defp extract_release_date(html) do
    # Extract datePublished from JSON-LD script tag
    case Regex.run(~r/"datePublished"\s*:\s*"([^"]+)"/, html) do
      [_, date_str] -> parse_bandcamp_date(date_str)
      nil -> nil
    end
  end

  # Parse Bandcamp date format: "01 Jul 2025 00:10:24 GMT"
  defp parse_bandcamp_date(date_str) do
    case Regex.run(~r/(\d{1,2})\s+(\w+)\s+(\d{4})/, date_str) do
      [_, day, month, year] ->
        month_num = month_to_number(month)
        case Date.new(String.to_integer(year), month_num, String.to_integer(day)) do
          {:ok, date} -> date
          _ -> nil
        end
      nil -> nil
    end
  end

  defp month_to_number(month) do
    %{
      "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4,
      "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8,
      "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12
    }[month] || 1
  end

  defp extract_song(html_tree) do
    %{
      title: parse_title(html_tree),
      urn: parse_urn(html_tree),
      duration: parse_duration(html_tree)
    }
  end

  defp parse_title(html_tree) do
    html_tree
    |> Floki.find("a")
    |> Floki.find(".track-title")
    |> Floki.text
    |> DateExtractor.strip_zero_width()
  end

  defp parse_urn(html_tree) do
    html_tree
    |> Floki.find("a")
    |> Floki.attribute("href")
    |> List.first
  end

  defp parse_duration(html_tree) do
    html_tree
    |> Floki.find(".time")
    |> Floki.text
    |> String.trim
    |> duration_string_to_seconds
  end

  def duration_string_to_seconds(""), do: nil
  def duration_string_to_seconds(raw_duration) do
    [minutes, seconds] = String.split(raw_duration, ":")
                         |> Enum.map(&String.to_integer/1)

    seconds + minutes * 60
  end
end
