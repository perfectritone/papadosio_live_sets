defmodule BandcampScraper.MusicFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BandcampScraper.Music` context.
  """

  @doc """
  Generate a set.
  """
  def set_fixture(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])
    {:ok, set} =
      attrs
      |> Enum.into(%{
        date: ~D[2023-11-07],
        release_date: ~D[2023-11-07],
        thumbnail: "some thumbnail",
        title: "some title #{unique_id}",
        urn: "some urn #{unique_id}"
      })
      |> BandcampScraper.Music.create_set()

    set
  end

  @doc """
  Generate a song.
  """
  def song_fixture(attrs \\ %{}) do
    {:ok, song} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> BandcampScraper.Music.create_song()

    song
  end

  @doc """
  Generate a set_song.
  """
  def set_song_fixture(attrs \\ %{}) do
    # Create a set if set_id not provided
    attrs = if Map.has_key?(attrs, :set_id) do
      attrs
    else
      set = set_fixture()
      Map.put(attrs, :set_id, set.id)
    end

    {:ok, set_song} =
      attrs
      |> Enum.into(%{
        duration: 42,
        title: "some title",
        urn: "some urn"
      })
      |> BandcampScraper.Music.create_set_song()

    set_song
  end
end
