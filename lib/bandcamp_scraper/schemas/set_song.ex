defmodule BandcampScraper.Schemas.SetSong do
  use Ecto.Schema

  alias BandcampScraper.Schemas.{Set, Song}

  schema "set_songs" do
    field :title, :string
    field :urn, :string
    field :duration, :integer
    belongs_to :set, Set
    belongs_to :song, Song

    timestamps()
  end
end

