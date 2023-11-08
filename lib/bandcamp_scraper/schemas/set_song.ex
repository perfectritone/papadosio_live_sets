defmodule BandcampScraper.Schemas.SetSong do
  use Ecto.Schema
  import Ecto.Changeset

  schema "set_songs" do
    field :title, :string
    field :urn, :string
    field :duration, :integer
    field :set_id, :id
    field :song_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(set_song, attrs) do
    set_song
    |> cast(attrs, [:title, :urn, :duration])
    |> validate_required([:title, :urn, :duration])
  end
end
