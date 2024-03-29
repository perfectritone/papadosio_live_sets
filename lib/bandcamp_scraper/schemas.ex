defmodule BandcampScraper.Schemas do
  @moduledoc """
  The Schemas context.
  """

  import Ecto.Query, warn: false
  alias BandcampScraper.Repo

  alias BandcampScraper.Schemas.Set
  alias BandcampScraper.Schemas.SetSong
  alias BandcampScraper.Schemas.Song

  @doc """
  Returns the list of sets.

  ## Examples

      iex> list_sets()
      [%Set{}, ...]

  """
  def list_sets do
    Repo.all(Set)
  end

  @doc """
  Gets a single set.

  Raises `Ecto.NoResultsError` if the Set does not exist.

  ## Examples

      iex> get_set!(123)
      %Set{}

      iex> get_set!(456)
      ** (Ecto.NoResultsError)

  """
  def get_set!(id), do: Repo.get!(Set, id)

  def get_set_by_title(title) do
    Repo.get_by(Set, title: title)
  end

  @doc """
  Creates a set.

  ## Examples

      iex> create_set(%{field: value})
      {:ok, %Set{}}

      iex> create_set(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_set(attrs \\ %{}) do
    %Set{}
    |> Set.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a set.

  ## Examples

      iex> update_set(set, %{field: new_value})
      {:ok, %Set{}}

      iex> update_set(set, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_set(%Set{} = set, attrs) do
    set
    |> Set.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a set.

  ## Examples

      iex> delete_set(set)
      {:ok, %Set{}}

      iex> delete_set(set)
      {:error, %Ecto.Changeset{}}

  """
  def delete_set(%Set{} = set) do
    Repo.delete(set)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking set changes.

  ## Examples

      iex> change_set(set)
      %Ecto.Changeset{data: %Set{}}

  """
  def change_set(%Set{} = set, attrs \\ %{}) do
    Set.changeset(set, attrs)
  end

  @doc """
  Returns the list of songs.

  ## Examples

      iex> list_songs()
      [%Song{}, ...]

  """
  def list_songs do
    Repo.all(Song)
  end

  @doc """
  Returns the list of songs filtered using Flop.

  ## Examples

      iex> list_songs(%{flop: params, ...)
      [%Song{}, ...]

  """
  def list_songs(params) do
    Song
    |> Flop.validate_and_run(params, for: Song)
  end

  @doc """
  Gets a single song.

  Raises `Ecto.NoResultsError` if the Song does not exist.

  ## Examples

      iex> get_song!(123)
      %Song{}

      iex> get_song!(456)
      ** (Ecto.NoResultsError)

  """
  def get_song!(id), do: Repo.get!(Song, id)

  def get_song_by_title(title), do: Repo.get_by(Song, title: title)

  def get_set_songs_for_song!(id) do
    Repo.all(from song in Song,
      where: song.id == ^id,
      join: set_song in assoc(song, :set_songs),
      join: set in assoc(set_song, :set),
      preload: [set_songs: {set_song, set: set}]
    ) |> List.first
  end

  def get_set_songs_for_song!(id, params) do
    SetSong
    |> where([set_song], set_song.song_id == ^id)
    |> join(:left, [set_song], set in assoc(set_song, :set), as: :set)
    |> preload([:set])
    |> Flop.validate_and_run(params, for: SetSong)
  end

  @doc """
  Creates a song.

  ## Examples

      iex> create_song(%{field: value})
      {:ok, %Song{}}

      iex> create_song(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_song(attrs \\ %{}) do
    %Song{}
    |> Song.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a song.

  ## Examples

      iex> update_song(song, %{field: new_value})
      {:ok, %Song{}}

      iex> update_song(song, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_song(%Song{} = song, attrs) do
    song
    |> Song.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a song.

  ## Examples

      iex> delete_song(song)
      {:ok, %Song{}}

      iex> delete_song(song)
      {:error, %Ecto.Changeset{}}

  """
  def delete_song(%Song{} = song) do
    Repo.delete(song)
  end

  def reset_songs do
    Repo.update_all(SetSong, set: [song_id: nil])
    Repo.delete_all(Song)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking song changes.

  ## Examples

      iex> change_song(song)
      %Ecto.Changeset{data: %Song{}}

  """
  def change_song(%Song{} = song, attrs \\ %{}) do
    Song.changeset(song, attrs)
  end

  @doc """
  Returns the list of set_songs.

  ## Examples

      iex> list_set_songs()
      [%SetSong{}, ...]

  """
  def list_set_songs do
    Repo.all(SetSong)
  end

  @doc """
  Returns the list of set_songs filtered using Flop.

  ## Examples

      iex> list_set_songs(%{flop: param, ...})
      [%SetSong{}, ...]

  """
  def list_set_songs(params) do
    {:ok, {flop, _meta}} = Flop.validate_and_run(SetSong, params, for: SetSong)

    flop
  end

  def list_set_songs_without_songs do
    q = from(
      ss in SetSong,
      where: is_nil(ss.song_id)
    )

    Repo.all(q)
  end

  @doc """
  Gets a single set_song.

  Raises `Ecto.NoResultsError` if the Set song does not exist.

  ## Examples

      iex> get_set_song!(123)
      %SetSong{}

      iex> get_set_song!(456)
      ** (Ecto.NoResultsError)

  """
  def get_set_song!(id), do: Repo.get!(SetSong, id)

  def get_set_song_with_set_and_song!(id) do
    Repo.all(from set_song in SetSong,
      where: set_song.id == ^id,
      join: song in assoc(set_song, :song),
      join: set in assoc(set_song, :set),
      preload: [:song, :set]
    ) |> List.first
  end

  @doc """
  Gets all set_songs from a set.

  Raises `Ecto.NoResultsError` if the Set does not exist.

  ## Examples

      iex> get_set_songs_by_set(123)
      [%SetSong{}, ...]

      iex> get_set_songs_by_set(456)
      ** (Ecto.NoResultsError)

  """
  def get_set_songs_by_set_id!(set_id) do
    q = SetSong |> where(set_id: ^set_id)
    Repo.all(q)
  end

  def get_set_songs_by_song_id!(song_id) do
    q = SetSong |> where(song_id: ^song_id)
    Repo.all(q)
  end

  @doc """
  Creates a set_song.

  ## Examples

      iex> create_set_song(%{field: value})
      {:ok, %SetSong{}}

      iex> create_set_song(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_set_song(attrs \\ %{}) do
    %SetSong{}
    |> SetSong.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a set_song.

  ## Examples

      iex> update_set_song(set_song, %{field: new_value})
      {:ok, %SetSong{}}

      iex> update_set_song(set_song, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_set_song(%SetSong{} = set_song, attrs) do
    set_song
    |> SetSong.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a set_song.

  ## Examples

      iex> delete_set_song(set_song)
      {:ok, %SetSong{}}

      iex> delete_set_song(set_song)
      {:error, %Ecto.Changeset{}}

  """
  def delete_set_song(%SetSong{} = set_song) do
    Repo.delete(set_song)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking set_song changes.

  ## Examples

      iex> change_set_song(set_song)
      %Ecto.Changeset{data: %SetSong{}}

  """
  def change_set_song(%SetSong{} = set_song, attrs \\ %{}) do
    SetSong.changeset(set_song, attrs)
  end
end
