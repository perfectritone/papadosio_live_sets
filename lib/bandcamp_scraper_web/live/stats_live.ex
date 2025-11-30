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
      current_user: current_user
    )}
  rescue
    Ecto.NoResultsError ->
      {:ok, assign(socket,
        page_title: "Stats",
        view: "play_counts",
        play_counts: [],
        durations: [],
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
    </div>

    <%= if @view == "play_counts" do %>
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
    <% else %>
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
    <% end %>
    """
  end
end
