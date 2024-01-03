defmodule BandcampScraperWeb.BandcampUrlHelper do

  def bandcamp_url_from_schema(schema) do
    schema.urn
    |> urn_to_bandcamp_url
  end

  def urn_to_bandcamp_url(urn) do
    "https://papadosio.bandcamp.com#{urn}"
  end
end
