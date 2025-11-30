defmodule BandcampScraper.ScrapePersister do
  alias BandcampScraper.{Repo, Scraper, SetScraper}
  alias BandcampScraper.Music
  alias BandcampScraper.Music.{Set, SongMatcher, DateExtractor}

  def persist_sets do
    Scraper.scrape_sets()
    |> Enum.map(&persist_set/1)
  end

  def persist_set(set_data) do
    Music.get_set_by_title(set_data.title)
    |> create_set_unless_exists(set_data)
  end

  def create_set_unless_exists(nil, set_data) do
    # Extract date from title if not already set
    set_data = maybe_extract_date(set_data)

    {:ok, set_record} = Music.create_set(set_data)

    persist_set_songs(set_record)

    set_record
  end
  def create_set_unless_exists(record, _set_data), do: record

  defp maybe_extract_date(%{date: nil, title: title} = set_data) do
    case DateExtractor.extract_date(title) do
      {:ok, date} -> Map.put(set_data, :date, date)
      :error -> set_data
    end
  end
  defp maybe_extract_date(%{title: title} = set_data) when not is_map_key(set_data, :date) do
    case DateExtractor.extract_date(title) do
      {:ok, date} -> Map.put(set_data, :date, date)
      :error -> set_data
    end
  end
  defp maybe_extract_date(set_data), do: set_data

  def persist_set_songs(set_record) do
    {songs, release_date} = SetScraper.scrape_set(set_record.urn)

    # Update set with release_date if we got one
    if release_date do
      set_record
      |> Set.changeset(%{release_date: release_date})
      |> Repo.update!()
    end

    songs
    |> Enum.map(&Map.put(&1, :set_id, set_record.id))
    |> Enum.map(&persist_set_song/1)
  end

  def persist_set_song(set_song_data) do
    {:ok, set_song_record} = Music.create_set_song(set_song_data)

    # Match to song and extract variants
    SongMatcher.match_set_song(set_song_record)

    set_song_record
  end
end
