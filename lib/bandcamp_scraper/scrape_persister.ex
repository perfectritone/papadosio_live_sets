defmodule BandcampScraper.ScrapePersister do
  alias BandcampScraper.{Scraper, SetScraper}
  alias BandcampScraper.Music

  def persist_sets do
    Scraper.scrape_sets()
    |> Enum.map(&persist_set/1)
  end

  def persist_set(set_data) do
    Music.get_set_by_title(set_data.title)
    |> create_set_unless_exists(set_data)
  end

  def create_set_unless_exists(nil, set_data) do
    {:ok, set_record} = Music.create_set(set_data)

    persist_set_songs(set_record)

    set_record
  end
  def create_set_unless_exists(record, _set_data), do: record

  def persist_set_songs(set_record) do
    SetScraper.scrape_set(set_record.urn)
    |> Enum.map(&Map.put(&1, :set_id, set_record.id))
    |> Enum.map(&persist_set_song/1)
  end

  def persist_set_song(set_song_data) do
    {:ok, _set_song_record} = Music.create_set_song(set_song_data)
  end
end
