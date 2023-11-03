defmodule BandcampScraper.Schemas.Set do
  use Ecto.Schema

  alias BandcampScraper.Schemas.SetSong

  schema "sets" do
    field :title, :string
    field :thumbnail, :string
    field :urn, :string
    field :date, :date
    field :release_date, :date
    has_many :set_songs, SetSong

    timestamps()
  end
end
