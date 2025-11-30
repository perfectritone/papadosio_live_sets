defmodule BandcampScraperWeb.SetHTML do
  use BandcampScraperWeb, :html

  alias BandcampScraper.Music.Set

  embed_templates "set_html/*"

  @doc """
  Renders a set form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def set_form(assigns)

  @doc """
  Returns the effective date for a set (show date or fallback to release date).
  """
  def effective_date(set), do: Set.effective_date(set)
end
