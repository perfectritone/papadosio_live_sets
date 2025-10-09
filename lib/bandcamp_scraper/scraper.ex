defmodule BandcampScraper.Scraper do
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
      title: client_item["title"],
      urn: client_item["page_url"],
      thumbnail: "https://f4.bcbits.com/img/a#{client_item["art_id"]}_2.jpg"
      #date: parse_date_from_title(client_item["title"]),
    }
  end

  # defp parse_date_from_title(title) do
  #   Regex.run(~r/\d+.\d+.\d+/, title)
  #   |> retrieve_date_from_formatted_string
  # end

  # defp retrieve_date_from_formatted_string(nil), do: nil
  # defp retrieve_date_from_formatted_string(match) do
  #   [month, day, year] =
  #     match
  #     |> List.first
  #     |> String.split(".")
  #     |> Enum.map(&String.to_integer/1)

  #   Date.new(year, month, day)
  # end
end
