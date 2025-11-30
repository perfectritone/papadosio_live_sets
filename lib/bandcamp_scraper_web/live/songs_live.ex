defmodule BandcampScraperWeb.SongsLive do
  use BandcampScraperWeb, :live_view

  alias BandcampScraper.Music
  alias BandcampScraper.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = case session["user_id"] do
      nil -> nil
      user_id -> Accounts.get_user!(user_id)
    end

    {:ok, assign(socket,
      songs: Music.list_songs(%{}),
      search: "",
      sort: "asc",
      current_user: current_user
    )}
  rescue
    Ecto.NoResultsError -> {:ok, assign(socket, songs: Music.list_songs(%{}), search: "", sort: "asc", current_user: nil)}
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
      Songs
      <:actions>
        <%= if @current_user && @current_user.role == "admin" do %>
          <.link href={~p"/songs/new"}>
            <.button>New Song</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <form phx-change="search" class="mb-4 flex flex-wrap gap-4 items-end">
      <div>
        <label for="search" class="block text-sm font-medium text-dosio-teal">Search</label>
        <input
          type="text"
          name="search"
          id="search"
          value={@search}
          placeholder="Search songs..."
          phx-debounce="300"
          class="mt-1 block rounded-md border-dosio-mint/30 shadow-sm focus:border-dosio-mint focus:ring-dosio-mint/50 sm:text-sm"
        />
      </div>

      <div>
        <label for="sort" class="block text-sm font-medium text-dosio-teal">Sort</label>
        <select name="sort" id="sort" class="mt-1 block rounded-md border-dosio-mint/30 shadow-sm focus:border-dosio-mint focus:ring-dosio-mint/50 sm:text-sm">
          <option value="asc" selected={@sort == "asc"}>A-Z</option>
          <option value="desc" selected={@sort == "desc"}>Z-A</option>
        </select>
      </div>

      <div>
        <.link href={~p"/songs"} class="text-sm text-dosio-teal hover:text-white">Clear</.link>
      </div>
    </form>

    <.table id="songs" rows={@songs}>
      <:col :let={song} label="Title">
        <.link href={~p"/songs/#{song}"} class="hover:text-dosio-mint"><%= song.display_name || song.title %></.link>
      </:col>
      <:action :let={song}>
        <%= if @current_user && @current_user.role == "admin" do %>
          <.link href={~p"/songs/#{song}/edit"}>Edit</.link>
        <% end %>
      </:action>
    </.table>
    """
  end
end
