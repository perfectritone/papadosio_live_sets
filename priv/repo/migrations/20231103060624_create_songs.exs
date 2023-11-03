defmodule BandcampScraper.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs) do
      add :title, :string

      timestamps()
    end

    alter table(:set_songs) do
      add :song_id, references(:songs)
    end
  end
end
