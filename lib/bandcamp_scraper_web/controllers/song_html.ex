defmodule BandcampScraperWeb.SongHTML do
  use BandcampScraperWeb, :html

  embed_templates "song_html/*"

  @doc """
  Renders a song form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def song_form(assigns)
end
