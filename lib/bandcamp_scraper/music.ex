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
    |> order_by([s], desc: fragment("COALESCE(?, ?)", s.date, s.release_date))
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
    |> filter_by_search(params)
    |> filter_by_year(params)
    |> filter_by_season(params)
    |> filter_by_songs(params)
  end

  defp filter_by_search(query, %{"search" => search}) when search != "" and search != nil do
    search_term = "%#{search}%"
    from(s in query, where: ilike(s.title, ^search_term))
  end
  defp filter_by_search(query, _params), do: query

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

  # Filter by multiple songs - supports both "any order" and "consecutive" modes
  defp filter_by_songs(query, %{"songs" => songs} = params) when is_list(songs) do
    # Filter out empty song selections
    song_ids = songs
      |> Enum.filter(&(&1 != "" and &1 != nil))
      |> Enum.map(fn id -> if is_binary(id), do: String.to_integer(id), else: id end)

    case song_ids do
      [] -> query
      [single_id] ->
        # Single song - just filter sets containing it
        from(s in query,
          where: s.id in subquery(
            from ss in SetSong,
            where: ss.song_id == ^single_id,
            select: ss.set_id
          )
        )
      _ ->
        if params["in_order"] == "true" do
          filter_consecutive_songs(query, song_ids)
        else
          filter_contains_all_songs(query, song_ids)
        end
    end
  end
  defp filter_by_songs(query, _params), do: query

  # Filter sets containing ALL specified songs (any order)
  # Supports duplicate songs - e.g., selecting the same song twice finds sets where it appears 2+ times
  defp filter_contains_all_songs(query, song_ids) do
    # Count required occurrences of each song
    song_counts = Enum.frequencies(song_ids)

    # Convert to list of {song_id, required_count} for the query
    # We use a CTE approach: for each unique song, check it appears enough times
    unique_song_ids = Map.keys(song_counts)
    required_counts = Map.values(song_counts)
    unique_count = length(unique_song_ids)

    from(s in query,
      where: s.id in fragment("""
        SELECT set_id FROM (
          SELECT ss.set_id, ss.song_id, COUNT(*) as cnt
          FROM set_songs ss
          WHERE ss.song_id = ANY(?)
          GROUP BY ss.set_id, ss.song_id
        ) counts
        INNER JOIN unnest(?::int[], ?::int[]) AS required(song_id, min_count)
          ON counts.song_id = required.song_id AND counts.cnt >= required.min_count
        GROUP BY set_id
        HAVING COUNT(*) = ?
        """, ^unique_song_ids, ^unique_song_ids, ^required_counts, ^unique_count)
    )
  end

  # Filter sets with songs appearing consecutively in order
  # Supports 2-5 songs in sequence
  defp filter_consecutive_songs(query, [s1, s2]) do
    from(s in query,
      where: s.id in fragment("""
        SELECT ss0.set_id FROM set_songs ss0
        JOIN set_songs ss1 ON ss0.set_id = ss1.set_id AND ss1.id = ss0.id + 1
        WHERE ss0.song_id = ? AND ss1.song_id = ?
        """, ^s1, ^s2)
    )
  end
  defp filter_consecutive_songs(query, [s1, s2, s3]) do
    from(s in query,
      where: s.id in fragment("""
        SELECT ss0.set_id FROM set_songs ss0
        JOIN set_songs ss1 ON ss0.set_id = ss1.set_id AND ss1.id = ss0.id + 1
        JOIN set_songs ss2 ON ss0.set_id = ss2.set_id AND ss2.id = ss1.id + 1
        WHERE ss0.song_id = ? AND ss1.song_id = ? AND ss2.song_id = ?
        """, ^s1, ^s2, ^s3)
    )
  end
  defp filter_consecutive_songs(query, [s1, s2, s3, s4]) do
    from(s in query,
      where: s.id in fragment("""
        SELECT ss0.set_id FROM set_songs ss0
        JOIN set_songs ss1 ON ss0.set_id = ss1.set_id AND ss1.id = ss0.id + 1
        JOIN set_songs ss2 ON ss0.set_id = ss2.set_id AND ss2.id = ss1.id + 1
        JOIN set_songs ss3 ON ss0.set_id = ss3.set_id AND ss3.id = ss2.id + 1
        WHERE ss0.song_id = ? AND ss1.song_id = ? AND ss2.song_id = ? AND ss3.song_id = ?
        """, ^s1, ^s2, ^s3, ^s4)
    )
  end
  defp filter_consecutive_songs(query, [s1, s2, s3, s4, s5]) do
    from(s in query,
      where: s.id in fragment("""
        SELECT ss0.set_id FROM set_songs ss0
        JOIN set_songs ss1 ON ss0.set_id = ss1.set_id AND ss1.id = ss0.id + 1
        JOIN set_songs ss2 ON ss0.set_id = ss2.set_id AND ss2.id = ss1.id + 1
        JOIN set_songs ss3 ON ss0.set_id = ss3.set_id AND ss3.id = ss2.id + 1
        JOIN set_songs ss4 ON ss0.set_id = ss4.set_id AND ss4.id = ss3.id + 1
        WHERE ss0.song_id = ? AND ss1.song_id = ? AND ss2.song_id = ? AND ss3.song_id = ? AND ss4.song_id = ?
        """, ^s1, ^s2, ^s3, ^s4, ^s5)
    )
  end
  # For more than 5 songs, just match the first 5
  defp filter_consecutive_songs(query, [s1, s2, s3, s4, s5 | _]) do
    filter_consecutive_songs(query, [s1, s2, s3, s4, s5])
  end
  defp filter_consecutive_songs(query, _), do: query

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
  Gets a single set by URN.

  Returns `nil` if the Set does not exist.
  """
  def get_set_by_urn(urn) do
    Repo.get_by(Set, urn: urn)
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
    |> apply_play_count_filter(params)
    |> apply_song_sorting(params)
    |> Repo.all()
  end

  defp apply_play_count_filter(query, %{"plays" => "multiple"}) do
    from(s in query,
      join: ss in assoc(s, :set_songs),
      group_by: s.id,
      having: count(ss.id) > 1
    )
  end
  defp apply_play_count_filter(query, %{"plays" => "single"}) do
    from(s in query,
      join: ss in assoc(s, :set_songs),
      group_by: s.id,
      having: count(ss.id) == 1
    )
  end
  defp apply_play_count_filter(query, _params), do: query

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
    query = SetSong
    |> where([ss], ss.song_id == ^id)
    |> join(:left, [ss], s in assoc(ss, :set))
    |> preload(:set)

    # Remove date_sort from params before passing to Flop
    flop_params = Map.drop(params, ["date_sort"])

    # Only apply manual date sorting if Flop isn't sorting (no order_by param)
    query = if params["order_by"] do
      query
    else
      case params["date_sort"] do
        "asc" -> order_by(query, [ss, s], asc: fragment("COALESCE(?, ?)", s.date, s.release_date))
        "desc" -> order_by(query, [ss, s], desc: fragment("COALESCE(?, ?)", s.date, s.release_date))
        _ -> order_by(query, [ss, s], desc: fragment("COALESCE(?, ?)", s.date, s.release_date))
      end
    end

    Flop.validate_and_run(query, flop_params, for: SetSong)
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

  alias BandcampScraper.Music.SongMerge

  @doc """
  Merges a source song into a target song.

  All set_songs linked to the source song will be moved to the target song,
  then the source song is deleted. The merge is recorded for audit/seeding.

  Returns `{:ok, target_song}` or `{:error, reason}`.
  """
  def merge_songs(source_id, target_id, user_id \\ nil)
  def merge_songs(source_id, target_id, _user_id) when source_id == target_id do
    {:error, "Cannot merge a song into itself"}
  end
  def merge_songs(source_id, target_id, user_id) do
    source = get_song!(source_id)
    target = get_song!(target_id)

    Repo.transaction(fn ->
      # Record the merge
      %SongMerge{}
      |> SongMerge.changeset(%{
        source_title: source.title,
        target_title: target.title,
        target_song_id: target.id,
        user_id: user_id
      })
      |> Repo.insert!()

      # Move all set_songs from source to target
      from(ss in SetSong, where: ss.song_id == ^source.id)
      |> Repo.update_all(set: [song_id: target.id])

      # Delete the source song
      Repo.delete!(source)

      target
    end)
  end

  @doc """
  Returns all song merges for seeding/audit.
  """
  def list_song_merges do
    SongMerge
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, :target_song])
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
    |> order_by([ss], asc: ss.id)
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

  # =============================================================================
  # Stats
  # =============================================================================

  @doc """
  Returns songs with their play counts (number of set_songs), sorted by most played first.
  """
  def list_songs_with_play_counts do
    from(s in Song,
      left_join: ss in SetSong, on: ss.song_id == s.id,
      group_by: s.id,
      select: %{
        id: s.id,
        title: s.title,
        display_name: s.display_name,
        play_count: count(ss.id)
      },
      order_by: [desc: count(ss.id), asc: fragment("COALESCE(?, ?)", s.display_name, s.title)]
    )
    |> Repo.all()
  end

  @doc """
  Returns set_songs sorted by duration with set and song preloaded.

  ## Options

    * `:sort` - Sort direction: "asc" or "desc" (default: "desc" for longest first)

  """
  def list_set_songs_by_duration(params \\ %{}) do
    sort_dir = if params["sort"] == "asc", do: :asc, else: :desc

    query = from(ss in SetSong,
      join: set in assoc(ss, :set),
      left_join: song in assoc(ss, :song),
      where: not is_nil(ss.duration) and ss.duration > 0,
      preload: [set: set, song: song]
    )

    query = case sort_dir do
      :asc -> order_by(query, [ss], asc: ss.duration)
      :desc -> order_by(query, [ss], desc: ss.duration)
    end

    Repo.all(query)
  end

  @doc """
  Returns "set sandwiches" - sets that start and end with the same song.

  Returns a list of maps with song info and the sets that form sandwiches with that song.

  ## Options

    * `:sort` - Sort direction for song title: "asc" (default) or "desc"

  """
  def list_set_sandwiches(params \\ %{}) do
    sort_dir = if params["sort"] == "desc", do: :desc, else: :asc
    sort_by = params["sort_by"] || "song"

    base_query = from(song in Song,
      join: sandwich in fragment("""
        SELECT DISTINCT ss_first.song_id, ss_first.set_id
        FROM set_songs ss_first
        JOIN (
          SELECT set_id, MIN(id) as min_id, MAX(id) as max_id
          FROM set_songs
          GROUP BY set_id
          HAVING MIN(id) != MAX(id)
        ) bounds ON ss_first.set_id = bounds.set_id AND ss_first.id = bounds.min_id
        JOIN set_songs ss_last ON ss_last.set_id = bounds.set_id AND ss_last.id = bounds.max_id
        WHERE ss_first.song_id IS NOT NULL
          AND ss_last.song_id IS NOT NULL
          AND ss_first.song_id = ss_last.song_id
        """),
      on: sandwich.song_id == song.id,
      join: set in Set, on: set.id == sandwich.set_id,
      select: %{
        song_id: song.id,
        song_title: song.title,
        song_display_name: song.display_name,
        set_id: set.id,
        set_title: set.title,
        set_date: fragment("COALESCE(?, ?)", set.date, set.release_date)
      }
    )

    query = case sort_by do
      "date" ->
        from([song, sandwich, set] in base_query,
          order_by: [{^sort_dir, fragment("COALESCE(?, ?)", set.date, set.release_date)}]
        )
      _ ->
        from([song, sandwich, set] in base_query,
          order_by: [{^sort_dir, fragment("COALESCE(?, ?)", song.display_name, song.title)}, desc: fragment("COALESCE(?, ?)", set.date, set.release_date)]
        )
    end

    Repo.all(query)
  end

  @doc """
  Returns "multisong sandwiches" - a song that appears twice in a set with songs
  between the appearances, but is NOT the first or last song of the set.

  ## Options

    * `:sort_by` - Column to sort by: "song" (default), "date", or "songs_between"
    * `:sort` - Sort direction: "asc" (default) or "desc"

  """
  def list_multisong_sandwiches(params \\ %{}) do
    sort_dir = if params["sort"] == "desc", do: :desc, else: :asc
    sort_by = params["sort_by"] || "song"

    query = from(song in Song,
      join: sandwich in fragment("""
        SELECT
          ss1.song_id,
          ss1.set_id,
          (ss2.id - ss1.id - 1) as songs_between
        FROM set_songs ss1
        JOIN set_songs ss2 ON ss1.set_id = ss2.set_id
          AND ss1.song_id = ss2.song_id
          AND ss2.id > ss1.id + 1
        JOIN (
          SELECT set_id, MIN(id) as min_id, MAX(id) as max_id
          FROM set_songs
          GROUP BY set_id
        ) bounds ON ss1.set_id = bounds.set_id
        WHERE ss1.song_id IS NOT NULL
          AND NOT (ss1.id = bounds.min_id AND ss2.id = bounds.max_id)
        """),
      on: sandwich.song_id == song.id,
      join: set in Set, on: set.id == sandwich.set_id,
      select: %{
        song_id: song.id,
        song_title: song.title,
        song_display_name: song.display_name,
        set_id: set.id,
        set_title: set.title,
        set_date: fragment("COALESCE(?, ?)", set.date, set.release_date),
        songs_between: sandwich.songs_between
      }
    )

    query = case sort_by do
      "date" ->
        order_by(query, [song, sandwich, set], [{^sort_dir, fragment("COALESCE(?, ?)", set.date, set.release_date)}])
      "songs_between" ->
        order_by(query, [song, sandwich, set], [{^sort_dir, sandwich.songs_between}])
      _ ->
        order_by(query, [song, sandwich, set], [{^sort_dir, fragment("COALESCE(?, ?)", song.display_name, song.title)}])
    end

    Repo.all(query)
  end

  @doc """
  Returns sets that have more than one sandwich (multiple songs that each repeat
  with songs between their appearances).

  ## Options

    * `:sort_by` - Column to sort by: "date" (default) or "sandwich_count"
    * `:sort` - Sort direction: "asc" or "desc" (default)

  """
  def list_multi_sandwich_sets(params \\ %{}) do
    sort_dir = if params["sort"] == "asc", do: :asc, else: :desc
    sort_by = params["sort_by"] || "date"

    query = from(set in Set,
      join: counts in fragment("""
        SELECT set_id, COUNT(DISTINCT song_id) as sandwich_count
        FROM (
          SELECT ss1.song_id, ss1.set_id
          FROM set_songs ss1
          JOIN set_songs ss2 ON ss1.set_id = ss2.set_id
            AND ss1.song_id = ss2.song_id
            AND ss2.id > ss1.id + 1
          WHERE ss1.song_id IS NOT NULL
        ) sandwiches
        GROUP BY set_id
        HAVING COUNT(DISTINCT song_id) > 1
        """),
      on: counts.set_id == set.id,
      select: %{
        set_id: set.id,
        set_title: set.title,
        set_date: fragment("COALESCE(?, ?)", set.date, set.release_date),
        sandwich_count: counts.sandwich_count
      }
    )

    query = case sort_by do
      "sandwich_count" ->
        order_by(query, [set, counts], [{^sort_dir, counts.sandwich_count}])
      _ ->
        order_by(query, [set, counts], [{^sort_dir, fragment("COALESCE(?, ?)", set.date, set.release_date)}])
    end

    Repo.all(query)
  end

  @doc """
  Returns songs that have returned after the longest gaps (bustouts).
  Shows the song, the set it returned in, and days since last played.
  """
  def list_bustouts(params \\ %{}) do
    sort_by = params["sort_by"] || "gap_days"
    sort_dir = if params["sort"] == "asc", do: "ASC", else: "DESC"

    order_clause = case sort_by do
      "date" -> "sa.play_date #{sort_dir}"
      _ -> "gap_days #{sort_dir}"
    end

    sql = """
    WITH song_appearances AS (
      SELECT
        ss.song_id,
        ss.set_id,
        COALESCE(s.date, s.release_date) as play_date,
        LAG(COALESCE(s.date, s.release_date)) OVER (PARTITION BY ss.song_id ORDER BY COALESCE(s.date, s.release_date)) as prev_date
      FROM set_songs ss
      JOIN sets s ON ss.set_id = s.id
      WHERE ss.song_id IS NOT NULL
    )
    SELECT sa.song_id, s.title as song_title, s.display_name as song_display_name,
           sa.set_id, st.title as set_title, sa.play_date as set_date,
           (sa.play_date - sa.prev_date) as gap_days
    FROM song_appearances sa
    JOIN songs s ON s.id = sa.song_id
    JOIN sets st ON st.id = sa.set_id
    WHERE sa.prev_date IS NOT NULL
    ORDER BY #{order_clause}
    LIMIT 100
    """

    Repo.query!(sql).rows
    |> Enum.map(fn [song_id, song_title, song_display_name, set_id, set_title, set_date, gap_days] ->
      %{
        song_id: song_id,
        song_title: song_title,
        song_display_name: song_display_name,
        set_id: set_id,
        set_title: set_title,
        set_date: set_date,
        gap_days: gap_days
      }
    end)
  end

  @doc """
  Returns songs played at the most consecutive shows.
  """
  def list_song_streaks(params \\ %{}) do
    sort_by = params["sort_by"] || "streak_length"
    sort_dir = if params["sort"] == "asc", do: "ASC", else: "DESC"

    order_clause = case sort_by do
      "date" -> "ms.streak_start #{sort_dir}"
      _ -> "ms.max_streak #{sort_dir}, s.display_name, s.title"
    end

    sql = """
    WITH ordered_sets AS (
      SELECT id, COALESCE(date, release_date) as play_date,
             ROW_NUMBER() OVER (ORDER BY COALESCE(date, release_date)) as set_num
      FROM sets
      WHERE COALESCE(date, release_date) IS NOT NULL
    ),
    song_sets AS (
      SELECT DISTINCT ss.song_id, os.set_num, os.play_date
      FROM set_songs ss
      JOIN ordered_sets os ON ss.set_id = os.id
      WHERE ss.song_id IS NOT NULL
    ),
    streaks AS (
      SELECT song_id, set_num, play_date,
             set_num - ROW_NUMBER() OVER (PARTITION BY song_id ORDER BY set_num) as grp
      FROM song_sets
    ),
    streak_lengths AS (
      SELECT song_id, MIN(play_date) as streak_start, MAX(play_date) as streak_end, COUNT(*) as streak_length
      FROM streaks
      GROUP BY song_id, grp
    ),
    max_streaks AS (
      SELECT song_id, streak_start, streak_end, streak_length as max_streak
      FROM streak_lengths sl
      WHERE streak_length = (SELECT MAX(streak_length) FROM streak_lengths WHERE song_id = sl.song_id)
    )
    SELECT s.id as song_id, s.title as song_title, s.display_name as song_display_name,
           ms.max_streak as streak_length, ms.streak_start, ms.streak_end
    FROM max_streaks ms
    JOIN songs s ON s.id = ms.song_id
    ORDER BY #{order_clause}
    LIMIT 100
    """

    Repo.query!(sql).rows
    |> Enum.map(fn [song_id, song_title, song_display_name, streak_length, streak_start, streak_end] ->
      %{
        song_id: song_id,
        song_title: song_title,
        song_display_name: song_display_name,
        streak_length: streak_length,
        streak_start: streak_start,
        streak_end: streak_end
      }
    end)
  end

  @doc """
  Returns most common set openers.
  """
  def list_common_openers do
    from(song in Song,
      join: opener in fragment("""
        SELECT ss.song_id, COUNT(*) as open_count
        FROM set_songs ss
        JOIN (
          SELECT set_id, MIN(id) as first_id
          FROM set_songs
          GROUP BY set_id
        ) firsts ON ss.set_id = firsts.set_id AND ss.id = firsts.first_id
        WHERE ss.song_id IS NOT NULL
        GROUP BY ss.song_id
        ORDER BY open_count DESC
        """),
      on: opener.song_id == song.id,
      select: %{
        song_id: song.id,
        song_title: song.title,
        song_display_name: song.display_name,
        count: opener.open_count
      },
      order_by: [desc: opener.open_count]
    )
    |> Repo.all()
  end

  @doc """
  Returns most common set closers.
  """
  def list_common_closers do
    from(song in Song,
      join: closer in fragment("""
        SELECT ss.song_id, COUNT(*) as close_count
        FROM set_songs ss
        JOIN (
          SELECT set_id, MAX(id) as last_id
          FROM set_songs
          GROUP BY set_id
        ) lasts ON ss.set_id = lasts.set_id AND ss.id = lasts.last_id
        WHERE ss.song_id IS NOT NULL
        GROUP BY ss.song_id
        ORDER BY close_count DESC
        """),
      on: closer.song_id == song.id,
      select: %{
        song_id: song.id,
        song_title: song.title,
        song_display_name: song.display_name,
        count: closer.close_count
      },
      order_by: [desc: closer.close_count]
    )
    |> Repo.all()
  end

  @doc """
  Returns song pairings - songs that most frequently follow each other.
  """
  def list_song_pairings do
    from(s1 in Song,
      join: pairing in fragment("""
        SELECT ss1.song_id as song1_id, ss2.song_id as song2_id, COUNT(*) as pair_count
        FROM set_songs ss1
        JOIN set_songs ss2 ON ss1.set_id = ss2.set_id AND ss2.id = ss1.id + 1
        WHERE ss1.song_id IS NOT NULL AND ss2.song_id IS NOT NULL
        GROUP BY ss1.song_id, ss2.song_id
        HAVING COUNT(*) > 1
        ORDER BY pair_count DESC
        LIMIT 100
        """),
      on: pairing.song1_id == s1.id,
      join: s2 in Song, on: s2.id == pairing.song2_id,
      select: %{
        song1_id: s1.id,
        song1_title: s1.title,
        song1_display_name: s1.display_name,
        song2_id: s2.id,
        song2_title: s2.title,
        song2_display_name: s2.display_name,
        count: pairing.pair_count
      },
      order_by: [desc: pairing.pair_count]
    )
    |> Repo.all()
  end

  @doc """
  Returns rare songs - played only 1-3 times.
  """
  def list_rare_songs do
    from(song in Song,
      join: ss in SetSong, on: ss.song_id == song.id,
      group_by: song.id,
      having: count(ss.id) <= 3,
      select: %{
        song_id: song.id,
        song_title: song.title,
        song_display_name: song.display_name,
        play_count: count(ss.id)
      },
      order_by: [asc: count(ss.id), asc: fragment("COALESCE(?, ?)", song.display_name, song.title)]
    )
    |> Repo.all()
  end

  @doc """
  Returns sets ordered by total duration.
  """
  def list_longest_sets(params \\ %{}) do
    sort_by = params["sort_by"] || "duration"
    sort_dir = if params["sort"] == "asc", do: :asc, else: :desc

    base_query = from(set in Set,
      join: ss in SetSong, on: ss.set_id == set.id,
      group_by: set.id,
      select: %{
        set_id: set.id,
        set_title: set.title,
        set_date: fragment("COALESCE(?, ?)", set.date, set.release_date),
        total_duration: sum(ss.duration),
        song_count: count(ss.id)
      }
    )

    query = case sort_by do
      "date" ->
        from([set, ss] in base_query,
          order_by: [{^sort_dir, fragment("COALESCE(?, ?)", set.date, set.release_date)}]
        )
      _ ->
        from([set, ss] in base_query,
          order_by: [{^sort_dir, sum(ss.duration)}]
        )
    end

    query
    |> Repo.all()
    |> Enum.filter(& &1.total_duration)
  end

  @doc """
  Returns songs that appear 3+ times in a single set (triple sandwiches).
  """
  def list_triple_sandwiches(params \\ %{}) do
    sort_by = params["sort_by"] || "appearances"
    sort_dir = if params["sort"] == "asc", do: :asc, else: :desc

    base_query = from(song in Song,
      join: triple in fragment("""
        SELECT ss.song_id, ss.set_id, COUNT(*) as appearance_count
        FROM set_songs ss
        WHERE ss.song_id IS NOT NULL
        GROUP BY ss.song_id, ss.set_id
        HAVING COUNT(*) >= 3
        """),
      on: triple.song_id == song.id,
      join: set in Set, on: set.id == triple.set_id,
      select: %{
        song_id: song.id,
        song_title: song.title,
        song_display_name: song.display_name,
        set_id: set.id,
        set_title: set.title,
        set_date: fragment("COALESCE(?, ?)", set.date, set.release_date),
        appearances: triple.appearance_count
      }
    )

    query = case sort_by do
      "date" ->
        from([song, triple, set] in base_query,
          order_by: [{^sort_dir, fragment("COALESCE(?, ?)", set.date, set.release_date)}]
        )
      _ ->
        from([song, triple, set] in base_query,
          order_by: [{^sort_dir, triple.appearance_count}, desc: fragment("COALESCE(?, ?)", set.date, set.release_date)]
        )
    end

    Repo.all(query)
  end

  @doc """
  Returns debut performances - first time each song was played.
  """
  def list_debuts(params \\ %{}) do
    sort_dir = if params["sort"] == "asc", do: :asc, else: :desc

    from(song in Song,
      join: debut in fragment("""
        SELECT ss.song_id, ss.set_id, COALESCE(s.date, s.release_date) as debut_date
        FROM set_songs ss
        JOIN sets s ON ss.set_id = s.id
        WHERE ss.song_id IS NOT NULL
          AND COALESCE(s.date, s.release_date) = (
            SELECT MIN(COALESCE(s2.date, s2.release_date))
            FROM set_songs ss2
            JOIN sets s2 ON ss2.set_id = s2.id
            WHERE ss2.song_id = ss.song_id
          )
        """),
      on: debut.song_id == song.id,
      join: set in Set, on: set.id == debut.set_id,
      select: %{
        song_id: song.id,
        song_title: song.title,
        song_display_name: song.display_name,
        set_id: set.id,
        set_title: set.title,
        debut_date: debut.debut_date
      },
      order_by: [{^sort_dir, debut.debut_date}]
    )
    |> Repo.all()
  end
end
