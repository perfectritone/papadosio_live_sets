defmodule BandcampScraper.Repo.Migrations.CreateSets do
  use Ecto.Migration

  def change do
    create table(:sets) do
      add :title, :string
      add :thumbnail, :string
      add :urn, :string
      add :date, :date
      add :release_date, :date

      timestamps()
    end

    create table(:songs) do
      add :title, :string
      add :urn, :string
      add :duration, :integer
      add :set_id, references(:sets)

      timestamps()
    end

    create unique_index("sets", [:title])
    create unique_index("songs", [:set_id, :urn])

    create index("songs", [:title])
  end
end
