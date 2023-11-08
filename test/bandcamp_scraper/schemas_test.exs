defmodule BandcampScraper.SchemasTest do
  use BandcampScraper.DataCase

  alias BandcampScraper.Schemas

  describe "sets" do
    alias BandcampScraper.Schemas.Set

    import BandcampScraper.SchemasFixtures

    @invalid_attrs %{date: nil, title: nil, thumbnail: nil, urn: nil, release_date: nil}

    test "list_sets/0 returns all sets" do
      set = set_fixture()
      assert Schemas.list_sets() == [set]
    end

    test "get_set!/1 returns the set with given id" do
      set = set_fixture()
      assert Schemas.get_set!(set.id) == set
    end

    test "create_set/1 with valid data creates a set" do
      valid_attrs = %{date: ~D[2023-11-07], title: "some title", thumbnail: "some thumbnail", urn: "some urn", release_date: ~D[2023-11-07]}

      assert {:ok, %Set{} = set} = Schemas.create_set(valid_attrs)
      assert set.date == ~D[2023-11-07]
      assert set.title == "some title"
      assert set.thumbnail == "some thumbnail"
      assert set.urn == "some urn"
      assert set.release_date == ~D[2023-11-07]
    end

    test "create_set/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schemas.create_set(@invalid_attrs)
    end

    test "update_set/2 with valid data updates the set" do
      set = set_fixture()
      update_attrs = %{date: ~D[2023-11-08], title: "some updated title", thumbnail: "some updated thumbnail", urn: "some updated urn", release_date: ~D[2023-11-08]}

      assert {:ok, %Set{} = set} = Schemas.update_set(set, update_attrs)
      assert set.date == ~D[2023-11-08]
      assert set.title == "some updated title"
      assert set.thumbnail == "some updated thumbnail"
      assert set.urn == "some updated urn"
      assert set.release_date == ~D[2023-11-08]
    end

    test "update_set/2 with invalid data returns error changeset" do
      set = set_fixture()
      assert {:error, %Ecto.Changeset{}} = Schemas.update_set(set, @invalid_attrs)
      assert set == Schemas.get_set!(set.id)
    end

    test "delete_set/1 deletes the set" do
      set = set_fixture()
      assert {:ok, %Set{}} = Schemas.delete_set(set)
      assert_raise Ecto.NoResultsError, fn -> Schemas.get_set!(set.id) end
    end

    test "change_set/1 returns a set changeset" do
      set = set_fixture()
      assert %Ecto.Changeset{} = Schemas.change_set(set)
    end
  end

  describe "songs" do
    alias BandcampScraper.Schemas.Song

    import BandcampScraper.SchemasFixtures

    @invalid_attrs %{title: nil}

    test "list_songs/0 returns all songs" do
      song = song_fixture()
      assert Schemas.list_songs() == [song]
    end

    test "get_song!/1 returns the song with given id" do
      song = song_fixture()
      assert Schemas.get_song!(song.id) == song
    end

    test "create_song/1 with valid data creates a song" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %Song{} = song} = Schemas.create_song(valid_attrs)
      assert song.title == "some title"
    end

    test "create_song/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schemas.create_song(@invalid_attrs)
    end

    test "update_song/2 with valid data updates the song" do
      song = song_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Song{} = song} = Schemas.update_song(song, update_attrs)
      assert song.title == "some updated title"
    end

    test "update_song/2 with invalid data returns error changeset" do
      song = song_fixture()
      assert {:error, %Ecto.Changeset{}} = Schemas.update_song(song, @invalid_attrs)
      assert song == Schemas.get_song!(song.id)
    end

    test "delete_song/1 deletes the song" do
      song = song_fixture()
      assert {:ok, %Song{}} = Schemas.delete_song(song)
      assert_raise Ecto.NoResultsError, fn -> Schemas.get_song!(song.id) end
    end

    test "change_song/1 returns a song changeset" do
      song = song_fixture()
      assert %Ecto.Changeset{} = Schemas.change_song(song)
    end
  end
end
