defmodule BandcampScraper.SongDisplayName do
  alias BandcampScraper.{Repo, Music}
  alias BandcampScraper.Music.Song

  def persist_all do
    Music.list_songs()
    |> Enum.map(&persist/1)
  end

  def persist(%Song{} = song) do
    Music.change_song(song, %{display_name: generate_display_name(song)})
    |> Repo.update()
  end

  def generate_display_name(%Song{} = song) do
    song.id
    |> Music.list_set_songs_by_song_id()
    |> Enum.map(& &1.title)
    |> Enum.frequencies()
    |> Enum.max_by(fn {_k, v} -> v end)
    |> elem(0)
  end
end
