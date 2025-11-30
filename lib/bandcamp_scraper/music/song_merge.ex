defmodule BandcampScraper.Music.SongMerge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "song_merges" do
    field :source_title, :string
    field :target_title, :string
    belongs_to :target_song, BandcampScraper.Music.Song
    belongs_to :user, BandcampScraper.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(song_merge, attrs) do
    song_merge
    |> cast(attrs, [:source_title, :target_title, :target_song_id, :user_id])
    |> validate_required([:source_title, :target_title])
  end
end
