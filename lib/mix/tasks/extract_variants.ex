defmodule Mix.Tasks.ExtractVariants do
  @moduledoc """
  Extracts variants from set_song titles and creates variant records.

  ## Usage

      mix extract_variants           # Run extraction
      mix extract_variants --dry-run # Preview without saving

  ## Variant patterns detected

  - Parts: 1/2, 2/2, Pt 2, Part 1
  - Extended: XL
  - Nights: (Night 1), (Night 2)
  - Dates: (5.3.13), (2.16.13)
  - Transitions: > at end, ->
  - Acoustic: (Acoustic)
  - Guests: ft. Name, Ft. Name, w/ Name, (w/ Name)
  - Reprises: Reprise, (reprise)
  - Versions: v2, V2, 2.0
  - Intros: Intro at end
  """

  use Mix.Task

  alias BandcampScraper.Repo
  alias BandcampScraper.Music.{SetSong, VariantExtractor}

  @shortdoc "Extract variants from set_song titles"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [dry_run: :boolean], aliases: [d: :dry_run])
    dry_run = Keyword.get(opts, :dry_run, false)

    Mix.Task.run("app.start")

    Mix.shell().info("Extracting variants from set_song titles...")
    if dry_run, do: Mix.shell().info("DRY RUN - no changes will be saved")

    extract_variants(dry_run)
  end

  defp extract_variants(dry_run) do
    set_songs = Repo.all(SetSong)

    Mix.shell().info("Processing #{length(set_songs)} set_songs...")

    results =
      set_songs
      |> Enum.map(fn ss -> {ss, VariantExtractor.parse_title(ss.title)} end)
      |> Enum.filter(fn {_ss, {_clean, variants}} -> variants != [] end)

    Mix.shell().info("Found #{length(results)} set_songs with variants")

    # Collect all unique variants
    all_variants =
      results
      |> Enum.flat_map(fn {_ss, {_clean, variants}} -> variants end)
      |> Enum.uniq()
      |> Enum.sort_by(fn {name, cat} -> {cat, name} end)

    Mix.shell().info("\n=== UNIQUE VARIANTS (#{length(all_variants)}) ===")
    all_variants
    |> Enum.group_by(fn {_name, cat} -> cat end)
    |> Enum.sort_by(fn {cat, _} -> cat end)
    |> Enum.each(fn {category, variants} ->
      Mix.shell().info("\n#{category}:")
      Enum.each(variants, fn {name, _} -> Mix.shell().info("  - #{name}") end)
    end)

    Mix.shell().info("\n=== SAMPLE EXTRACTIONS ===")
    results
    |> Enum.take(30)
    |> Enum.each(fn {ss, {clean, variants}} ->
      variant_names = Enum.map(variants, fn {name, _} -> name end) |> Enum.join(", ")
      Mix.shell().info("  \"#{ss.title}\"")
      Mix.shell().info("    -> \"#{clean}\" [#{variant_names}]")
    end)

    unless dry_run do
      Mix.shell().info("\n=== SAVING TO DATABASE ===")

      # Create variants and link to set_songs
      linked =
        Enum.reduce(results, 0, fn {ss, {_clean, _variant_tuples}}, count ->
          variants = VariantExtractor.extract_variants(ss.title)
          if length(variants) > 0 do
            VariantExtractor.link_variants(ss.id, variants)
          end
          count + 1
        end)

      Mix.shell().info("Linked #{linked} set_songs to variants")
    end

    Mix.shell().info("\nDone!")
  end
end
