defmodule Mix.Tasks.FetchReleaseDates do
  use Mix.Task

  import Ecto.Query
  alias BandcampScraper.{Repo, SetScraper}
  alias BandcampScraper.Music.Set

  @shortdoc "Fetch release dates from Bandcamp for all sets"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    sets = from(s in Set, where: is_nil(s.release_date)) |> Repo.all()
    total = length(sets)
    Mix.shell().info("Found #{total} sets without release_date")

    sets
    |> Enum.with_index(1)
    |> Enum.each(fn {set, idx} ->
      if rem(idx, 50) == 0, do: Mix.shell().info("  Progress: #{idx}/#{total}")
      Process.sleep(300)

      {_songs, release_date} = SetScraper.scrape_set(set.urn)

      if release_date do
        set |> Set.changeset(%{release_date: release_date}) |> Repo.update!()
      end
    end)

    Mix.shell().info("Done!")
  end
end
