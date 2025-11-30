defmodule BandcampScraperWeb.Plugs.Auth do
  @behaviour Plug
  import Plug.Conn
  import Phoenix.Controller

  alias BandcampScraper.Accounts

  def init(opts), do: opts

  def call(conn, :fetch_current_user), do: fetch_current_user(conn)
  def call(conn, :require_authenticated_user), do: require_authenticated_user(conn)
  def call(conn, :require_admin), do: require_admin(conn)

  defp fetch_current_user(conn) do
    user_id = get_session(conn, :user_id)
    user = user_id && Accounts.get_user!(user_id)
    assign(conn, :current_user, user)
  rescue
    Ecto.NoResultsError ->
      conn
      |> configure_session(drop: true)
      |> assign(:current_user, nil)
  end

  defp require_authenticated_user(conn) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: "/login")
      |> halt()
    end
  end

  defp require_admin(conn) do
    user = conn.assigns[:current_user]

    if user && user.role == "admin" do
      conn
    else
      conn
      |> put_flash(:error, "You don't have permission to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
