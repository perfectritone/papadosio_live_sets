defmodule BandcampScraper.Schemas.Song do
  use Ecto.Schema

  alias BandcampScraper.Schemas.Set

  schema "songs" do
    field :title, :string
    field :urn, :string
    field :duration, :integer
    belongs_to :set, Set

    timestamps()
  end
end

