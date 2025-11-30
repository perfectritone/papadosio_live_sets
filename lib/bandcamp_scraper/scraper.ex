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
    # Extract from both data-client-items JSON and direct HTML links
    # Some featured/recent albums are only in the HTML, not in data-client-items
    json_sets = extract_data_client_items(html) |> transform_client_items
    html_sets = extract_html_album_links(html)

    # Merge, preferring json_sets for duplicates (they have more data)
    json_urns = MapSet.new(Enum.map(json_sets, & &1.urn))

    new_html_sets = Enum.reject(html_sets, fn set -> MapSet.member?(json_urns, set.urn) end)

    new_html_sets ++ json_sets
  end

  def extract_html_album_links(html) do
    {:ok, document} = Floki.parse_document(html)

    # Find album links in the music grid that have images (to get thumbnails)
    Floki.find(document, "#music-grid li a[href^=\"/album/\"]")
    |> Enum.map(fn link_element ->
      href = Floki.attribute(link_element, "href") |> List.first()
      img = Floki.find(link_element, "img") |> List.first()
      img_src = if img, do: Floki.attribute(img, "src") |> List.first(), else: nil

      # Try to get title from various places
      title = extract_album_title(link_element, href)

      %{
        title: title |> DateExtractor.strip_zero_width(),
        urn: href,
        thumbnail: img_src
      }
    end)
    |> Enum.filter(fn set -> set.urn != nil end)
    |> Enum.uniq_by(& &1.urn)
  end

  defp extract_album_title(link_element, href) do
    # Try to find title in link text or nearby elements
    title_text = Floki.find(link_element, ".title") |> Floki.text() |> String.trim()

    if title_text != "" do
      title_text
    else
      # Fall back to extracting from URL
      href
      |> String.replace("/album/", "")
      |> String.replace("-", " ")
      |> String.split()
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")
    end
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
