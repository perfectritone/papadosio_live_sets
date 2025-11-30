defmodule BandcampScraper.Repo.Migrations.AddManualToSetSongVariants do
  use Ecto.Migration

  def change do
    alter table(:set_song_variants) do
      add :manual, :boolean, default: false, null: false
    end
  end
end
