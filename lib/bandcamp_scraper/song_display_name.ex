defmodule BandcampScraper.SongDisplayName do
  alias BandcampScraper.{Repo, Schemas}
  alias BandcampScraper.Schemas.Song

  def persist_all do
    Schemas.list_songs()
    |> Enum.map(&persist/1)
  end

  def persist(%Song{} = song) do
    Schemas.change_song(song, %{display_name: generate_display_name(song)})
    |> Repo.update
  end

  def generate_display_name(%Song{} = song) do
    song.id
    |> Schemas.get_set_songs_by_song_id!
    |> Enum.map(&(&1.title))
    |> Enum.frequencies
    |> Enum.max_by(fn {_k, v} -> v end)
    |> Kernel.elem(0)
  end
end
