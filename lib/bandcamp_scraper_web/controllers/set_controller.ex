defmodule BandcampScraperWeb.SetController do
  use BandcampScraperWeb, :controller

  alias BandcampScraper.Schemas
  alias BandcampScraper.Schemas.Set
  alias BandcampScraperWeb.ViewHelpers

  def index(conn, _params) do
    sets = Schemas.list_sets()
    render(conn, :index, sets: sets)
  end

  def new(conn, _params) do
    changeset = Schemas.change_set(%Set{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"set" => set_params}) do
    case Schemas.create_set(set_params) do
      {:ok, set} ->
        conn
        |> put_flash(:info, "Set created successfully.")
        |> redirect(to: ~p"/sets/#{set}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    set = Schemas.get_set!(id)
    set_songs = Schemas.get_set_songs_by_set_id!(id)
    url = ViewHelpers.urn_to_bandcamp_url(set.urn)
    thumbnail_attrs = %{
      src: set.thumbnail
    }

    render(conn, :show,
      set: set,
      set_songs: set_songs,
      thumbnail_attrs: thumbnail_attrs,
      url: url)
  end

  def edit(conn, %{"id" => id}) do
    set = Schemas.get_set!(id)
    changeset = Schemas.change_set(set)
    render(conn, :edit, set: set, changeset: changeset)
  end

  def update(conn, %{"id" => id, "set" => set_params}) do
    set = Schemas.get_set!(id)

    case Schemas.update_set(set, set_params) do
      {:ok, set} ->
        conn
        |> put_flash(:info, "Set updated successfully.")
        |> redirect(to: ~p"/sets/#{set}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, set: set, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    set = Schemas.get_set!(id)
    {:ok, _set} = Schemas.delete_set(set)

    conn
    |> put_flash(:info, "Set deleted successfully.")
    |> redirect(to: ~p"/sets")
  end
end
