defmodule Mix.Tasks.MatchSongs do
  @moduledoc """
  Maps set_songs to songs based on fuzzy title matching.

  ## Usage

      mix match_songs           # Run with default threshold (0.80)
      mix match_songs --threshold 0.9   # Custom threshold

  Uses the same SongMatcher logic as the scraping process.
  """

  use Mix.Task

  alias BandcampScraper.Music.SongMatcher

  @shortdoc "Match set_songs to songs using fuzzy title matching"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args,
      strict: [threshold: :float],
      aliases: [t: :threshold]
    )

    threshold = Keyword.get(opts, :threshold)

    Mix.Task.run("app.start")

    opts = if threshold, do: [threshold: threshold], else: []

    Mix.shell().info("Starting song matching...")

    {matched, created} = SongMatcher.match_all_set_songs(opts)

    Mix.shell().info("")
    Mix.shell().info("Summary:")
    Mix.shell().info("  Set songs matched: #{matched}")
    Mix.shell().info("  Songs created: #{created}")
  end
end
