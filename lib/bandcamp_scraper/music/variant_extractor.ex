defmodule BandcampScraper.Music.VariantExtractor do
  @moduledoc """
  Extracts variant information from set_song titles.

  Variants include:
  - Parts: 1/2, 2/2, Pt 2, Part 1
  - Extended: XL
  - Nights: (Night 1), (Night 2)
  - Dates: (5.3.13), (2.16.13)
  - Transitions: > at end
  - Acoustic: (Acoustic)
  - Guests: ft. Name, w/ Name
  - Reprises: Reprise
  - Versions: v2, 2.0
  - Intros: Intro at end
  - Covers: (Artist Name) for known artists
  - Remixes: - (Name Remix)
  """

  alias BandcampScraper.Repo
  alias BandcampScraper.Music.Variant

  @known_cover_artists ~w(
    Radiohead Bowie Moby NIN Daft\ Punk Smashing\ Pumpkins Telefon\ Tel\ Aviv
    Boards\ of\ Canada Led\ Zeppelin Pink\ Floyd Nine\ Inch\ Nails Gorillaz
    Röyksopp Orbital RATATAT Crystal\ Method Spacehog ESKMO John\ Lennon
    Aphex\ Twin Bluetech
  )

  @doc """
  Parses a title and extracts variants.

  Returns `{cleaned_title, [{name, category}, ...]}`.

  ## Examples

      iex> parse_title("Find Your Cloud (5.3.13)")
      {"Find Your Cloud", [{"5.3.13", "date"}]}

      iex> parse_title("Snorkle ft. Nick Gerlach")
      {"Snorkle", [{"ft. Nick Gerlach", "guest"}]}

  """
  def parse_title(nil), do: {"", []}
  def parse_title(title) do
    {title, variants} = {title, []}

    # Order matters - extract from most specific to least

    # Parts: 1/2, 2/2, Pt 2, Part 1
    {title, variants} = extract_pattern(title, variants, ~r/\s+(\d+\/\d+)$/, "part")
    {title, variants} = extract_pattern(title, variants, ~r/\s+Pt\.?\s*(\d+)$/i, "part", fn m -> "Part #{m}" end)
    {title, variants} = extract_pattern(title, variants, ~r/\s+Part\s+(\d+)$/i, "part", fn m -> "Part #{m}" end)

    # Extended: XL
    {title, variants} = extract_pattern(title, variants, ~r/\s+XL$/i, "extended", fn _ -> "XL" end)

    # Nights: (Night 1), (Night 2)
    {title, variants} = extract_pattern(title, variants, ~r/\s*\(Night\s+(\d+)\)$/i, "night", fn m -> "Night #{m}" end)

    # Dates: (5.3.13), (2.16.13), (2023-11-07)
    {title, variants} = extract_pattern(title, variants, ~r/\s*\((\d{1,2}\.\d{1,2}\.\d{2,4})\)$/, "date")
    {title, variants} = extract_pattern(title, variants, ~r/\s*\((\d{4}-\d{2}-\d{2})\)$/, "date")

    # Acoustic
    {title, variants} = extract_pattern(title, variants, ~r/\s*\(Acoustic\)$/i, "acoustic", fn _ -> "Acoustic" end)

    # Reprises
    {title, variants} = extract_pattern(title, variants, ~r/\s*\(reprise\)$/i, "reprise", fn _ -> "Reprise" end)
    {title, variants} = extract_pattern(title, variants, ~r/\s+Reprise$/i, "reprise", fn _ -> "Reprise" end)

    # Intro at end
    {title, variants} = extract_pattern(title, variants, ~r/\s+Intro$/i, "intro", fn _ -> "Intro" end)

    # Versions: v2, V2, 2.0
    {title, variants} = extract_pattern(title, variants, ~r/\s+v(\d+)$/i, "version", fn m -> "v#{m}" end)
    {title, variants} = extract_pattern(title, variants, ~r/\s+(\d+\.\d+)$/, "version", fn m -> "v#{m}" end)

    # Guests: ft. Name, Ft. Name, w/ Name, (w/ Name), (Ft. Name)
    {title, variants} = extract_pattern(title, variants, ~r/\s*\((?:ft\.?|feat\.?|w\/)\s*(.+?)\)$/i, "guest", fn m -> "ft. #{m}" end)
    {title, variants} = extract_pattern(title, variants, ~r/\s+(?:ft\.?|feat\.?)\s+(.+?)$/i, "guest", fn m -> "ft. #{m}" end)
    {title, variants} = extract_pattern(title, variants, ~r/\s+w\/\s+(.+?)$/i, "guest", fn m -> "ft. #{m}" end)

    # Transitions: > at end (song continues into next)
    {title, variants} = extract_pattern(title, variants, ~r/\s*>\s*$/, "transition", fn _ -> ">" end)
    {title, variants} = extract_pattern(title, variants, ~r/\s*->\s*$/, "transition", fn _ -> ">" end)

    # Remixes: - (Name Remix)
    {title, variants} = extract_remix(title, variants)

    # Covers: (Artist Name) at end for known cover artists
    {title, variants} = extract_cover_parens(title, variants)

    # Numbered prefix: 1. Song Name
    {title, variants} = extract_pattern(title, variants, ~r/^(\d+)\.\s+/, "sequence", fn m -> "##{m}" end)

    # Starred (notable version): Song*
    {title, variants} = extract_pattern(title, variants, ~r/\*$/, "notable", fn _ -> "*" end)

    {String.trim(title), Enum.reverse(variants)}
  end

  @doc """
  Returns a cleaned version of the title suitable for song matching.
  Strips all variant markers.
  """
  def clean_title(title) do
    {clean, _variants} = parse_title(title)
    clean
  end

  @doc """
  Extracts variants from a title and returns or creates Variant records.

  Returns a list of Variant structs.
  """
  def extract_variants(title) do
    {_clean, variant_tuples} = parse_title(title)

    Enum.map(variant_tuples, fn {name, category} ->
      get_or_create_variant(name, category)
    end)
  end

  @doc """
  Gets or creates a variant by name.
  """
  def get_or_create_variant(name, category) do
    case Repo.get_by(Variant, name: name) do
      nil ->
        {:ok, variant} =
          %Variant{}
          |> Variant.changeset(%{name: name, category: category})
          |> Repo.insert()
        variant

      variant ->
        variant
    end
  end

  @doc """
  Links a set_song to its variants.
  """
  def link_variants(set_song_id, variants) when is_list(variants) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      Enum.map(variants, fn variant ->
        %{
          set_song_id: set_song_id,
          variant_id: variant.id,
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all("set_song_variants", entries, on_conflict: :nothing)
  end

  # Private functions

  defp extract_pattern(title, variants, regex, category, transform \\ nil) do
    transform = transform || fn m -> m end

    case Regex.run(regex, title, capture: :all) do
      [full_match | captures] ->
        variant_name = transform.(List.first(captures) || full_match)
        new_title = String.replace(title, full_match, "")
        {new_title, [{variant_name, category} | variants]}

      nil ->
        {title, variants}
    end
  end

  defp extract_remix(title, variants) do
    case Regex.run(~r/\s+-\s*\(([^)]+)\)$/, title) do
      [full_match, content] ->
        if String.downcase(content) =~ ~r/remix|detailing/ do
          {String.replace(title, full_match, ""), [{content, "remix"} | variants]}
        else
          {title, variants}
        end

      nil ->
        {title, variants}
    end
  end

  defp extract_cover_parens(title, variants) do
    case Regex.run(~r/\s*\(([^)]+)\)$/, title) do
      [full_match, artist] ->
        if is_cover_artist?(artist) do
          {String.replace(title, full_match, ""), [{artist, "cover"} | variants]}
        else
          {title, variants}
        end

      nil ->
        {title, variants}
    end
  end

  defp is_cover_artist?(name) do
    normalized = String.downcase(name)
    Enum.any?(@known_cover_artists, fn artist ->
      String.downcase(artist) == normalized
    end)
  end
end
