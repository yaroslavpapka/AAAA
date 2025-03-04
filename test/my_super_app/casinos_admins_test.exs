defmodule MySuperApp.CasinosAdminsTest do
  alias MySuperApp.Accounts
  use MySuperApp.DataCase
  alias MySuperApp.Accounts.User
  alias MySuperApp.Accounts.UserToken
  alias MySuperApp.Repo
  alias MySuperApp.CasinosAdmins
  alias MySuperApp.Operators
  alias MySuperApp.{Operator, Role, Site}
  import Ecto.Query

  setup do
    {:ok, operator} = CasinosAdmins.create_operator(%{name: "SuperOperator"})
    {:ok, role} = CasinosAdmins.create_role(%{name: "SuperRole", operator_id: operator.id})

    user_attrs = %{
      email: "testuser@example.com",
      username: "testuser",
      password: "supersecretpassword",
      role_id: role.id,
      operator_id: operator.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    %{
      user: user,
      operator: operator,
      role: role,
      email: "testuser2@example.com",
      username: "testuser2",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }
  end

  describe "Operators" do
    test "all_models/0 returns all operators as maps", %{operator: operator} do
      result = CasinosAdmins.all_models()
      assert Enum.any?(result, &(&1.name == operator.name))
    end

    test "get_operator!/1 returns the operator by id", %{operator: operator} do
      assert %Operator{name: "SuperOperator"} = CasinosAdmins.get_operator!(operator.id)
    end

    test "create_operator/1 creates a new operator" do
      attrs = %{name: "NewOperator"}
      {:ok, operator} = CasinosAdmins.create_operator(attrs)
      assert operator.name == "NewOperator"
    end

    test "get_operator/1 returns operator as a map", %{operator: operator} do
      result = CasinosAdmins.get_operator(operator.id)
      assert result.name == operator.name
    end

    test "delete_operator/1 deletes an operator", %{operator: operator} do
      assert {:ok, %Operator{}} = CasinosAdmins.delete_operator(operator.id)
      assert_raise Ecto.NoResultsError, fn -> CasinosAdmins.get_operator!(operator.id) end
    end
  end

  describe "Roles" do
    test "all_roles/0 returns all roles", %{role: role} do
      result = CasinosAdmins.all_roles()
      assert Enum.any?(result, &(&1.name == role.name))
    end

    test "get_role!/1 returns the role by id", %{role: role} do
      assert %Role{name: "SuperRole"} = CasinosAdmins.get_role!(role.id)
    end

    test "get_role_by_name/1 returns the role by name", %{role: role} do
      assert %Role{id: id} = CasinosAdmins.get_role_by_name(role.name)
      assert id == role.id
    end

    test "create_role/1 creates a new role", %{operator: operator} do
      attrs = %{name: "NewRole", operator_id: operator.id}
      {:ok, role} = CasinosAdmins.create_role(attrs)
      assert role.name == "NewRole"
    end

    test "update_role/2 updates an existing role", %{role: role} do
      attrs = %{name: "UpdatedRole"}
      {:ok, role} = CasinosAdmins.update_role(role.id, attrs)
      assert role.name == "UpdatedRole"
    end

    test "delete_role/1 deletes a role", %{role: role} do
      assert {:ok, %Role{}} = CasinosAdmins.delete_role(role)
      assert_raise Ecto.NoResultsError, fn -> CasinosAdmins.get_role!(role.id) end
    end
  end

  describe "Sites" do
    test "all_sites/0 returns all sites", %{operator: operator} do
      {:ok, site} = CasinosAdmins.create_site(%{brand: "TestSite", operator_id: operator.id})
      result = CasinosAdmins.all_sites()
      assert Enum.any?(result, &(&1.brand == site.brand))
    end

    test "get_site!/1 returns the site by id", %{operator: operator} do
      {:ok, site} = CasinosAdmins.create_site(%{brand: "TestSite", operator_id: operator.id})
      assert %Site{brand: "TestSite"} = CasinosAdmins.get_site!(site.id)
    end

    test "create_site/1 creates a new site", %{operator: operator} do
      attrs = %{brand: "NewSite", operator_id: operator.id}
      {:ok, site} = CasinosAdmins.create_site(attrs)
      assert site.brand == "NewSite"
    end

    test "update_site/2 updates an existing site", %{operator: operator} do
      {:ok, site} = CasinosAdmins.create_site(%{brand: "TestSite", operator_id: operator.id})
      attrs = %{brand: "UpdatedSite"}
      {:ok, site} = CasinosAdmins.update_site(site, attrs)
      assert site.brand == "UpdatedSite"
    end

    test "delete_site/1 deletes a site", %{operator: operator} do
      {:ok, site} = CasinosAdmins.create_site(%{brand: "TestSite", operator_id: operator.id})
      assert {:ok, %Site{}} = CasinosAdmins.delete_site(site)
      assert_raise Ecto.NoResultsError, fn -> CasinosAdmins.get_site!(site.id) end
    end
  end

  describe "Permissions" do
    test "create_permission/1 creates a new permission" do
      attrs = %{name: "NewPermission"}
      {:ok, permission} = CasinosAdmins.create_permission(attrs)
      assert permission.name == "NewPermission"
    end

    test "list_permissions/0 returns all permissions" do
      attrs = %{name: "NewPermission"}
      {:ok, _permission} = CasinosAdmins.create_permission(attrs)
      result = CasinosAdmins.list_permissions()
      assert Enum.any?(result, &(&1.name == "NewPermission"))
    end
  end

  describe "Pagination" do
    test "get_roles/4 returns paginated roles", %{role: role} do
      result = CasinosAdmins.get_roles(1, 10, nil, :name, :asc)
      assert Enum.any?(result, &(&1.name == role.name))
    end

    test "count_roles/1 returns the count of roles", %{operator: operator} do
      assert 1 == CasinosAdmins.count_roles(operator.id)
    end
  end

  describe "Permission" do
    test "create_permission/1 creates a new permission" do
      attrs = %{name: "NewPermission"}
      {:ok, permission} = CasinosAdmins.create_permission(attrs)
      assert permission.name == "NewPermission"
    end

    test "list_permissions/0 returns all permissions" do
      attrs = %{name: "NewPermission"}
      {:ok, _permission} = CasinosAdmins.create_permission(attrs)
      result = CasinosAdmins.list_permissions()
      assert Enum.any?(result, &(&1.name == "NewPermission"))
    end
  end

  describe "User Management" do
    test "get_users/5 returns paginated users", %{user: user} do
      result = CasinosAdmins.get_users(1, 10, user.operator_id)
      assert Enum.any?(result, &(&1.email == user.email))
    end

    test "count_users/2 returns the count of users", %{operator: operator} do
      assert 1 == CasinosAdmins.count_users(operator.id)
    end

    test "apply_filters/3 filters users by operator and role", %{user: user} do
      query = User |> CasinosAdmins.apply_filters(user.operator_id, user.role_id)
      assert length(Repo.all(query)) == 1
    end

    test "apply_sorting/3 sorts users by given key", %{user: user} do
      sorted_query = User |> CasinosAdmins.apply_sorting("username", "asc")
      [first_user | _] = Repo.all(sorted_query)
      assert first_user.username == user.username
    end
  end
end
