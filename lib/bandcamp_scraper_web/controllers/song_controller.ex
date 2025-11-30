defmodule BandcampScraperWeb.SongController do
  use BandcampScraperWeb, :controller

  alias BandcampScraper.Music
  alias BandcampScraper.Music.Song

  def index(conn, params) do
    case Music.list_songs(params) do
      {:ok, {songs, meta}} ->
        render(conn, :index, meta: meta, songs: songs)

      {:error, meta} ->
        render(conn, :index, meta: meta, songs: [])
    end
  end

  def new(conn, _params) do
    changeset = Music.change_song(%Song{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"song" => song_params}) do
    case Music.create_song(song_params) do
      {:ok, song} ->
        conn
        |> put_flash(:info, "Song created successfully.")
        |> redirect(to: ~p"/songs/#{song}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, params) do
    id = Map.fetch!(params, "id")
    song = Music.get_song!(id)

    case Music.get_set_songs_for_song(id, params) do
      {:ok, {set_songs, meta}} ->
        render(conn, :show, meta: meta, set_songs: set_songs, song: song)

      {:error, meta} ->
        render(conn, :show, meta: meta, set_songs: [], song: song)
    end
  end

  def edit(conn, %{"id" => id}) do
    song = Music.get_song!(id)
    changeset = Music.change_song(song)
    render(conn, :edit, song: song, changeset: changeset)
  end

  def update(conn, %{"id" => id, "song" => song_params}) do
    song = Music.get_song!(id)

    case Music.update_song(song, song_params) do
      {:ok, song} ->
        conn
        |> put_flash(:info, "Song updated successfully.")
        |> redirect(to: ~p"/songs/#{song}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, song: song, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    song = Music.get_song!(id)
    {:ok, _song} = Music.delete_song(song)

    conn
    |> put_flash(:info, "Song deleted successfully.")
    |> redirect(to: ~p"/songs")
  end
end
