defmodule BandcampScraper.SongTitleNormalizer do
  alias BandcampScraper.{Repo, Schemas}

  def normalize_song_titles do
    Schemas.list_set_songs_without_songs()
    |> Enum.map(&associate_song/1)
  end

  def force_normalize_song_titles do
    Schemas.list_set_songs()
    |> Enum.map(&associate_song/1)
  end

  def generated_normalized_song_titles do
    Schemas.list_set_songs()
    |> Enum.map(&(normalize_song_title(&1.title)))
    |> Enum.uniq
  end

  def generated_normalized_song_title_count do
    generated_normalized_song_titles()
    |> Enum.count
  end

  def associate_song(set_song) do
    normalized_title = normalize_song_title(set_song.title)

    song_record = Schemas.get_song_by_title(normalized_title)
                  |> find_or_create_song_record(normalized_title)

    Schemas.change_set_song(set_song, %{song_id: song_record.id})
    |> Repo.update
  end

  def find_or_create_song_record(nil, title) do
    {:ok, song_record} = Schemas.create_song(%{title: title})

    song_record
  end
  def find_or_create_song_record(record, _title), do: record

  def normalize_song_title(raw_title) do
    raw_title
    |> downcase
    |> remove_punctuation
    |> remove_accents
    |> remove_trailing_dates
    |> remove_xl
    |> remove_acoustic
    |> trim_whitespace
  end

  def downcase(string), do: String.downcase(string)
  def remove_punctuation(string), do: String.replace(string, ~r/\.?'?>?\*?\^?/, "")
  def remove_accents(string), do: String.replace(string, ~r/é/, "e")
  def remove_trailing_dates(string), do: String.replace(string, ~r/\(\d+\)\Z/, "")
  def remove_xl(string), do: String.replace(string, ~r/\(?xl\)?\Z/, "")
  def remove_acoustic(string), do: String.replace(string, ~r/\(?acoustic\)?\Z/, "")
  def trim_whitespace(string), do: String.trim(string)
end
