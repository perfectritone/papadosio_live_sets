defmodule BandcampScraper.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :role, :string, default: "user", null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username])

    alter table(:set_song_variants) do
      add :user_id, references(:users, on_delete: :nilify_all)
    end
  end
end
