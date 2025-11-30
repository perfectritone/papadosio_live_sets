defmodule BandcampScraperWeb.SongsLive do
  use BandcampScraperWeb, :live_view

  alias BandcampScraper.Music

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      songs: Music.list_songs(%{}),
      search: "",
      sort: "asc"
    )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = params["search"] || ""
    sort = params["sort"] || "asc"

    songs = Music.list_songs(%{"search" => search, "sort" => sort})

    {:noreply, assign(socket,
      songs: songs,
      search: search,
      sort: sort
    )}
  end

  @impl true
  def handle_event("search", %{"search" => search, "sort" => sort}, socket) do
    {:noreply, push_patch(socket, to: ~p"/songs?#{%{search: search, sort: sort}}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      All Songs
      <:actions>
        <.link href={~p"/songs/new"}>
          <.button>New Song</.button>
        </.link>
      </:actions>
    </.header>

    <form phx-change="search" class="mb-4 flex flex-wrap gap-4 items-end">
      <div>
        <label for="search" class="block text-sm font-medium text-zinc-700">Search</label>
        <input
          type="text"
          name="search"
          id="search"
          value={@search}
          placeholder="Search songs..."
          phx-debounce="300"
          class="mt-1 block rounded-md border-zinc-300 shadow-sm focus:border-zinc-500 focus:ring-zinc-500 sm:text-sm"
        />
      </div>

      <div>
        <label for="sort" class="block text-sm font-medium text-zinc-700">Sort</label>
        <select name="sort" id="sort" class="mt-1 block rounded-md border-zinc-300 shadow-sm focus:border-zinc-500 focus:ring-zinc-500 sm:text-sm">
          <option value="asc" selected={@sort == "asc"}>A-Z</option>
          <option value="desc" selected={@sort == "desc"}>Z-A</option>
        </select>
      </div>

      <div>
        <.link href={~p"/songs"} class="text-sm text-zinc-600 hover:text-zinc-900">Clear</.link>
      </div>
    </form>

    <.table id="songs" rows={@songs} row_click={fn song -> JS.navigate(~p"/songs/#{song}") end}>
      <:col :let={song} label="Title"><%= song.display_name || song.title %></:col>
      <:action :let={song}>
        <div class="sr-only">
          <.link navigate={~p"/songs/#{song}"}>Show</.link>
        </div>
        <.link navigate={~p"/songs/#{song}/edit"}>Edit</.link>
      </:action>
    </.table>
    """
  end
end
