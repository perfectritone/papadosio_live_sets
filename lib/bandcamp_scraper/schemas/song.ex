defmodule BandcampScraper.Schemas.Song do
  use Ecto.Schema

  alias BandcampScraper.Schemas.SetSong

  schema "songs" do
    field :title, :string
    has_many :set_songs, SetSong

    timestamps()
  end
end
