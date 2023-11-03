defmodule BandcampScraper.SetParser do
  def parse({:ok, raw_set}) do
    %{
      # date: ~D[raw_set.release_date],
      date: raw_set.release_date,
      title: raw_set.title,
      bandcamp_id: raw_set.id,
      urn: raw_set.page_url,
    }
  end
end
