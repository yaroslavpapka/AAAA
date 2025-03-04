defmodule MySuperAppWeb.UserLoginLive do
  use MySuperAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto my-8 max-w-md p-6 bg-white shadow-lg rounded-lg">
      <.header class="text-center mb-6">
        <h1 class="text-3xl font-extrabold text-blue-800">Log in to your account</h1>

        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-green-500 hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="login_form"
        action={~p"/users/log_in"}
        phx-update="ignore"
        class="space-y-4"
      >
        <div class="flex flex-col space-y-4">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
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

        <div class="flex items-center justify-between mt-4">
          <.input
            field={@form[:remember_me]}
            type="checkbox"
            label="Keep me logged in"
            class="form-checkbox text-blue-500"
          />
          <.link
            href={~p"/users/reset_password"}
            class="text-sm font-semibold text-blue-500 hover:underline"
          >
            Forgot your password?
          </.link>
        </div>

        <div class="mt-6">
          <.button
            phx-disable-with="Logging in..."
            class="w-full py-2 px-4 bg-blue-600 text-white font-semibold rounded-md hover:bg-blue-700 transition duration-300"
          >
            Log in <span aria-hidden="true">→</span>
          </.button>
        </div>
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
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
