defmodule Mix.Tasks.ProcessSongs do
  @moduledoc """
  Processes set_songs: extracts variants and matches to songs in one step.

  ## Usage

      mix process_songs           # Run both extraction and matching
      mix process_songs --dry-run # Preview without saving

  ## What it does

  1. Extracts variants from set_song titles (dates, parts, guests, etc.)
  2. Creates variant records and links them to set_songs
  3. Matches set_songs to songs using fuzzy title matching on cleaned titles
  4. Creates new songs as needed
  """

  use Mix.Task

  @shortdoc "Extract variants and match set_songs to songs"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args,
      strict: [dry_run: :boolean, threshold: :float],
      aliases: [d: :dry_run, t: :threshold]
    )

    dry_run = Keyword.get(opts, :dry_run, false)
    threshold = Keyword.get(opts, :threshold, 0.85)

    Mix.Task.run("app.start")

    Mix.shell().info("=== PROCESSING SONGS ===\n")

    # Step 1: Extract variants
    Mix.shell().info("Step 1: Extracting variants from titles...")
    variant_args = if dry_run, do: ["--dry-run"], else: []
    Mix.Task.rerun("extract_variants", variant_args)

    Mix.shell().info("\n" <> String.duplicate("=", 50) <> "\n")

    # Step 2: Match songs
    Mix.shell().info("Step 2: Matching set_songs to songs...")
    match_args = ["--threshold", Float.to_string(threshold)]
    match_args = if dry_run, do: match_args ++ ["--dry-run"], else: match_args
    Mix.Task.rerun("match_songs", match_args)

    Mix.shell().info("\n=== PROCESSING COMPLETE ===")
  end
end
