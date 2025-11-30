# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     BandcampScraper.Repo.insert!(%BandcampScraper.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias BandcampScraper.Accounts

# Create default admin user if it doesn't exist
unless Accounts.get_user_by_username("merp") do
  Accounts.create_user(%{
    username: "merp",
    password: "dosioposio",
    role: "admin"
  })
  |> case do
    {:ok, _user} -> IO.puts("Created admin user 'merp'")
    {:error, changeset} -> IO.puts("Failed to create admin user: #{inspect(changeset.errors)}")
  end
end
