defmodule MySuperAppWeb.AuthController do
  use MySuperAppWeb, :controller
  import Plug.Conn
  alias MySuperApp.Accounts
  alias Jason

  @google_client_id System.get_env("GOOGLE_CLIENT_ID") 
  @google_client_secret System.get_env("GOOGLE_CLIENT_SECRET")
  @redirect_uri System.get_env("GOOGLE_REDIRECT_URI")
  @google_token_url System.get_env("GOOGLE_TOKEN_URL") 

  def redirect_to_google(conn, _params) do
    url =
      "https://accounts.google.com/o/oauth2/auth?" <>
        "client_id=#{@google_client_id}&" <>
        "redirect_uri=#{URI.encode(@redirect_uri)}&" <>
        "response_type=code&" <>
        "scope=email profile"

    redirect(conn, external: url)
  end

  def callback(conn, %{"code" => code}) do
    body = %{
      code: code,
      client_id: @google_client_id,
      client_secret: @google_client_secret,
      redirect_uri: @redirect_uri,
      grant_type: "authorization_code"
    }

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(@google_token_url, URI.encode_query(body), headers) do
      {:ok, %HTTPoison.Response{body: response_body}} ->
        %{"access_token" => access_token} = Jason.decode!(response_body)

        user_info_url =
          "https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{access_token}"

        case HTTPoison.get(user_info_url) do
          {:ok, %HTTPoison.Response{body: user_info_body}} ->

            %{"email" => email} = Jason.decode!(user_info_body)
            %{"name" => name} = Jason.decode!(user_info_body)
            %{"id" => id} = Jason.decode!(user_info_body)

            case Accounts.get_user_by_email(email) do
              nil ->
                case Accounts.register_user(%{email: email, username: name, password: id}) do
                  {:ok, user} ->
                    conn
                    |> MySuperAppWeb.UserAuth.log_in_user(user, %{email: email, password: id})
                    |> put_flash(:info, "Successfully registered and authenticated with Google!")
                    |> redirect(to: "/users")

                  {:error, _} ->
                    conn
                    |> put_flash(:error, "Failed to register user")
                    |> redirect(to: "/")
                end

              user ->
                conn
                |> MySuperAppWeb.UserAuth.log_in_user(user, %{email: email, password: id})
                |> put_flash(:info, "Successfully authenticated with Google!")
                |> redirect(to: "/users")
            end

          {:error, _reason} ->

            conn
            |> put_flash(:error, "Failed to get user profile from Google")
            |> redirect(to: "/")
        end

      {:error, _reason} ->

        conn
        |> put_flash(:error, "Failed to authenticate with Google")
        |> redirect(to: "/")
    end
  end
end
