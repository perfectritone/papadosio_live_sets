defmodule BandcampScraper.Music.Variant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "variants" do
    field :name, :string
    field :category, :string

    many_to_many :set_songs, BandcampScraper.Music.SetSong, join_through: "set_song_variants"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, [:name, :category])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @categories ~w(part night date version transition acoustic extended guest other)

  def categories, do: @categories
end
