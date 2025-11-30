defmodule BandcampScraperWeb.SetsLive do
  use BandcampScraperWeb, :live_view

  alias BandcampScraper.Music
  alias BandcampScraper.Music.Set
  alias BandcampScraper.Accounts

  import BandcampScraperWeb.BandcampUrlHelper

  @impl true
  def mount(_params, session, socket) do
    current_user = case session["user_id"] do
      nil -> nil
      user_id -> Accounts.get_user!(user_id)
    end

    {:ok, assign(socket,
      sets: [],
      years: Music.list_set_years(),
      songs: Music.list_songs(%{"sort" => "asc"}),
      search: "",
      year: "",
      season: "",
      sort: "desc",
      current_songs: [""],
      in_order: false,
      current_user: current_user
    )}
  rescue
    Ecto.NoResultsError ->
      {:ok, assign(socket,
        sets: [],
        years: Music.list_set_years(),
        songs: Music.list_songs(%{"sort" => "asc"}),
        search: "",
        year: "",
        season: "",
        sort: "desc",
        current_songs: [""],
        in_order: false,
        current_user: nil
      )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = params["search"] || ""
    year = params["year"] || ""
    season = params["season"] || ""
    sort = params["sort"] || "desc"
    in_order = params["in_order"] == "true"

    current_songs = case params["songs"] do
      nil -> [""]
      list when is_list(list) ->
        filtered = Enum.filter(list, &(&1 != ""))
        if filtered == [], do: [""], else: filtered
      _ -> [""]
    end

    sets = Music.list_sets(%{
      "search" => search,
      "year" => year,
      "season" => season,
      "sort" => sort,
      "songs" => current_songs,
      "in_order" => if(in_order, do: "true", else: nil)
    })

    {:noreply, assign(socket,
      sets: sets,
      search: search,
      year: year,
      season: season,
      sort: sort,
      current_songs: current_songs,
      in_order: in_order
    )}
  end

  @impl true
  def handle_event("filter", params, socket) do
    search = params["search"] || ""
    year = params["year"] || ""
    season = params["season"] || ""
    sort = params["sort"] || "desc"
    in_order = params["in_order"] == "true"
    songs = params["songs"] || [""]

    query_params = %{search: search, year: year, season: season, sort: sort}
    query_params = if in_order, do: Map.put(query_params, :in_order, "true"), else: query_params

    # Filter out empty song selections for URL
    filtered_songs = Enum.filter(songs, &(&1 != ""))
    query_params = if filtered_songs != [], do: Map.put(query_params, :songs, filtered_songs), else: query_params

    {:noreply, push_patch(socket, to: ~p"/sets?#{query_params}")}
  end

  @impl true
  def handle_event("add_song", _, socket) do
    {:noreply, assign(socket, current_songs: socket.assigns.current_songs ++ [""])}
  end

  @impl true
  def handle_event("remove_song", %{"index" => index}, socket) do
    index = String.to_integer(index)
    new_songs = List.delete_at(socket.assigns.current_songs, index)
    new_songs = if new_songs == [], do: [""], else: new_songs
    {:noreply, assign(socket, current_songs: new_songs)}
  end

  defp effective_date(set), do: Set.effective_date(set)

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      All Sets
      <:actions>
        <%= if @current_user && @current_user.role == "admin" do %>
          <.link href={~p"/sets/new"}>
            <.button>New Set</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <form phx-change="filter" phx-submit="filter" class="mb-4 space-y-4" id="set-filter-form">
      <div class="flex flex-wrap gap-4 items-end">
        <div>
          <label for="search" class="block text-sm font-medium text-dosio-teal">Search</label>
          <input
            type="text"
            name="search"
            id="search"
            value={@search}
            placeholder="Search set titles..."
            phx-debounce="300"
            class="mt-1 block rounded-md border-dosio-mint/30 shadow-sm focus:border-dosio-mint focus:ring-dosio-mint/50 sm:text-sm"
          />
        </div>

        <div>
          <label for="year" class="block text-sm font-medium text-dosio-teal">Year</label>
          <select name="year" id="year" class="mt-1 block rounded-md border-dosio-mint/30 shadow-sm focus:border-dosio-mint focus:ring-dosio-mint/50 sm:text-sm">
            <option value="">All Years</option>
            <%= for year <- @years do %>
              <option value={year} selected={to_string(year) == @year}><%= year %></option>
            <% end %>
          </select>
        </div>

        <div>
          <label for="season" class="block text-sm font-medium text-dosio-teal">Season</label>
          <select name="season" id="season" class="mt-1 block rounded-md border-dosio-mint/30 shadow-sm focus:border-dosio-mint focus:ring-dosio-mint/50 sm:text-sm">
            <option value="">All Seasons</option>
            <option value="spring" selected={@season == "spring"}>Spring</option>
            <option value="summer" selected={@season == "summer"}>Summer</option>
            <option value="fall" selected={@season == "fall"}>Fall</option>
            <option value="winter" selected={@season == "winter"}>Winter</option>
          </select>
        </div>

        <div>
          <label for="sort" class="block text-sm font-medium text-dosio-teal">Sort</label>
          <select name="sort" id="sort" class="mt-1 block rounded-md border-dosio-mint/30 shadow-sm focus:border-dosio-mint focus:ring-dosio-mint/50 sm:text-sm">
            <option value="desc" selected={@sort == "desc"}>Newest First</option>
            <option value="asc" selected={@sort == "asc"}>Oldest First</option>
          </select>
        </div>
      </div>

      <div class="border-t border-dosio-mint/20 pt-4">
        <div class="flex items-center gap-4 mb-3">
          <p class="text-sm font-medium text-dosio-teal">Song Search</p>
          <label class="flex items-center gap-2 text-sm text-dosio-teal">
            <input
              type="checkbox"
              name="in_order"
              value="true"
              checked={@in_order}
              class="rounded border-dosio-mint bg-dosio-dark text-white checked:bg-dosio-mint checked:border-dosio-mint focus:ring-dosio-mint focus:ring-offset-dosio-dark"
            />
            <span>In order (consecutive)</span>
          </label>
        </div>

        <div id="song-filters" class="space-y-2">
          <%= for {song_id, index} <- Enum.with_index(@current_songs) do %>
            <div class="flex gap-2 items-center song-row">
              <%= if index > 0 do %>
                <span class="text-dosio-teal text-sm w-6"><%= if @in_order, do: "→", else: "&" %></span>
              <% else %>
                <span class="w-6"></span>
              <% end %>
              <select name="songs[]" class="block rounded-md border-dosio-mint/30 shadow-sm focus:border-dosio-mint focus:ring-dosio-mint/50 sm:text-sm">
                <option value="">Select song</option>
                <%= for song <- @songs do %>
                  <option value={song.id} selected={to_string(song.id) == song_id}><%= song.display_name || song.title %></option>
                <% end %>
              </select>
              <%= if index > 0 do %>
                <button type="button" phx-click="remove_song" phx-value-index={index} class="text-red-400 hover:text-red-300 text-sm">✕</button>
              <% else %>
                <span class="w-4"></span>
              <% end %>
            </div>
          <% end %>
        </div>

        <button type="button" phx-click="add_song" class="mt-2 text-sm text-dosio-mint hover:text-white flex items-center gap-1">
          <span>+</span> Add song
        </button>
      </div>

      <div class="flex gap-2">
        <.link href={~p"/sets"} class="inline-flex items-center px-4 py-2 text-sm text-dosio-teal hover:text-white">Clear</.link>
      </div>
    </form>

    <.table id="sets" rows={@sets} row_click={fn set -> JS.navigate(~p"/sets/#{set}") end}>
      <:col :let={set} label="Title"><%= set.title %></:col>
      <:col :let={set} label="Bandcamp Link">
        <.link href={bandcamp_url_from_schema(set)} target="_blank" class="text-dosio-mint hover:text-white">Listen</.link>
      </:col>
      <:col :let={set} label="Date"><%= effective_date(set) %></:col>
      <:action :let={set}>
        <div class="sr-only">
          <.link navigate={~p"/sets/#{set}"}>Show</.link>
        </div>
        <%= if @current_user && @current_user.role == "admin" do %>
          <.link navigate={~p"/sets/#{set}/edit"}>Edit</.link>
        <% end %>
      </:action>
    </.table>
    """
  end
end
