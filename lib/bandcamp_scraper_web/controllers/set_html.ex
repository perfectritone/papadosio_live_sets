defmodule BandcampScraperWeb.SetHTML do
  use BandcampScraperWeb, :html

  embed_templates "set_html/*"

  @doc """
  Renders a set form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def set_form(assigns)
end
