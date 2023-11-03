defmodule BandcampScraper.ScrapePersister do
  alias BandcampScraper.{Repo, Scraper, SetScraper}
  alias BandcampScraper.Schemas.{Set, SetSong}

  def persist_sets do
    Scraper.scrape_sets()
    |> Enum.map(&persist_set/1)
  end

  def persist_set(set_data) do
    unless Set |> Repo.get_by(title: set_data.title) do
      set_struct = struct(Set, set_data)

      {:ok, set_record} = Repo.insert(set_struct)

      persist_songs(set_record)
    end
  end

  def persist_songs(set_record) do
    SetScraper.scrape_set(set_record.urn)
    |> Enum.map(&persist_song(set_record.id, &1))
  end

  def persist_song(set_id, song_data) do
    set_song_data = [set_id: set_id, title: song_data.title]
    set_song_record = SetSong |> Repo.get_by(set_song_data)

    unless set_song_record do
      song_struct = struct(SetSong, Map.put(set_song_data, :set_id, set_id))

      {:ok, _set_song_record} = Repo.insert(song_struct)
    end
  end
end
