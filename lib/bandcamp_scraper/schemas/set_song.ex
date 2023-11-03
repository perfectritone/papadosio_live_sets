defmodule BandcampScraper.Schemas.SetSong do
  use Ecto.Schema

  alias BandcampScraper.Schemas.Set

  schema "set_songs" do
    field :title, :string
    field :urn, :string
    field :duration, :integer
    belongs_to :set, Set

    timestamps()
  end
end

