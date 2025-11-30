defmodule BandcampScraper.Repo.Migrations.CreateSongMerges do
  use Ecto.Migration

  def change do
    create table(:song_merges) do
      # Store the original title of the source song (since it gets deleted)
      add :source_title, :string, null: false
      # Store the target song title at time of merge (for reference)
      add :target_title, :string, null: false
      # Target song ID (still exists after merge)
      add :target_song_id, references(:songs, on_delete: :nilify_all)
      # User who performed the merge
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:song_merges, [:target_song_id])
    create index(:song_merges, [:user_id])
  end
end
