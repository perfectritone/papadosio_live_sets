defmodule BandcampScraperWeb.SongHTML do
  use BandcampScraperWeb, :html

  alias BandcampScraper.Music.Set

  embed_templates "song_html/*"

  @doc """
  Renders a song form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def song_form(assigns)

  @doc """
  Returns the effective date for a set.
  """
  def effective_date(set), do: Set.effective_date(set)
end
