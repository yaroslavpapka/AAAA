defmodule MySuperAppWeb.UserRegistrationLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.Accounts
  alias MySuperApp.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto my-8 max-w-md p-6 bg-white shadow-lg rounded-lg">
      <.header class="text-center mb-6">
        <h1 class="text-3xl font-extrabold text-blue-800">Register for an account</h1>

        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-green-500 hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
        class="space-y-4"
      >
        <.error :if={@check_errors} class="text-red-600">
          Oops, something went wrong! Please check the errors below.
        </.error>

        <div class="flex flex-col space-y-4">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            required
            class="p-3 border border-gray-300 rounded-md shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
          />
          <.input
            field={@form[:username]}
            type="text"
            label="Username"
            required
            class="p-3 border border-gray-300 rounded-md shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            required
            class="p-3 border border-gray-300 rounded-md shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
          />
        </div>

        <:actions class="mt-6">
          <.button
            phx-disable-with="Creating account..."
            class="w-full py-2 px-4 bg-blue-600 text-white font-semibold rounded-md hover:bg-blue-700 transition duration-300"
          >
            Create an account
          </.button>
        </:actions>
      </.simple_form>

      <div class="mt-6 text-center">
        <span class="text-gray-600">or</span>
        <a
          href={~p"/auth/google"}
          class="inline-block mt-2 py-2 px-4 bg-gray-200 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-300 transition duration-300"
        >
          <img
            src="https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg"
            alt="Google"
            class="inline w-5 h-5 mr-2"
          /> Log in with Google
        </a>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
