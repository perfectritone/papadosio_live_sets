defmodule BandcampScraperWeb.SetController do
  use BandcampScraperWeb, :controller

  alias BandcampScraper.Music
  alias BandcampScraper.Music.Set

  def index(conn, params) do
    sets = Music.list_sets(params)
    years = Music.list_set_years()
    songs = Music.list_songs(%{"sort" => "asc"})

    # Handle songs[] array - ensure at least one empty slot
    current_songs = case params["songs"] do
      nil -> [""]
      list when is_list(list) ->
        filtered = Enum.filter(list, &(&1 != ""))
        if filtered == [], do: [""], else: filtered
      _ -> [""]
    end

    render(conn, :index,
      sets: sets,
      years: years,
      songs: songs,
      current_year: params["year"],
      current_season: params["season"],
      current_sort: params["sort"] || "desc",
      current_songs: current_songs,
      in_order: params["in_order"],
      current_search: params["search"]
    )
  end

  def new(conn, _params) do
    changeset = Music.change_set(%Set{})
    render(conn, :new, page_title: "New Set", changeset: changeset)
  end

  def create(conn, %{"set" => set_params}) do
    case Music.create_set(set_params) do
      {:ok, set} ->
        conn
        |> put_flash(:info, "Set created successfully.")
        |> redirect(to: ~p"/sets/#{set}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, page_title: "New Set", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    set = Music.get_set!(id)
    set_songs = Music.list_set_songs_by_set_id(id)
    thumbnail_attrs = %{
      src: set.thumbnail
    }

    render(conn, :show,
      page_title: set.title,
      set: set,
      set_songs: set_songs,
      thumbnail_attrs: thumbnail_attrs
    )
  end

  def edit(conn, %{"id" => id}) do
    set = Music.get_set!(id)
    changeset = Music.change_set(set)
    render(conn, :edit, page_title: "Edit #{set.title}", set: set, changeset: changeset)
  end

  def update(conn, %{"id" => id, "set" => set_params}) do
    set = Music.get_set!(id)

    case Music.update_set(set, set_params) do
      {:ok, set} ->
        conn
        |> put_flash(:info, "Set updated successfully.")
        |> redirect(to: ~p"/sets/#{set}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, page_title: "Edit #{set.title}", set: set, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    set = Music.get_set!(id)
    {:ok, _set} = Music.delete_set(set)

    conn
    |> put_flash(:info, "Set deleted successfully.")
    |> redirect(to: ~p"/sets")
  end
end
