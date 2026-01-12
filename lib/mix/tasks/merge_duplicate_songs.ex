defmodule Mix.Tasks.MergeDuplicateSongs do
  use Mix.Task

  import Ecto.Query
  alias BandcampScraper.Repo
  alias BandcampScraper.Music.{Song, SetSong, SongMatcher}

  @shortdoc "Find and merge duplicate songs based on fuzzy matching"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    threshold = case args do
      [t] -> String.to_float(t)
      _ -> 0.80
    end

    Mix.shell().info("Finding duplicate songs with threshold #{threshold}...")

    songs = Repo.all(from s in Song, order_by: s.title)
    duplicates = find_duplicates(songs, threshold)

    if length(duplicates) == 0 do
      Mix.shell().info("No duplicates found!")
    else
      Mix.shell().info("Found #{length(duplicates)} potential duplicate groups:\n")

      Enum.each(duplicates, fn {canonical, dupes} ->
        Mix.shell().info("  Keep: #{canonical.title} (id: #{canonical.id})")
        Enum.each(dupes, fn dupe ->
          Mix.shell().info("    Merge: #{dupe.title} (id: #{dupe.id})")
        end)
        Mix.shell().info("")
      end)

      if Mix.shell().yes?("Merge these duplicates?") do
        merge_all(duplicates)
        Mix.shell().info("Done! Merged #{length(duplicates)} groups.")
      else
        Mix.shell().info("Aborted.")
      end
    end
  end

  defp find_duplicates(songs, threshold) do
    songs
    |> Enum.reduce({[], MapSet.new()}, fn song, {groups, seen} ->
      if MapSet.member?(seen, song.id) do
        {groups, seen}
      else
        normalized = SongMatcher.normalize_title(song.title)

        # Find all songs that fuzzy match this one
        matches = Enum.filter(songs, fn other ->
          other.id != song.id and
          not MapSet.member?(seen, other.id) and
          is_valid_match?(normalized, SongMatcher.normalize_title(other.title), threshold)
        end)

        if length(matches) > 0 do
          # Mark all as seen
          new_seen = Enum.reduce(matches, MapSet.put(seen, song.id), fn m, acc ->
            MapSet.put(acc, m.id)
          end)
          {[{song, matches} | groups], new_seen}
        else
          {groups, seen}
        end
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp is_valid_match?(title1, title2, threshold) do
    # Check Jaro distance
    jaro = String.jaro_distance(title1, title2)
    if jaro < threshold, do: false, else: passes_safeguards?(title1, title2)
  end

  defp passes_safeguards?(title1, title2) do
    # Don't merge if one is a substring of the other (e.g., "Improv" vs "105 Improv")
    not String.contains?(title1, title2) and
    not String.contains?(title2, title1) and
    # Don't merge if lengths are too different (>40% difference)
    length_ratio(title1, title2) >= 0.6 and
    # First word should match (prevents "1979" matching "Eye")
    first_word_matches?(title1, title2)
  end

  defp length_ratio(s1, s2) do
    len1 = String.length(s1)
    len2 = String.length(s2)
    min(len1, len2) / max(len1, len2)
  end

  defp first_word_matches?(title1, title2) do
    word1 = title1 |> String.split() |> List.first() || ""
    word2 = title2 |> String.split() |> List.first() || ""
    # First words should be similar (allowing for typos)
    String.jaro_distance(word1, word2) >= 0.8
  end

  defp merge_all(duplicates) do
    Enum.each(duplicates, fn {canonical, dupes} ->
      Enum.each(dupes, fn dupe ->
        # Update all set_songs pointing to dupe to point to canonical
        from(ss in SetSong, where: ss.song_id == ^dupe.id)
        |> Repo.update_all(set: [song_id: canonical.id])

        # Delete the duplicate song
        Repo.delete!(dupe)
      end)
    end)
  end
end
