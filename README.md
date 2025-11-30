# BandcampScraper

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

BandcampScraper.ScrapePersister.persist_sets()

# Local setup

## Create the db

`mix ecto.create`
`mix ecto.load`

`iex -S mix`

`BandcampScraper.ScrapePersister.persist_sets()`

## Migrations

`mix ecto.migrate`
`mix ecto.dump`

## If the scraping stops
Recover by running this in the console

```
  import Ecto.Query
  alias BandcampScraper.{Repo, ScrapePersister}
  alias BandcampScraper.Music.{Set, SetSong}

  # Find sets without any set_songs
  sets_without_songs = Repo.all(
    from s in Set,
    left_join: ss in SetSong, on: ss.set_id == s.id,
    group_by: s.id,
    having: count(ss.id) == 0,
    select: s
  )

  IO.puts("Found #{length(sets_without_songs)} sets without songs")

  # Process each set with a delay to avoid throttling
  Enum.each(Enum.with_index(sets_without_songs), fn {set, i} ->
    IO.puts("#{i+1}/#{length(sets_without_songs)}: Processing #{set.title}")
    try do
      ScrapePersister.persist_set_songs(set)
      # 2 second delay between requests
      Process.sleep(2000)
    rescue
      e -> IO.puts("  Error: #{inspect(e)}")
    end
  end)

  IO.puts("Done!")
```
