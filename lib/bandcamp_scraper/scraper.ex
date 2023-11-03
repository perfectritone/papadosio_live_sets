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

  defp extract_sets(html) do
    {:ok, document} = Floki.parse_document(html)

    Floki.find(document, "ol.music-grid")
    |> Floki.find("li")
    |> Enum.map(&Floki.find(&1, "a"))
    |> Enum.map(&map_set_attrs/1)
  end

  defp map_set_attrs(html_tree) do
    title = parse_title(html_tree)

    %{
      title: title,
      urn: parse_urn(html_tree),
      #date: parse_date_from_title(title),
      thumbnail: parse_thumbnail(html_tree)
    }
  end

  defp parse_title(html_tree) do
    Floki.find(html_tree, "p")
    |> Floki.text
    |> String.trim
  end

  defp parse_date_from_title(title) do
    Regex.run(~r/\d+.\d+.\d+/, title)
    |> retrieve_date_from_formatted_string
  end

  defp retrieve_date_from_formatted_string(nil), do: nil
  defp retrieve_date_from_formatted_string(match) do
    [month, day, year] =
      match
      |> List.first
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)

    Date.new(year, month, day)
  end

  defp parse_urn(html_tree) do
    Floki.attribute(html_tree, "href")
    |> List.first
  end

  defp parse_thumbnail(html_tree) do
    Floki.find(html_tree, "div img")
    |> Floki.attribute("src")
    |> List.first
  end
end
