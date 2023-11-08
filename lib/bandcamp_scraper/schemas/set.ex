defmodule BandcampScraper.Schemas.Set do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sets" do
    field :date, :date
    field :title, :string
    field :thumbnail, :string
    field :urn, :string
    field :release_date, :date
    has_many :set_songs, BandcampScraper.Schemas.SetSong

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(set, attrs) do
    set
    |> cast(attrs, [:title, :thumbnail, :urn, :date, :release_date])
    |> validate_required([:title, :thumbnail, :urn])
  end
end
