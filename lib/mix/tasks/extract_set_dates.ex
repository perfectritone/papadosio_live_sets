defmodule Mix.Tasks.ExtractSetDates do
  @moduledoc """
  Extracts dates from set titles and updates the date field.

  ## Usage

      mix extract_set_dates           # Run extraction
      mix extract_set_dates --dry-run # Preview without saving

  """

  use Mix.Task

  import Ecto.Query
  alias BandcampScraper.Repo
  alias BandcampScraper.Music.{Set, DateExtractor}

  @shortdoc "Extract dates from set titles"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [dry_run: :boolean], aliases: [d: :dry_run])
    dry_run = Keyword.get(opts, :dry_run, false)

    Mix.Task.run("app.start")

    Mix.shell().info("Extracting dates from set titles...")
    if dry_run, do: Mix.shell().info("DRY RUN - no changes will be saved")

    extract_dates(dry_run)
  end

  defp extract_dates(dry_run) do
    # Get sets without dates
    sets_without_dates =
      Set
      |> where([s], is_nil(s.date))
      |> Repo.all()

    all_sets = Repo.all(Set)

    Mix.shell().info("Found #{length(all_sets)} total sets")
    Mix.shell().info("Found #{length(sets_without_dates)} sets without dates")

    # Extract dates
    results =
      sets_without_dates
      |> Enum.map(fn set ->
        {set, DateExtractor.extract_date(set.title)}
      end)

    {found, not_found} = Enum.split_with(results, fn {_, result} -> match?({:ok, _}, result) end)

    Mix.shell().info("\n=== DATES FOUND (#{length(found)}) ===")
    found
    |> Enum.take(30)
    |> Enum.each(fn {set, {:ok, date}} ->
      Mix.shell().info("  #{date} <- \"#{set.title}\"")
    end)

    if length(found) > 30 do
      Mix.shell().info("  ... and #{length(found) - 30} more")
    end

    Mix.shell().info("\n=== NO DATE FOUND (#{length(not_found)}) ===")
    not_found
    |> Enum.each(fn {set, _} ->
      Mix.shell().info("  \"#{set.title}\"")
    end)

    unless dry_run do
      Mix.shell().info("\n=== UPDATING DATABASE ===")

      updated =
        Enum.reduce(found, 0, fn {set, {:ok, date}}, count ->
          set
          |> Set.changeset(%{date: date})
          |> Repo.update!()
          count + 1
        end)

      Mix.shell().info("Updated #{updated} sets with dates")
    end

    Mix.shell().info("\nDone!")
  end
end
