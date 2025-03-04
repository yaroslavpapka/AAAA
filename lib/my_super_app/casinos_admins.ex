defmodule MySuperApp.CasinosAdmins do
  @moduledoc false
  alias MySuperApp.Repo
  alias MySuperApp.Operator
  alias MySuperApp.Role
  alias MySuperApp.Site
  alias MySuperApp.Permission
  import Ecto.Query
  alias MySuperApp.{Accounts.User, Role}

  def all_models() do
    Operator
    |> Repo.all()
    |> Enum.map(&(&1 |> Map.from_struct()))
  end

  def get_operator!(id), do: Repo.get!(Operator, id)

  def create_operator(attrs \\ %{}) do
    %Operator{}
    |> Operator.changeset(attrs)
    |> Repo.insert()
  end

  def get_operator(id) do
    Operator
    |> Repo.get(id)
    |> Map.from_struct()
  end

  def delete_operator(id) do
    Operator
    |> Repo.get(id)
    |> Repo.delete()
  end

  def all_roles do
    Repo.all(Role)
  end

  def get_role!(id), do: Repo.get!(Role, id)

  def get_role_by_name(name), do: Repo.get_by(Role, name: name)

  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  def update_role(id, attrs) do
    Repo.get(Role, id)
    |> Role.changeset(attrs)
    |> Repo.update()
  end

  def delete_role(%Role{} = role) do
    Repo.delete(role)
  end

  def change_role(role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end

  def all_sites do
    Repo.all(Site)
  end

  def get_site!(id), do: Repo.get!(Site, id)

  def create_site(attrs \\ %{}) do
    %Site{}
    |> Site.changeset(attrs)
    |> Repo.insert()
  end

  def update_site(%Site{} = site, attrs) do
    site
    |> Site.changeset(attrs)
    |> Repo.update()
  end

  def get_operator_with_associations(operator_id) do
    Repo.get!(Operator, operator_id)
    |> Repo.preload([:users, :sites])
  end

  def delete_site(%Site{} = site) do
    Repo.delete(site)
  end

  def change_site(%Site{} = site, attrs \\ %{}) do
    Site.changeset(site, attrs)
  end

  def get_operator_name(id) do
    Repo.get(Operator, id) |> Map.get(:name)
  end

  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  def list_permissions do
    Repo.all(Permission)
  end


  def get_roles(page, per_page \\ 10, operator_id \\ nil, sort_key \\ :updated_at, sort_dir \\ :desc) do
    query =
      from r in Role,
        limit: ^per_page,
        offset: ^((page - 1) * per_page),
        order_by: [{^sort_dir, field(r, ^sort_key)}],
        preload: [:operator]

    query =
      if operator_id do
        from r in query, where: r.operator_id == ^operator_id
      else
        query
      end

    Repo.all(query) |> Enum.map(&(&1 |> Map.from_struct()))
  end

  def count_roles(operator_id) do
    query =
      from r in Role,
        select: count(r.id)

    query =
      if operator_id do
        from r in query, where: r.operator_id == ^operator_id
      else
        query
      end

    Repo.one(query)
  end

  def get_sites(page, per_page, operator_id) do
    offset = (page - 1) * per_page

    query =
      from s in Site,
        where: s.operator_id == ^operator_id,
        limit: ^per_page,
        offset: ^offset

    Repo.all(query)
    |> Enum.map(&Map.from_struct/1)
    |> Enum.reverse()
  end

  def count_sites(operator_id) do
    query =
      from s in Site,
        where: s.operator_id == ^operator_id,
        select: count(s.id)

    Repo.one(query)
  end

  def get_users(
        page,
        per_page,
        operator_id \\ nil,
        role_id \\ nil,
        sort_key \\ nil,
        sort_dir \\ "asc"
      ) do
    offset = (page - 1) * per_page

    query =
      User
      |> apply_filters(operator_id, role_id)
      |> apply_sorting(sort_key, sort_dir)
      |> limit(^per_page)
      |> offset(^offset)

    Repo.all(query)
    |> Enum.map(&Map.from_struct/1)
  end

  def count_users(operator_id \\ nil, role_id \\ nil) do
    User
    |> apply_filters(operator_id, role_id)
    |> select([u], count(u.id))
    |> Repo.one()
  end

  def apply_filters(query, operator_id, role_id) do
    query
    |> maybe_filter(:operator_id, operator_id)
    |> maybe_filter(:role_id, role_id)
  end

  def apply_sorting(query, nil, _), do: query

  def apply_sorting(query, sort_key, sort_dir) do
    sort_field = String.to_existing_atom(sort_key)
    sort_direction = String.to_existing_atom(sort_dir)

    from(u in query, order_by: [{^sort_direction, field(u, ^sort_field)}])
  end

  def maybe_filter(query, _field, nil), do: query

  def maybe_filter(query, field, value) do
    from(u in query, where: field(u, ^field) == ^value)
  end

  def maybe_filter_by_operator(query, nil), do: query

  def maybe_filter_by_operator(query, operator_id),
    do: from(u in query, where: u.operator_id == ^operator_id)

  def maybe_filter_by_role(query, nil), do: query
  def maybe_filter_by_role(query, role_id), do: from(u in query, where: u.role_id == ^role_id)

  def disable_edit_button?(current_user, user) do
    permission = get_role!(current_user.role_id)
    user_permission = get_role!(user.role_id)

    case current_user.role.permission.name do
      "superadmin" -> # superadmin can edit anyone except himself
        current_user.id == user.id

      "operator" -> # operators can edit only users within their own operator, except superadmin
        current_user.operator_id != user.operator_id or
          user_permission.permission_id <= permission.permission_id

      "admin-oerator" -> # admin-operator cannot edit themselves or higher roles
        current_user.operator_id != user.operator_id or
          user_permission.permission_id <= permission.permission_id

      "admin " -> # admin can only edit users within their own operator and cannot edit higher roles or same role
        current_user.operator_id != user.operator_id or
          user_permission.permission_id <= permission.permission_id

      "readonly-admin" -> # readonly-admin cannot edit anyone
        true

      _ -> # default case, if permission_id doesn't match any known value
        true
    end
  end

  def disable_delete_button?(current_user, user) do
    permission = get_role!(current_user.role_id)
    user_permission = get_role!(user.role_id)

    case current_user.role.permission.name do
      "superadmin" -> # superadmin can delete anyone except himself
        current_user.id == user.id

      "operator" ->
        current_user.operator_id != user.operator_id or
          user_permission.permission_id <= permission.permission_id

      "admin-oerator" ->  # admin-operator cannot delete themselves or higher roles
        current_user.id == user.id or user.role_id < current_user.role_id or
          user_permission.permission_id <= permission.permission_id

      _ -> # default case, if permission_id doesn't match any known value
        true
    end
  end

  def filter_users(filter, operator_id, role_id, limit, offset) do
    query =
      User
      |> where([u], ilike(u.username, ^"%#{filter}%"))
      |> maybe_filter_by_operator(operator_id)
      |> maybe_filter_by_role(role_id)

    users =
      query
      |> limit(^limit)
      |> offset(^offset)
      |> Repo.all()
      |> Enum.map(&Map.from_struct/1)

    total_users = Repo.aggregate(query, :count, :id)
    total_pages = ceil(total_users / limit)

    {users, total_users, total_pages}
  end
end
