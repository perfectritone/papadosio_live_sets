defmodule BandcampScraper.Music.SongMatcher do
  @moduledoc """
  Matches set_songs to songs using fuzzy title matching.

  Uses Jaro-Winkler distance to find similar song titles and either
  matches to existing songs or creates new ones.
  """

  import Ecto.Query
  alias BandcampScraper.Repo
  alias BandcampScraper.Music.{Song, SetSong, VariantExtractor}

  @default_threshold 0.80

  # Song aliases - map variations to canonical song title
  # Format: %{"normalized_alias" => "Canonical Title"}
  @song_aliases %{
    # Polygons variations
    "polygone" => "Polygons",
    "psipoly" => "Polygons",
    "psipolygons" => "Polygons",
    "psypoly" => "Polygons",
    "psypolygons" => "Polygons",
    # Typo fixes
    "and this is what he though" => "...And This Is What He Thought",
    # Spacing variations
    "2am" => "2 AM",
    "2 am" => "2 AM"
  }

  @doc """
  Returns the canonical title for a normalized title, applying aliases.
  """
  def get_canonical_title(normalized_title) do
    Map.get(@song_aliases, normalized_title, nil)
  end

  @doc """
  Normalizes a title and applies alias resolution.
  Returns {normalized_title, canonical_title} where canonical_title is the
  display title to use for creating songs.
  """
  def normalize_with_alias(title) do
    clean_title = VariantExtractor.clean_title(title)
    normalized = normalize_title(clean_title)

    case Map.get(@song_aliases, normalized) do
      nil -> {normalized, clean_title}
      canonical -> {normalize_title(canonical), canonical}
    end
  end

  @doc """
  Finds or creates a song for a set_song based on fuzzy title matching.

  Returns the matched or created Song.

  ## Options

    * `:threshold` - minimum Jaro distance for fuzzy match (default: 0.85)

  ## Examples

      iex> find_or_create_song("Find Your Cloud (5.3.13)")
      %Song{title: "Find Your Cloud"}

  """
  def find_or_create_song(title, opts \\ []) do
    threshold = Keyword.get(opts, :threshold, @default_threshold)

    # Clean the title by stripping variant markers
    clean_title = VariantExtractor.clean_title(title)
    normalized = normalize_title(clean_title)

    # Check for alias first
    canonical_title = Map.get(@song_aliases, normalized, clean_title)
    canonical_normalized = normalize_title(canonical_title)

    # Try exact match first (using canonical title)
    case find_exact_match(canonical_normalized) do
      %Song{} = song ->
        song

      nil ->
        # Try fuzzy match
        case find_fuzzy_match(canonical_normalized, threshold) do
          %Song{} = song ->
            song

          nil ->
            # Create new song with canonical title
            create_song(canonical_title)
        end
    end
  end

  @doc """
  Matches a set_song to a song and updates the set_song's song_id.

  Also extracts and links variants.

  Returns `{:ok, set_song}` or `{:error, changeset}`.
  """
  def match_set_song(%SetSong{} = set_song, opts \\ []) do
    song = find_or_create_song(set_song.title, opts)

    # Extract and link variants
    variants = VariantExtractor.extract_variants(set_song.title)
    if length(variants) > 0 do
      VariantExtractor.link_variants(set_song.id, variants)
    end

    # Update set_song with song_id
    set_song
    |> SetSong.changeset(%{song_id: song.id})
    |> Repo.update()
  end

  @doc """
  Matches all unlinked set_songs to songs.

  Returns `{matched_count, created_count}`.
  """
  def match_all_set_songs(opts \\ []) do
    set_songs =
      SetSong
      |> where([ss], is_nil(ss.song_id))
      |> Repo.all()

    Enum.reduce(set_songs, {0, 0}, fn set_song, {matched, created} ->
      songs_before = Repo.aggregate(Song, :count)
      {:ok, _} = match_set_song(set_song, opts)
      songs_after = Repo.aggregate(Song, :count)

      if songs_after > songs_before do
        {matched + 1, created + 1}
      else
        {matched + 1, created}
      end
    end)
  end

  @doc """
  Normalizes a title for comparison.

  - Strips variant markers
  - Lowercase
  - Trim whitespace
  - Remove special characters (keep alphanumeric and spaces)
  - Collapse multiple spaces
  """
  def normalize_title(nil), do: ""
  def normalize_title(title) do
    title
    |> VariantExtractor.clean_title()
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^\w\s]/u, "")
    |> String.replace(~r/\s+/, " ")
  end

  # Private functions

  defp find_exact_match(normalized_title) do
    Song
    |> Repo.all()
    |> Enum.find(fn song ->
      normalize_title(song.title) == normalized_title
    end)
  end

  defp find_fuzzy_match(normalized_title, threshold) do
    Song
    |> Repo.all()
    |> Enum.map(fn song ->
      other_normalized = normalize_title(song.title)
      score = String.jaro_distance(normalized_title, other_normalized)
      {song, score, other_normalized}
    end)
    |> Enum.filter(fn {_song, score, other_normalized} ->
      score >= threshold and is_valid_match?(normalized_title, other_normalized)
    end)
    |> Enum.max_by(fn {_song, score, _} -> score end, fn -> nil end)
    |> case do
      {song, _score, _} -> song
      nil -> nil
    end
  end

  defp is_valid_match?(title1, title2) do
    # Don't match if one is a substring of the other (e.g., "Improv" vs "105 Improv")
    not String.contains?(title1, title2) and
    not String.contains?(title2, title1) and
    # Don't match if lengths are too different (>40% difference)
    length_ratio(title1, title2) >= 0.6 and
    # First word should match (prevents "1979" matching "Eye")
    first_word_matches?(title1, title2)
  end

  defp length_ratio(s1, s2) do
    len1 = String.length(s1)
    len2 = String.length(s2)
    min(len1, len2) / max(len1, len2)
  end

  defp first_word_matches?(title1, title2) do
    word1 = title1 |> String.split() |> List.first() || ""
    word2 = title2 |> String.split() |> List.first() || ""
    # First words should be similar (allowing for typos)
    String.jaro_distance(word1, word2) >= 0.8
  end

  defp create_song(title) do
    {:ok, song} =
      %Song{}
      |> Song.changeset(%{title: title})
      |> Repo.insert()

    song
  end
end
