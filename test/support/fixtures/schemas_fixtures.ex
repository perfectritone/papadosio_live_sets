defmodule BandcampScraper.SchemasFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BandcampScraper.Schemas` context.
  """

  @doc """
  Generate a set.
  """
  def set_fixture(attrs \\ %{}) do
    {:ok, set} =
      attrs
      |> Enum.into(%{
        date: ~D[2023-11-07],
        release_date: ~D[2023-11-07],
        thumbnail: "some thumbnail",
        title: "some title",
        urn: "some urn"
      })
      |> BandcampScraper.Schemas.create_set()

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
      |> BandcampScraper.Schemas.create_song()

    song
  end
end
