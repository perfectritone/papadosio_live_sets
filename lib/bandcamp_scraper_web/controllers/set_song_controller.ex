defmodule BandcampScraperWeb.SetSongController do
  use BandcampScraperWeb, :controller

  alias BandcampScraper.Music
  alias BandcampScraper.Music.SetSong

  def index(conn, params) do
    case Music.list_set_songs(params) do
      {:ok, {set_songs, _meta}} ->
        render(conn, :index, set_songs: set_songs)

      {:error, _meta} ->
        set_songs = Music.list_set_songs()
        render(conn, :index, set_songs: set_songs)
    end
  end

  def new(conn, _params) do
    changeset = Music.change_set_song(%SetSong{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"set_song" => set_song_params}) do
    case Music.create_set_song(set_song_params) do
      {:ok, set_song} ->
        conn
        |> put_flash(:info, "Set song created successfully.")
        |> redirect(to: ~p"/set_songs/#{set_song}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    set_song = Music.get_set_song_with_associations!(id)

    render(conn, :show,
      set_song: set_song
    )
  end

  def edit(conn, %{"id" => id}) do
    set_song = Music.get_set_song!(id)
    changeset = Music.change_set_song(set_song)
    render(conn, :edit, set_song: set_song, changeset: changeset)
  end

  def update(conn, %{"id" => id, "set_song" => set_song_params}) do
    set_song = Music.get_set_song!(id)

    case Music.update_set_song(set_song, set_song_params) do
      {:ok, set_song} ->
        conn
        |> put_flash(:info, "Set song updated successfully.")
        |> redirect(to: ~p"/set_songs/#{set_song}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, set_song: set_song, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    set_song = Music.get_set_song!(id)
    {:ok, _set_song} = Music.delete_set_song(set_song)

    conn
    |> put_flash(:info, "Set song deleted successfully.")
    |> redirect(to: ~p"/set_songs")
  end
end
