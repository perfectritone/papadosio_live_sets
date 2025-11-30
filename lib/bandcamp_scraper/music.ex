defmodule BandcampScraper.Music do
  @moduledoc """
  The Music context - handles all database operations for sets, songs, and set_songs.
  """

  import Ecto.Query, warn: false
  alias BandcampScraper.Repo

  alias BandcampScraper.Music.Set
  alias BandcampScraper.Music.SetSong
  alias BandcampScraper.Music.Song

  # =============================================================================
  # Sets
  # =============================================================================

  @doc """
  Returns the list of sets.

  ## Examples

      iex> list_sets()
      [%Set{}, ...]

  """
  def list_sets do
    Set
    |> Repo.all()
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

  @doc """
  Gets a single set by title.

  Returns `nil` if no set with that title exists.

  ## Examples

      iex> get_set_by_title("My Set")
      %Set{}

      iex> get_set_by_title("Nonexistent")
      nil

  """
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

  # =============================================================================
  # Songs
  # =============================================================================

  @doc """
  Returns the list of songs.

  ## Examples

      iex> list_songs()
      [%Song{}, ...]

  """
  def list_songs do
    Song
    |> Repo.all()
  end

  @doc """
  Returns the list of songs filtered using Flop.

  ## Examples

      iex> list_songs(%{page: 1, page_size: 10})
      {:ok, {[%Song{}, ...], %Flop.Meta{}}}

      iex> list_songs(%{invalid: params})
      {:error, %Flop.Meta{}}

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

  @doc """
  Gets a single song by title.

  Returns `nil` if no song with that title exists.
  """
  def get_song_by_title(title), do: Repo.get_by(Song, title: title)

  @doc """
  Gets a song with its set_songs preloaded.

  Raises `Ecto.NoResultsError` if the Song does not exist.
  """
  def get_song_with_set_songs!(id) do
    Song
    |> where([s], s.id == ^id)
    |> preload(set_songs: :set)
    |> Repo.one!()
  end

  @doc """
  Gets set_songs for a song with Flop pagination.

  ## Examples

      iex> get_set_songs_for_song(123, %{page: 1})
      {:ok, {[%SetSong{}, ...], %Flop.Meta{}}}

  """
  def get_set_songs_for_song(id, params) do
    SetSong
    |> where([ss], ss.song_id == ^id)
    |> preload(:set)
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

  @doc """
  Resets all songs - removes song associations from set_songs and deletes all songs.
  Uses a transaction to ensure atomicity.

  ## Examples

      iex> reset_songs()
      {:ok, %{update_set_songs: {count, nil}, delete_songs: {count, nil}}}

  """
  def reset_songs do
    Repo.transaction(fn ->
      {updated, _} = Repo.update_all(SetSong, set: [song_id: nil])
      {deleted, _} = Repo.delete_all(Song)
      %{update_set_songs: updated, delete_songs: deleted}
    end)
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

  # =============================================================================
  # SetSongs
  # =============================================================================

  @doc """
  Returns the list of set_songs.

  ## Examples

      iex> list_set_songs()
      [%SetSong{}, ...]

  """
  def list_set_songs do
    SetSong
    |> Repo.all()
  end

  @doc """
  Returns the list of set_songs filtered using Flop.

  ## Examples

      iex> list_set_songs(%{page: 1, page_size: 10})
      {:ok, {[%SetSong{}, ...], %Flop.Meta{}}}

      iex> list_set_songs(%{invalid: params})
      {:error, %Flop.Meta{}}

  """
  def list_set_songs(params) do
    SetSong
    |> Flop.validate_and_run(params, for: SetSong)
  end

  @doc """
  Returns set_songs that don't have an associated song.

  ## Examples

      iex> list_set_songs_without_songs()
      [%SetSong{}, ...]

  """
  def list_set_songs_without_songs do
    SetSong
    |> where([ss], is_nil(ss.song_id))
    |> Repo.all()
  end

  @doc """
  Gets a single set_song.

  Raises `Ecto.NoResultsError` if the SetSong does not exist.

  ## Examples

      iex> get_set_song!(123)
      %SetSong{}

      iex> get_set_song!(456)
      ** (Ecto.NoResultsError)

  """
  def get_set_song!(id), do: Repo.get!(SetSong, id)

  @doc """
  Gets a single set_song with set and song preloaded.

  Raises `Ecto.NoResultsError` if the SetSong does not exist.

  ## Examples

      iex> get_set_song_with_associations!(123)
      %SetSong{set: %Set{}, song: %Song{}}

      iex> get_set_song_with_associations!(456)
      ** (Ecto.NoResultsError)

  """
  def get_set_song_with_associations!(id) do
    SetSong
    |> where([ss], ss.id == ^id)
    |> preload([:set, :song, :variants])
    |> Repo.one!()
  end

  @doc """
  Gets all set_songs for a set.

  ## Examples

      iex> list_set_songs_by_set_id(123)
      [%SetSong{}, ...]

  """
  def list_set_songs_by_set_id(set_id) do
    SetSong
    |> where([ss], ss.set_id == ^set_id)
    |> Repo.all()
  end

  @doc """
  Gets all set_songs for a song.

  ## Examples

      iex> list_set_songs_by_song_id(123)
      [%SetSong{}, ...]

  """
  def list_set_songs_by_song_id(song_id) do
    SetSong
    |> where([ss], ss.song_id == ^song_id)
    |> Repo.all()
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
