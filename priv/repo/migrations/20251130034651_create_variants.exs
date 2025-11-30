defmodule BandcampScraper.Repo.Migrations.CreateVariants do
  use Ecto.Migration

  def change do
    create table(:variants) do
      add :name, :string, null: false
      add :category, :string  # e.g., "part", "night", "date", "version", "transition", "acoustic", "extended"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:variants, [:name])

    create table(:set_song_variants) do
      add :set_song_id, references(:set_songs, on_delete: :delete_all), null: false
      add :variant_id, references(:variants, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:set_song_variants, [:set_song_id])
    create index(:set_song_variants, [:variant_id])
    create unique_index(:set_song_variants, [:set_song_id, :variant_id])
  end
end
