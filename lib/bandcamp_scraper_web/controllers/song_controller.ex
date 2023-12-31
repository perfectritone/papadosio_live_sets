defmodule BandcampScraperWeb.SongController do
  use BandcampScraperWeb, :controller

  alias BandcampScraper.Schemas
  alias BandcampScraper.Schemas.Song

  def index(conn, _params) do
    songs = Schemas.list_songs()
    render(conn, :index, songs: songs)
  end

  def new(conn, _params) do
    changeset = Schemas.change_song(%Song{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"song" => song_params}) do
    case Schemas.create_song(song_params) do
      {:ok, song} ->
        conn
        |> put_flash(:info, "Song created successfully.")
        |> redirect(to: ~p"/songs/#{song}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    song = Schemas.get_song_with_set_songs!(id)
    #set_songs = Schemas.get_set_songs_by_song
    render(conn, :show, song: song)
  end

  def edit(conn, %{"id" => id}) do
    song = Schemas.get_song!(id)
    changeset = Schemas.change_song(song)
    render(conn, :edit, song: song, changeset: changeset)
  end

  def update(conn, %{"id" => id, "song" => song_params}) do
    song = Schemas.get_song!(id)

    case Schemas.update_song(song, song_params) do
      {:ok, song} ->
        conn
        |> put_flash(:info, "Song updated successfully.")
        |> redirect(to: ~p"/songs/#{song}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, song: song, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    song = Schemas.get_song!(id)
    {:ok, _song} = Schemas.delete_song(song)

    conn
    |> put_flash(:info, "Song deleted successfully.")
    |> redirect(to: ~p"/songs")
  end
end
