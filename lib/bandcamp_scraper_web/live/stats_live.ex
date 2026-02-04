defmodule BandcampScraperWeb.StatsLive do
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
      page_title: "Stats",
      view: "play_counts",
      play_counts: [],
      durations: [],
      sandwiches: [],
      multisong_sandwiches: [],
      multi_sandwich_sets: [],
      sort: "asc",
      sort_by: "song",
      current_user: current_user
    )}
  rescue
    Ecto.NoResultsError ->
      {:ok, assign(socket,
        page_title: "Stats",
        view: "play_counts",
        play_counts: [],
        durations: [],
        sandwiches: [],
        multisong_sandwiches: [],
        multi_sandwich_sets: [],
        sort: "asc",
        sort_by: "song",
        current_user: nil
      )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    view = params["view"] || "play_counts"

    socket = case view do
      "play_counts" ->
        play_counts = Music.list_songs_with_play_counts()
        assign(socket,
          page_title: "Song Play Counts",
          view: view,
          play_counts: play_counts
        )

      "durations" ->
        durations = Music.list_set_songs_by_duration()
        assign(socket,
          page_title: "Longest Performances",
          view: view,
          durations: durations
        )

      "sandwiches" ->
        sort = params["sort"] || "asc"
        sandwiches = Music.list_set_sandwiches(%{"sort" => sort})
        assign(socket,
          page_title: "Full Set Sandwiches",
          view: view,
          sandwiches: sandwiches,
          sort: sort
        )

      "multisong_sandwiches" ->
        sort = params["sort"] || "asc"
        sort_by = params["sort_by"] || "song"
        multisong_sandwiches = Music.list_multisong_sandwiches(%{"sort" => sort, "sort_by" => sort_by})
        assign(socket,
          page_title: "Sandwiches",
          view: view,
          multisong_sandwiches: multisong_sandwiches,
          sort: sort,
          sort_by: sort_by
        )

      "multi_sandwich_sets" ->
        sort = params["sort"] || "desc"
        sort_by = params["sort_by"] || "date"
        multi_sandwich_sets = Music.list_multi_sandwich_sets(%{"sort" => sort, "sort_by" => sort_by})
        assign(socket,
          page_title: "Multi-Sandwich Sets",
          view: view,
          multi_sandwich_sets: multi_sandwich_sets,
          sort: sort,
          sort_by: sort_by
        )

      _ ->
        assign(socket, view: "play_counts")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, push_patch(socket, to: ~p"/stats?#{%{view: view}}")}
  end

  defp format_duration(nil), do: "-"
  defp format_duration(seconds) when is_integer(seconds) do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Stats
    </.header>

    <div class="mb-6 flex gap-4">
      <button
        phx-click="change_view"
        phx-value-view="play_counts"
        class={"px-4 py-2 rounded-md text-sm font-medium #{if @view == "play_counts", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Song Play Counts
      </button>
      <button
        phx-click="change_view"
        phx-value-view="durations"
        class={"px-4 py-2 rounded-md text-sm font-medium #{if @view == "durations", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Longest Performances
      </button>
      <button
        phx-click="change_view"
        phx-value-view="sandwiches"
        class={"px-4 py-2 rounded-md text-sm font-medium #{if @view == "sandwiches", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Full Set Sandwiches
      </button>
      <button
        phx-click="change_view"
        phx-value-view="multisong_sandwiches"
        class={"px-4 py-2 rounded-md text-sm font-medium #{if @view == "multisong_sandwiches", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Sandwiches
      </button>
      <button
        phx-click="change_view"
        phx-value-view="multi_sandwich_sets"
        class={"px-4 py-2 rounded-md text-sm font-medium #{if @view == "multi_sandwich_sets", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Multi-Sandwich Sets
      </button>
    </div>

    <%= case @view do %>
      <% "play_counts" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Rank</th>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">Times Played</th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for {song, index} <- Enum.with_index(@play_counts, 1) do %>
                <tr>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= index %></td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{song.id}"} class="hover:text-dosio-mint">
                      <%= song.display_name || song.title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-right"><%= song.play_count %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "durations" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Rank</th>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">Duration</th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for {set_song, index} <- Enum.with_index(@durations, 1) do %>
                <tr>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= index %></td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/set_songs/#{set_song}"} class="hover:text-dosio-mint">
                      <%= if set_song.song, do: set_song.song.display_name || set_song.song.title, else: set_song.title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/sets/#{set_song.set}"} class="hover:text-dosio-mint">
                      <%= set_song.set.title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-right"><%= format_duration(set_song.duration) %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "sandwiches" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "sandwiches", sort: if(@sort == "asc", do: "desc", else: "asc")}}"} class="hover:text-dosio-mint">
                    Song <%= if @sort == "asc", do: "↑", else: "↓" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal">Date</th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for sandwich <- @sandwiches do %>
                <tr>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{sandwich.song_id}"} class="hover:text-dosio-mint">
                      <%= sandwich.song_display_name || sandwich.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/sets/#{sandwich.set_id}"} class="hover:text-dosio-mint">
                      <%= sandwich.set_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= sandwich.set_date %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "multisong_sandwiches" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "multisong_sandwiches", sort_by: "song", sort: if(@sort_by == "song" && @sort == "asc", do: "desc", else: "asc")}}"} class="hover:text-dosio-mint">
                    Song <%= if @sort_by == "song", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "multisong_sandwiches", sort_by: "date", sort: if(@sort_by == "date" && @sort == "asc", do: "desc", else: "asc")}}"} class="hover:text-dosio-mint">
                    Date <%= if @sort_by == "date", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">
                  <.link patch={~p"/stats?#{%{view: "multisong_sandwiches", sort_by: "songs_between", sort: if(@sort_by == "songs_between" && @sort == "asc", do: "desc", else: "asc")}}"} class="hover:text-dosio-mint">
                    Songs Between <%= if @sort_by == "songs_between", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for sandwich <- @multisong_sandwiches do %>
                <tr>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{sandwich.song_id}"} class="hover:text-dosio-mint">
                      <%= sandwich.song_display_name || sandwich.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/sets/#{sandwich.set_id}"} class="hover:text-dosio-mint">
                      <%= sandwich.set_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= sandwich.set_date %></td>
                  <td class="p-0 py-4 pr-6 text-right"><%= sandwich.songs_between %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "multi_sandwich_sets" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "multi_sandwich_sets", sort_by: "date", sort: if(@sort_by == "date" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Date <%= if @sort_by == "date", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">
                  <.link patch={~p"/stats?#{%{view: "multi_sandwich_sets", sort_by: "sandwich_count", sort: if(@sort_by == "sandwich_count" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Sandwiches <%= if @sort_by == "sandwich_count", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for set <- @multi_sandwich_sets do %>
                <tr>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/sets/#{set.set_id}"} class="hover:text-dosio-mint">
                      <%= set.set_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= set.set_date %></td>
                  <td class="p-0 py-4 pr-6 text-right"><%= set.sandwich_count %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% _ -> %>
        <p>Unknown view</p>
    <% end %>
    """
  end
end
