defmodule BandcampScraper.SetScraper do
  @bandcamp_domain "https://papadosio.bandcamp.com"

  def scrape_set(urn) do
    set_url(urn)
    |> page_body
    |> extract_set
  end

  defp set_url(urn) do
    @bandcamp_domain
    |> URI.parse
    |> Map.put(:path, urn)
    |> URI.to_string()
  end

  defp page_body(url) do
    HTTPoison.get!(url).body
  end

  defp extract_set(html) do
    {:ok, doc} = Floki.parse_document(html)

    Floki.find(doc, "td.title-col .title")
    |> Enum.map(&extract_song/1)
  end

  defp extract_song(html_tree) do
    %{
      title: parse_title(html_tree),
      urn: parse_urn(html_tree),
      duration: parse_duration(html_tree)
    }
  end

  defp parse_title(html_tree) do
    html_tree
    |> Floki.find("a")
    |> Floki.find(".track-title")
    |> Floki.text
  end

  defp parse_urn(html_tree) do
    html_tree
    |> Floki.find("a")
    |> Floki.attribute("href")
    |> List.first
  end

  defp parse_duration(html_tree) do
    html_tree
    |> Floki.find(".time")
    |> Floki.text
    |> String.trim
    |> duration_string_to_seconds
  end

  def duration_string_to_seconds(raw_duration) do
    [minutes, seconds] = String.split(raw_duration, ":")
                         |> Enum.map(&String.to_integer/1)

    seconds + minutes * 60
  end
end
