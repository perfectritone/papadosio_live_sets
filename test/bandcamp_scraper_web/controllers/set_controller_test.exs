defmodule BandcampScraperWeb.SetControllerTest do
  use BandcampScraperWeb.ConnCase

  import BandcampScraper.SchemasFixtures

  @create_attrs %{date: ~D[2023-11-07], title: "some title", thumbnail: "some thumbnail", urn: "some urn", release_date: ~D[2023-11-07]}
  @update_attrs %{date: ~D[2023-11-08], title: "some updated title", thumbnail: "some updated thumbnail", urn: "some updated urn", release_date: ~D[2023-11-08]}
  @invalid_attrs %{date: nil, title: nil, thumbnail: nil, urn: nil, release_date: nil}

  describe "index" do
    test "lists all sets", %{conn: conn} do
      conn = get(conn, ~p"/sets")
      assert html_response(conn, 200) =~ "Listing Sets"
    end
  end

  describe "new set" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/sets/new")
      assert html_response(conn, 200) =~ "New Set"
    end
  end

  describe "create set" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/sets", set: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/sets/#{id}"

      conn = get(conn, ~p"/sets/#{id}")
      assert html_response(conn, 200) =~ "Set #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/sets", set: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Set"
    end
  end

  describe "edit set" do
    setup [:create_set]

    test "renders form for editing chosen set", %{conn: conn, set: set} do
      conn = get(conn, ~p"/sets/#{set}/edit")
      assert html_response(conn, 200) =~ "Edit Set"
    end
  end

  describe "update set" do
    setup [:create_set]

    test "redirects when data is valid", %{conn: conn, set: set} do
      conn = put(conn, ~p"/sets/#{set}", set: @update_attrs)
      assert redirected_to(conn) == ~p"/sets/#{set}"

      conn = get(conn, ~p"/sets/#{set}")
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{conn: conn, set: set} do
      conn = put(conn, ~p"/sets/#{set}", set: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Set"
    end
  end

  describe "delete set" do
    setup [:create_set]

    test "deletes chosen set", %{conn: conn, set: set} do
      conn = delete(conn, ~p"/sets/#{set}")
      assert redirected_to(conn) == ~p"/sets"

      assert_error_sent 404, fn ->
        get(conn, ~p"/sets/#{set}")
      end
    end
  end

  defp create_set(_) do
    set = set_fixture()
    %{set: set}
  end
end
