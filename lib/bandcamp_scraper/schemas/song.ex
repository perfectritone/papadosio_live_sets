defmodule BandcampScraper.Schemas.Song do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:title],
    sortable: [:title]
  }

  schema "songs" do
    field :title, :string
    field :release_id, :id
    field :display_name, :string
    has_many :set_songs, BandcampScraper.Schemas.SetSong

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [:title, :display_name])
    |> validate_required([:title])
  end
end
