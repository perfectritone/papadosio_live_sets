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
  Returns a list of sets filtered and sorted by the given parameters.

  ## Options

    * `:sort` - Sort direction for effective date: "asc" or "desc" (default: "desc")
    * `:year` - Filter by year (integer or string)
    * `:season` - Filter by season: "winter", "spring", "summer", "fall"

  Season definitions (month-based):
    * winter: December, January, February
    * spring: March, April, May
    * summer: June, July, August
    * fall: September, October, November

  """
  def list_sets(params) when is_map(params) do
    Set
    |> apply_set_filters(params)
    |> apply_set_sorting(params)
    |> Repo.all()
  end

  defp apply_set_filters(query, params) do
    query
    |> filter_by_year(params)
    |> filter_by_season(params)
  end

  defp filter_by_year(query, %{"year" => year}) when year != "" and year != nil do
    year = if is_binary(year), do: String.to_integer(year), else: year
    from(s in query,
      where: fragment("EXTRACT(YEAR FROM COALESCE(?, ?)) = ?", s.date, s.release_date, ^year)
    )
  end
  defp filter_by_year(query, _params), do: query

  defp filter_by_season(query, %{"season" => "winter"}) do
    # Winter: Dec 21 - Mar 20 (wraps year boundary)
    from(s in query,
      where: fragment("(EXTRACT(MONTH FROM COALESCE(?, ?)) = 12 AND EXTRACT(DAY FROM COALESCE(?, ?)) >= 21) OR EXTRACT(MONTH FROM COALESCE(?, ?)) IN (1, 2) OR (EXTRACT(MONTH FROM COALESCE(?, ?)) = 3 AND EXTRACT(DAY FROM COALESCE(?, ?)) <= 20)", s.date, s.release_date, s.date, s.release_date, s.date, s.release_date, s.date, s.release_date, s.date, s.release_date)
    )
  end
  defp filter_by_season(query, %{"season" => "spring"}) do
    # Spring: Mar 21 - Jun 20
    from(s in query,
      where: fragment("(EXTRACT(MONTH FROM COALESCE(?, ?)) = 3 AND EXTRACT(DAY FROM COALESCE(?, ?)) >= 21) OR EXTRACT(MONTH FROM COALESCE(?, ?)) IN (4, 5) OR (EXTRACT(MONTH FROM COALESCE(?, ?)) = 6 AND EXTRACT(DAY FROM COALESCE(?, ?)) <= 20)", s.date, s.release_date, s.date, s.release_date, s.date, s.release_date, s.date, s.release_date, s.date, s.release_date)
    )
  end
  defp filter_by_season(query, %{"season" => "summer"}) do
    # Summer: Jun 21 - Sep 22
    from(s in query,
      where: fragment("(EXTRACT(MONTH FROM COALESCE(?, ?)) = 6 AND EXTRACT(DAY FROM COALESCE(?, ?)) >= 21) OR EXTRACT(MONTH FROM COALESCE(?, ?)) IN (7, 8) OR (EXTRACT(MONTH FROM COALESCE(?, ?)) = 9 AND EXTRACT(DAY FROM COALESCE(?, ?)) <= 22)", s.date, s.release_date, s.date, s.release_date, s.date, s.release_date, s.date, s.release_date, s.date, s.release_date)
    )
  end
  defp filter_by_season(query, %{"season" => "fall"}) do
    # Fall: Sep 23 - Dec 20
    from(s in query,
      where: fragment("(EXTRACT(MONTH FROM COALESCE(?, ?)) = 9 AND EXTRACT(DAY FROM COALESCE(?, ?)) >= 23) OR EXTRACT(MONTH FROM COALESCE(?, ?)) IN (10, 11) OR (EXTRACT(MONTH FROM COALESCE(?, ?)) = 12 AND EXTRACT(DAY FROM COALESCE(?, ?)) <= 20)", s.date, s.release_date, s.date, s.release_date, s.date, s.release_date, s.date, s.release_date, s.date, s.release_date)
    )
  end
  defp filter_by_season(query, _params), do: query

  @doc """
  Returns a list of available years that have sets.
  """
  def list_set_years do
    from(s in Set,
      select: fragment("DISTINCT EXTRACT(YEAR FROM COALESCE(?, ?))::integer", s.date, s.release_date),
      where: not is_nil(s.date) or not is_nil(s.release_date),
      order_by: [desc: fragment("EXTRACT(YEAR FROM COALESCE(?, ?))::integer", s.date, s.release_date)]
    )
    |> Repo.all()
    |> Enum.reject(&is_nil/1)
  end

  defp apply_set_sorting(query, %{"sort" => "asc"}) do
    from(s in query,
      order_by: [asc_nulls_last: fragment("COALESCE(?, ?)", s.date, s.release_date)]
    )
  end
  defp apply_set_sorting(query, _params) do
    # Default to descending (newest first)
    from(s in query,
      order_by: [desc_nulls_last: fragment("COALESCE(?, ?)", s.date, s.release_date)]
    )
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
    |> order_by([s], asc: fragment("COALESCE(?, ?)", s.display_name, s.title))
    |> Repo.all()
  end

  @doc """
  Returns the list of songs with optional sorting and search.

  ## Options

    * `:sort` - Sort direction: "asc" (default) or "desc"
    * `:search` - Search term to filter by title or display_name

  """
  def list_songs(params) when is_map(params) do
    Song
    |> apply_song_search(params)
    |> apply_song_sorting(params)
    |> Repo.all()
  end

  defp apply_song_search(query, %{"search" => search}) when search != "" and search != nil do
    search_term = "%#{search}%"
    from(s in query,
      where: ilike(s.title, ^search_term) or ilike(s.display_name, ^search_term)
    )
  end
  defp apply_song_search(query, _params), do: query

  defp apply_song_sorting(query, %{"sort" => "desc"}) do
    from(s in query,
      order_by: [desc: fragment("COALESCE(?, ?)", s.display_name, s.title)]
    )
  end
  defp apply_song_sorting(query, _params) do
    from(s in query,
      order_by: [asc: fragment("COALESCE(?, ?)", s.display_name, s.title)]
    )
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

  # =============================================================================
  # Variants
  # =============================================================================

  alias BandcampScraper.Music.Variant

  @doc """
  Returns the list of variants ordered by name.
  """
  def list_variants do
    Variant
    |> order_by([v], v.name)
    |> Repo.all()
  end

  @doc """
  Gets a single variant.

  Raises `Ecto.NoResultsError` if the Variant does not exist.
  """
  def get_variant!(id), do: Repo.get!(Variant, id)

  @doc """
  Gets a variant with its set_songs preloaded (including set association).
  """
  def get_variant_with_set_songs!(id) do
    Variant
    |> where([v], v.id == ^id)
    |> preload(set_songs: :set)
    |> Repo.one!()
  end

  @doc """
  Gets or creates a variant by name.
  """
  def get_or_create_variant(name, category \\ "other") do
    case Repo.get_by(Variant, name: name) do
      nil ->
        {:ok, variant} =
          %Variant{}
          |> Variant.changeset(%{name: name, category: category})
          |> Repo.insert()
        variant

      variant ->
        variant
    end
  end

  @doc """
  Adds a variant to a set_song. Set manual: true for manually added variants.
  Optional user_id to track who made the change.
  """
  def add_variant_to_set_song(set_song_id, variant_id, manual \\ false, user_id \\ nil) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all(
      "set_song_variants",
      [%{
        set_song_id: set_song_id,
        variant_id: variant_id,
        manual: manual,
        user_id: user_id,
        inserted_at: now,
        updated_at: now
      }],
      on_conflict: :nothing
    )
  end

  @doc """
  Removes a variant from a set_song.
  """
  def remove_variant_from_set_song(set_song_id, variant_id) do
    from(sv in "set_song_variants",
      where: sv.set_song_id == ^set_song_id and sv.variant_id == ^variant_id
    )
    |> Repo.delete_all()
  end

  @doc """
  Returns all manually added variant associations for seeding.
  """
  def list_manual_variant_associations do
    from(sv in "set_song_variants",
      where: sv.manual == true,
      join: ss in SetSong, on: ss.id == sv.set_song_id,
      join: v in Variant, on: v.id == sv.variant_id,
      select: %{set_song_title: ss.title, variant_name: v.name, variant_category: v.category}
    )
    |> Repo.all()
  end
end
