defmodule BandcampScraperWeb.VariantController do
  use BandcampScraperWeb, :controller

  alias BandcampScraper.Music

  def index(conn, _params) do
    variants = Music.list_variants()
    render(conn, :index, variants: variants)
  end

  def show(conn, %{"id" => id}) do
    variant = Music.get_variant_with_set_songs!(id)
    render(conn, :show, variant: variant)
  end
end
