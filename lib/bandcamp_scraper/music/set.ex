defmodule BandcampScraper.Music.Set do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sets" do
    field :date, :date
    field :title, :string
    field :thumbnail, :string
    field :urn, :string
    field :release_date, :date
    has_many :set_songs, BandcampScraper.Music.SetSong

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(set, attrs) do
    set
    |> cast(attrs, [:title, :thumbnail, :urn, :date, :release_date])
    |> validate_required([:title, :thumbnail, :urn])
  end

  @doc """
  Returns the effective date for display purposes.

  Falls back to release_date (Bandcamp upload date) if no show date
  was extracted from the title.
  """
  def effective_date(%__MODULE__{date: date}) when not is_nil(date), do: date
  def effective_date(%__MODULE__{release_date: release_date}), do: release_date
end
