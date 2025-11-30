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

  @doc """
  Returns a clickable date sort link with indicator.
  """
  def date_sort_link(song, current_sort) do
    next_sort = if current_sort == "desc", do: "asc", else: "desc"
    indicator = if current_sort == "desc", do: " ▼", else: " ▲"

    assigns = %{song: song, next_sort: next_sort, indicator: indicator}

    ~H"""
    <.link href={~p"/songs/#{@song}?date_sort=#{@next_sort}"} class="hover:text-white">Date<%= @indicator %></.link>
    """
  end
end
