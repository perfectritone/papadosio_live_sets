defmodule BandcampScraper.SongTitleNormalizer do
  require Ecto.Query

  alias BandcampScraper.Repo
  alias BandcampScraper.Schemas.{SetSong, Song}

  def normalize_song_titles do
    unnormalized_set_songs()
    |> Enum.map(&associate_song/1)
  end

  def unnormalized_set_songs do
    q = Ecto.Query.from(
      ss in SetSong,
      where: is_nil(ss.song_id)
    )

    Repo.all(q)
  end

  def associate_song(set_song) do
    normalized_title = normalize_song_title(set_song.title)

    song_record = find_or_create_song_record(normalized_title)

    set_song_changeset = Ecto.Changeset.cast(set_song, %{song_id: song_record.id}, [:song_id])
    Repo.update(set_song_changeset)
  end

  def find_or_create_song_record(title) do
    existing_song_record = Song |> Repo.get_by(title: title)

    if existing_song_record do
      existing_song_record
    else
      song_struct = struct(Song, title: title)

      {:ok, new_song_record} = Repo.insert(song_struct)
      new_song_record
    end
  end

  def normalize_song_title(raw_title) do
    raw_title
    |> String.downcase
  end

  def delete_all_songs do
    Repo.delete_all(Song)
  end
end
