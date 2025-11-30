defmodule BandcampScraper.MusicTest do
  use BandcampScraper.DataCase

  alias BandcampScraper.Music

  describe "sets" do
    alias BandcampScraper.Music.Set

    import BandcampScraper.MusicFixtures

    @invalid_attrs %{date: nil, title: nil, thumbnail: nil, urn: nil, release_date: nil}

    test "list_sets/0 returns all sets" do
      set = set_fixture()
      assert Music.list_sets() == [set]
    end

    test "get_set!/1 returns the set with given id" do
      set = set_fixture()
      assert Music.get_set!(set.id) == set
    end

    test "create_set/1 with valid data creates a set" do
      valid_attrs = %{date: ~D[2023-11-07], title: "some title", thumbnail: "some thumbnail", urn: "some urn", release_date: ~D[2023-11-07]}

      assert {:ok, %Set{} = set} = Music.create_set(valid_attrs)
      assert set.date == ~D[2023-11-07]
      assert set.title == "some title"
      assert set.thumbnail == "some thumbnail"
      assert set.urn == "some urn"
      assert set.release_date == ~D[2023-11-07]
    end

    test "create_set/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Music.create_set(@invalid_attrs)
    end

    test "update_set/2 with valid data updates the set" do
      set = set_fixture()
      update_attrs = %{date: ~D[2023-11-08], title: "some updated title", thumbnail: "some updated thumbnail", urn: "some updated urn", release_date: ~D[2023-11-08]}

      assert {:ok, %Set{} = set} = Music.update_set(set, update_attrs)
      assert set.date == ~D[2023-11-08]
      assert set.title == "some updated title"
      assert set.thumbnail == "some updated thumbnail"
      assert set.urn == "some updated urn"
      assert set.release_date == ~D[2023-11-08]
    end

    test "update_set/2 with invalid data returns error changeset" do
      set = set_fixture()
      assert {:error, %Ecto.Changeset{}} = Music.update_set(set, @invalid_attrs)
      assert set == Music.get_set!(set.id)
    end

    test "delete_set/1 deletes the set" do
      set = set_fixture()
      assert {:ok, %Set{}} = Music.delete_set(set)
      assert_raise Ecto.NoResultsError, fn -> Music.get_set!(set.id) end
    end

    test "change_set/1 returns a set changeset" do
      set = set_fixture()
      assert %Ecto.Changeset{} = Music.change_set(set)
    end
  end

  describe "songs" do
    alias BandcampScraper.Music.Song

    import BandcampScraper.MusicFixtures

    @invalid_attrs %{title: nil}

    test "list_songs/0 returns all songs" do
      song = song_fixture()
      assert Music.list_songs() == [song]
    end

    test "get_song!/1 returns the song with given id" do
      song = song_fixture()
      assert Music.get_song!(song.id) == song
    end

    test "create_song/1 with valid data creates a song" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %Song{} = song} = Music.create_song(valid_attrs)
      assert song.title == "some title"
    end

    test "create_song/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Music.create_song(@invalid_attrs)
    end

    test "update_song/2 with valid data updates the song" do
      song = song_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Song{} = song} = Music.update_song(song, update_attrs)
      assert song.title == "some updated title"
    end

    test "update_song/2 with invalid data returns error changeset" do
      song = song_fixture()
      assert {:error, %Ecto.Changeset{}} = Music.update_song(song, @invalid_attrs)
      assert song == Music.get_song!(song.id)
    end

    test "delete_song/1 deletes the song" do
      song = song_fixture()
      assert {:ok, %Song{}} = Music.delete_song(song)
      assert_raise Ecto.NoResultsError, fn -> Music.get_song!(song.id) end
    end

    test "change_song/1 returns a song changeset" do
      song = song_fixture()
      assert %Ecto.Changeset{} = Music.change_song(song)
    end
  end

  describe "set_songs" do
    alias BandcampScraper.Music.SetSong

    import BandcampScraper.MusicFixtures

    @invalid_attrs %{title: nil, urn: nil, duration: nil}

    test "list_set_songs/0 returns all set_songs" do
      set_song = set_song_fixture()
      assert Music.list_set_songs() == [set_song]
    end

    test "get_set_song!/1 returns the set_song with given id" do
      set_song = set_song_fixture()
      assert Music.get_set_song!(set_song.id) == set_song
    end

    test "create_set_song/1 with valid data creates a set_song" do
      set = set_fixture()
      valid_attrs = %{title: "some title", urn: "some urn", duration: 42, set_id: set.id}

      assert {:ok, %SetSong{} = set_song} = Music.create_set_song(valid_attrs)
      assert set_song.title == "some title"
      assert set_song.urn == "some urn"
      assert set_song.duration == 42
    end

    test "create_set_song/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Music.create_set_song(@invalid_attrs)
    end

    test "update_set_song/2 with valid data updates the set_song" do
      set_song = set_song_fixture()
      update_attrs = %{title: "some updated title", urn: "some updated urn", duration: 43}

      assert {:ok, %SetSong{} = set_song} = Music.update_set_song(set_song, update_attrs)
      assert set_song.title == "some updated title"
      assert set_song.urn == "some updated urn"
      assert set_song.duration == 43
    end

    test "update_set_song/2 with invalid data returns error changeset" do
      set_song = set_song_fixture()
      assert {:error, %Ecto.Changeset{}} = Music.update_set_song(set_song, @invalid_attrs)
      assert set_song == Music.get_set_song!(set_song.id)
    end

    test "delete_set_song/1 deletes the set_song" do
      set_song = set_song_fixture()
      assert {:ok, %SetSong{}} = Music.delete_set_song(set_song)
      assert_raise Ecto.NoResultsError, fn -> Music.get_set_song!(set_song.id) end
    end

    test "change_set_song/1 returns a set_song changeset" do
      set_song = set_song_fixture()
      assert %Ecto.Changeset{} = Music.change_set_song(set_song)
    end
  end
end
