defmodule BandcampScraper.Repo do
  use Ecto.Repo,
    otp_app: :bandcamp_scraper,
    adapter: Ecto.Adapters.Postgres
end
