defmodule MySuperAppWeb.EditUser do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view
  alias Moon.Design.Form
  alias Moon.Design.Form.Input
  alias Moon.Design.Form.Field
  alias Moon.Design.Button

  alias MySuperApp.{User, Repo}
  prop(selected, :list)
  data(users, :any)

  def mount(%{"id" => user_id}, _session, socket) do
    {
      :ok,
      assign(
        socket,
        id: user_id,
        user:
          Repo.get(User, user_id)
          |> Map.from_struct(),
        form: to_form(User.changeset(%User{}, %{}))
      )
    }
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("edit", %{"user" => params}, socket) do
    user_id = socket.assigns.id

    case Repo.get(User, user_id) do
      nil ->
        {:noreply, socket}

      user ->
        changeset = User.changeset(user, params)

        case Repo.update(changeset) do
          {:ok, _updated_user} ->
            {:noreply,
             socket
             |> put_flash(:info, "Edided users")
             |> redirect(to: ~p"/users")}

          {:error, changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end
    end
  end

  def render(assigns) do
    ~F"""
    <Form for={@form} change="validate" submit="edit">
      <Field field={:username}>
        <Input placeholder="Username" field={:username} value={@user.username} />
      </Field>
      <Field field={:email}>
        <Input placeholder="Email" field={:email} value={@user.email} />
      </Field>
      <Button type="submit">Save</Button>
    </Form>
    """
  end
end
