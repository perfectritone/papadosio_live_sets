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
end
