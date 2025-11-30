defmodule BandcampScraperWeb.RegistrationController do
  use BandcampScraperWeb, :controller

  alias BandcampScraper.Accounts
  alias BandcampScraper.Accounts.User

  def new(conn, _params) do
    changeset = User.changeset(%User{}, %{})
    render(conn, :new, page_title: "Register", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Account created successfully!")
        |> redirect(to: ~p"/")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, page_title: "Register", changeset: changeset)
    end
  end
end
