defmodule BandcampScraper.Repo.Migrations.CreateSets do
  use Ecto.Migration

  def change do
    create table(:sets) do
      add :title, :string
      add :thumbnail, :string
      add :urn, :string
      add :date, :date
      add :release_date, :date

      timestamps(type: :utc_datetime)
    end

    create table(:songs) do
      add :title, :string
      add :release_id, references(:sets)

      timestamps(type: :utc_datetime)
    end

    create table(:set_songs) do
      add :title, :string
      add :urn, :string
      add :duration, :integer
      add :set_id, references(:sets)
      add :song_id, references(:songs)

      timestamps(type: :utc_datetime)
    end

    create unique_index("sets", [:title])
    create unique_index("set_songs", [:set_id, :urn])
    create unique_index("songs", [:title])

    create index("set_songs", [:title])
  end
end
