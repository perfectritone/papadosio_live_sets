defmodule BandcampScraper.Music.SetSong do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:duration],
    sortable: [:duration]
  }

  schema "set_songs" do
    field :title, :string
    field :urn, :string
    field :duration, :integer
    belongs_to :set, BandcampScraper.Music.Set
    belongs_to :song, BandcampScraper.Music.Song

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(set_song, attrs) do
    set_song
    |> cast(attrs, [:title, :urn, :duration, :set_id, :song_id])
    |> validate_required([:title, :urn, :duration, :set_id])
  end
end
