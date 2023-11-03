defmodule BandcampScraper.Schemas.Set do
  use Ecto.Schema

  alias BandcampScraper.Schemas.Song

  schema "sets" do
    field :title, :string
    field :thumbnail, :string
    field :urn, :string
    field :date, :date
    field :release_date, :date
    has_many :songs, Song

    timestamps()
  end
end
