defmodule MySuperAppWeb.Form do
  use MySuperAppWeb, :surface_live_view
  @moduledoc false
  alias MySuperApp.{User, Accounts}

  alias Moon.Design.Form
  alias Moon.Design.Form.Input
  alias Moon.Design.Form.Field
  alias Moon.Design.Button

  def render(assigns) do
    ~F"""
    <Form for={@form} change="validate" submit="save">
      <Field field={:username}>
        <Input placeholder="Username" />
      </Field>
      <Field field={:email}>
        <Input placeholder="Email" />
      </Field>
      <Button type="submit">Save</Button>
    </Form>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(User.changeset(%User{}, %{})))}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "user #{user_params["username"]} created")
         |> redirect(to: ~p"/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
