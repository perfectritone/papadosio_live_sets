defmodule BandcampScraperWeb.SetSongHTML do
  use BandcampScraperWeb, :html

  embed_templates "set_song_html/*"

  @doc """
  Renders a set_song form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def set_song_form(assigns)
end
