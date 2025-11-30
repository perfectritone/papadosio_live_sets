defmodule BandcampScraper.Scraper do
  alias BandcampScraper.Music.DateExtractor

  @bandcamp_domain "https://papadosio.bandcamp.com"

  def scrape_sets do
    releases_url()
    |> page_body
    |> extract_sets
  end

  def releases_url do
    @bandcamp_domain
    |> URI.parse
    |> Map.put(:path, "/music")
    |> URI.to_string()
  end

  def page_body(url) do
    HTTPoison.get!(url).body
  end

  def extract_sets(html) do
    extract_data_client_items(html)
    |> transform_client_items
  end

  def extract_data_client_items(html) do
    {:ok, document} = Floki.parse_document(html)

    Floki.find(document, "ol.music-grid")
    |> Floki.attribute("data-client-items")
    |> Jason.decode!
  end

  def transform_client_items(client_items) do
    Enum.map(client_items, &transform_client_item/1)
  end

  def transform_client_item(client_item) do
    %{
      title: DateExtractor.strip_zero_width(client_item["title"]),
      urn: client_item["page_url"],
      thumbnail: "https://f4.bcbits.com/img/a#{client_item["art_id"]}_2.jpg"
    }
  end
end
