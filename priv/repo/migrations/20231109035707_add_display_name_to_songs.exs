defmodule BandcampScraper.Repo.Migrations.AddDisplayNameToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :display_name, :string
    end
  end
end
