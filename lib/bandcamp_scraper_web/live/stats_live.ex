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
      bustouts: [],
      streaks: [],
      openers: [],
      closers: [],
      pairings: [],
      rare_songs: [],
      longest_sets: [],
      triple_sandwiches: [],
      debuts: [],
      sort: "asc",
      sort_by: "song",
      show_menu: false,
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
        bustouts: [],
        streaks: [],
        openers: [],
        closers: [],
        pairings: [],
        rare_songs: [],
        longest_sets: [],
        triple_sandwiches: [],
        debuts: [],
        sort: "asc",
        sort_by: "song",
        show_menu: false,
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
        sort = params["sort"] || "desc"
        sort_by = params["sort_by"] || "date"
        sandwiches = Music.list_set_sandwiches(%{"sort" => sort, "sort_by" => sort_by})
        assign(socket,
          page_title: "Full Set Sandwiches",
          view: view,
          sandwiches: sandwiches,
          sort: sort,
          sort_by: sort_by
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

      "bustouts" ->
        sort = params["sort"] || "desc"
        sort_by = params["sort_by"] || "gap_days"
        bustouts = Music.list_bustouts(%{"sort" => sort, "sort_by" => sort_by})
        assign(socket, page_title: "Bustouts", view: view, bustouts: bustouts, sort: sort, sort_by: sort_by)

      "streaks" ->
        sort = params["sort"] || "desc"
        sort_by = params["sort_by"] || "streak_length"
        streaks = Music.list_song_streaks(%{"sort" => sort, "sort_by" => sort_by})
        assign(socket, page_title: "Song Streaks", view: view, streaks: streaks, sort: sort, sort_by: sort_by)

      "openers" ->
        assign(socket, page_title: "Common Openers", view: view, openers: Music.list_common_openers())

      "closers" ->
        assign(socket, page_title: "Common Closers", view: view, closers: Music.list_common_closers())

      "pairings" ->
        assign(socket, page_title: "Song Pairings", view: view, pairings: Music.list_song_pairings())

      "rare_songs" ->
        assign(socket, page_title: "Rare Songs", view: view, rare_songs: Music.list_rare_songs())

      "longest_sets" ->
        sort = params["sort"] || "desc"
        sort_by = params["sort_by"] || "duration"
        longest_sets = Music.list_longest_sets(%{"sort" => sort, "sort_by" => sort_by})
        assign(socket, page_title: "Longest Sets", view: view, longest_sets: longest_sets, sort: sort, sort_by: sort_by)

      "triple_sandwiches" ->
        sort = params["sort"] || "desc"
        sort_by = params["sort_by"] || "appearances"
        triple_sandwiches = Music.list_triple_sandwiches(%{"sort" => sort, "sort_by" => sort_by})
        assign(socket, page_title: "Triple Sandwiches", view: view, triple_sandwiches: triple_sandwiches, sort: sort, sort_by: sort_by)

      "debuts" ->
        sort = params["sort"] || "desc"
        debuts = Music.list_debuts(%{"sort" => sort})
        assign(socket, page_title: "Debut Performances", view: view, debuts: debuts, sort: sort)

      _ ->
        assign(socket, view: "play_counts")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, socket |> assign(show_menu: false) |> push_patch(to: ~p"/stats?#{%{view: view}}")}
  end

  @impl true
  def handle_event("toggle_menu", _params, socket) do
    {:noreply, assign(socket, show_menu: !socket.assigns.show_menu)}
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

    <div class="mb-6 flex flex-wrap gap-2 md:gap-4">
      <button
        phx-click="change_view"
        phx-value-view="play_counts"
        class={"px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium #{if @view == "play_counts", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Play Counts
      </button>
      <button
        phx-click="change_view"
        phx-value-view="durations"
        class={"px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium #{if @view == "durations", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Longest
      </button>
      <button
        phx-click="change_view"
        phx-value-view="sandwiches"
        class={"px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium #{if @view == "sandwiches", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Full Sandwiches
      </button>
      <button
        phx-click="change_view"
        phx-value-view="multisong_sandwiches"
        class={"px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium #{if @view == "multisong_sandwiches", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Sandwiches
      </button>
      <button
        phx-click="change_view"
        phx-value-view="multi_sandwich_sets"
        class={"px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium #{if @view == "multi_sandwich_sets", do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        Multi-Sandwich
      </button>
      <button
        phx-click="toggle_menu"
        class={"px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium #{if @view in ~w(bustouts streaks openers closers pairings rare_songs longest_sets triple_sandwiches debuts), do: "bg-dosio-mint text-dosio-dark", else: "bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint"}"}
      >
        More ⋮
      </button>
    </div>

    <%= if @show_menu do %>
      <div class="mb-4 w-full grid grid-cols-3 md:grid-cols-5 gap-2">
        <button phx-click="change_view" phx-value-view="bustouts" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Bustouts</button>
        <button phx-click="change_view" phx-value-view="streaks" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Streaks</button>
        <button phx-click="change_view" phx-value-view="openers" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Openers</button>
        <button phx-click="change_view" phx-value-view="closers" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Closers</button>
        <button phx-click="change_view" phx-value-view="pairings" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Pairings</button>
        <button phx-click="change_view" phx-value-view="rare_songs" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Rare Songs</button>
        <button phx-click="change_view" phx-value-view="longest_sets" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Longest Sets</button>
        <button phx-click="change_view" phx-value-view="triple_sandwiches" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Triple</button>
        <button phx-click="change_view" phx-value-view="debuts" class="px-3 py-1.5 md:py-2 rounded-md text-xs md:text-sm font-medium bg-dosio-dark text-dosio-teal border border-dosio-mint/30 hover:border-dosio-mint">Debuts</button>
      </div>
    <% end %>

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
                  <.link patch={~p"/stats?#{%{view: "sandwiches", sort_by: "song", sort: if(@sort_by == "song" && @sort == "asc", do: "desc", else: "asc")}}"} class="hover:text-dosio-mint">
                    Song <%= if @sort_by == "song", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "sandwiches", sort_by: "date", sort: if(@sort_by == "date" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Date <%= if @sort_by == "date", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
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
      <% "bustouts" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "bustouts", sort_by: "date", sort: if(@sort_by == "date" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Date <%= if @sort_by == "date", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">
                  <.link patch={~p"/stats?#{%{view: "bustouts", sort_by: "gap_days", sort: if(@sort_by == "gap_days" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Gap (Days) <%= if @sort_by == "gap_days", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for bustout <- @bustouts do %>
                <tr>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{bustout.song_id}"} class="hover:text-dosio-mint">
                      <%= bustout.song_display_name || bustout.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/sets/#{bustout.set_id}"} class="hover:text-dosio-mint">
                      <%= bustout.set_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= bustout.set_date %></td>
                  <td class="p-0 py-4 pr-6 text-right"><%= bustout.gap_days %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "streaks" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">
                  <.link patch={~p"/stats?#{%{view: "streaks", sort_by: "streak_length", sort: if(@sort_by == "streak_length" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Consecutive Shows <%= if @sort_by == "streak_length", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "streaks", sort_by: "date", sort: if(@sort_by == "date" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    From <%= if @sort_by == "date", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal">To</th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for streak <- @streaks do %>
                <tr>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{streak.song_id}"} class="hover:text-dosio-mint">
                      <%= streak.song_display_name || streak.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-right"><%= streak.streak_length %></td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= streak.streak_start %></td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= streak.streak_end %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "openers" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Rank</th>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">Times Opened</th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for {opener, index} <- Enum.with_index(@openers, 1) do %>
                <tr>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= index %></td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{opener.song_id}"} class="hover:text-dosio-mint">
                      <%= opener.song_display_name || opener.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-right"><%= opener.count %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "closers" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Rank</th>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">Times Closed</th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for {closer, index} <- Enum.with_index(@closers, 1) do %>
                <tr>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= index %></td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{closer.song_id}"} class="hover:text-dosio-mint">
                      <%= closer.song_display_name || closer.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-right"><%= closer.count %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "pairings" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Rank</th>
                <th class="p-0 pb-4 pr-6 font-normal">First Song</th>
                <th class="p-0 pb-4 pr-6 font-normal">→</th>
                <th class="p-0 pb-4 pr-6 font-normal">Second Song</th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">Times</th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for {pairing, index} <- Enum.with_index(@pairings, 1) do %>
                <tr>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= index %></td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{pairing.song1_id}"} class="hover:text-dosio-mint">
                      <%= pairing.song1_display_name || pairing.song1_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal">→</td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{pairing.song2_id}"} class="hover:text-dosio-mint">
                      <%= pairing.song2_display_name || pairing.song2_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-right"><%= pairing.count %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "rare_songs" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">Times Played</th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for song <- @rare_songs do %>
                <tr>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{song.song_id}"} class="hover:text-dosio-mint">
                      <%= song.song_display_name || song.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-right"><%= song.play_count %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "longest_sets" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Rank</th>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "longest_sets", sort_by: "date", sort: if(@sort_by == "date" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Date <%= if @sort_by == "date", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">Songs</th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">
                  <.link patch={~p"/stats?#{%{view: "longest_sets", sort_by: "duration", sort: if(@sort_by == "duration" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Duration <%= if @sort_by == "duration", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for {set, index} <- Enum.with_index(@longest_sets, 1) do %>
                <tr>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= index %></td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/sets/#{set.set_id}"} class="hover:text-dosio-mint">
                      <%= set.set_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= set.set_date %></td>
                  <td class="p-0 py-4 pr-6 text-right"><%= set.song_count %></td>
                  <td class="p-0 py-4 pr-6 text-right"><%= format_duration(set.total_duration) %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "triple_sandwiches" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "triple_sandwiches", sort_by: "date", sort: if(@sort_by == "date" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Date <%= if @sort_by == "date", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
                <th class="p-0 pb-4 pr-6 font-normal text-right">
                  <.link patch={~p"/stats?#{%{view: "triple_sandwiches", sort_by: "appearances", sort: if(@sort_by == "appearances" && @sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Appearances <%= if @sort_by == "appearances", do: (if @sort == "asc", do: "↑", else: "↓"), else: "" %>
                  </.link>
                </th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for triple <- @triple_sandwiches do %>
                <tr>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{triple.song_id}"} class="hover:text-dosio-mint">
                      <%= triple.song_display_name || triple.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/sets/#{triple.set_id}"} class="hover:text-dosio-mint">
                      <%= triple.set_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= triple.set_date %></td>
                  <td class="p-0 py-4 pr-6 text-right"><%= triple.appearances %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% "debuts" -> %>
        <div class="overflow-hidden">
          <table class="w-full">
            <thead class="text-sm text-left leading-6 text-dosio-teal border-b border-dosio-mint/20">
              <tr>
                <th class="p-0 pb-4 pr-6 font-normal">Song</th>
                <th class="p-0 pb-4 pr-6 font-normal">Set</th>
                <th class="p-0 pb-4 pr-6 font-normal">
                  <.link patch={~p"/stats?#{%{view: "debuts", sort: if(@sort == "desc", do: "asc", else: "desc")}}"} class="hover:text-dosio-mint">
                    Debut Date <%= if @sort == "asc", do: "↑", else: "↓" %>
                  </.link>
                </th>
              </tr>
            </thead>
            <tbody class="relative divide-y divide-dosio-mint/10 border-t border-dosio-mint/20 text-sm leading-6 text-white">
              <%= for debut <- @debuts do %>
                <tr>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/songs/#{debut.song_id}"} class="hover:text-dosio-mint">
                      <%= debut.song_display_name || debut.song_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6">
                    <.link href={~p"/sets/#{debut.set_id}"} class="hover:text-dosio-mint">
                      <%= debut.set_title %>
                    </.link>
                  </td>
                  <td class="p-0 py-4 pr-6 text-dosio-teal"><%= debut.debut_date %></td>
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
