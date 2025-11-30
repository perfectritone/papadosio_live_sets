defmodule BandcampScraperWeb.SetSongControllerTest do
  use BandcampScraperWeb.ConnCase

  import BandcampScraper.MusicFixtures

  @update_attrs %{title: "some updated title", urn: "some updated urn", duration: 43}
  @invalid_attrs %{title: nil, urn: nil, duration: nil}

  defp create_attrs do
    set = set_fixture()
    %{title: "some title", urn: "some urn", duration: 42, set_id: set.id}
  end

  describe "index" do
    test "lists all set_songs", %{conn: conn} do
      conn = get(conn, ~p"/set_songs")
      assert html_response(conn, 200) =~ "Listing Set songs"
    end
  end

  describe "new set_song" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/set_songs/new")
      assert html_response(conn, 200) =~ "New Set song"
    end
  end

  describe "create set_song" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/set_songs", set_song: create_attrs())

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/set_songs/#{id}"

      conn = get(conn, ~p"/set_songs/#{id}")
      assert html_response(conn, 200) =~ "some title"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/set_songs", set_song: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Set song"
    end
  end

  describe "edit set_song" do
    setup [:create_set_song]

    test "renders form for editing chosen set_song", %{conn: conn, set_song: set_song} do
      conn = get(conn, ~p"/set_songs/#{set_song}/edit")
      assert html_response(conn, 200) =~ "Edit Set song"
    end
  end

  describe "update set_song" do
    setup [:create_set_song]

    test "redirects when data is valid", %{conn: conn, set_song: set_song} do
      conn = put(conn, ~p"/set_songs/#{set_song}", set_song: @update_attrs)
      assert redirected_to(conn) == ~p"/set_songs/#{set_song}"

      conn = get(conn, ~p"/set_songs/#{set_song}")
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{conn: conn, set_song: set_song} do
      conn = put(conn, ~p"/set_songs/#{set_song}", set_song: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Set song"
    end
  end

  describe "delete set_song" do
    setup [:create_set_song]

    test "deletes chosen set_song", %{conn: conn, set_song: set_song} do
      conn = delete(conn, ~p"/set_songs/#{set_song}")
      assert redirected_to(conn) == ~p"/set_songs"

      assert_error_sent 404, fn ->
        get(conn, ~p"/set_songs/#{set_song}")
      end
    end
  end

  defp create_set_song(_) do
    set_song = set_song_fixture()
    %{set_song: set_song}
  end
end
