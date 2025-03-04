defmodule MySuperApp.UserTest do
  alias MySuperApp.Accounts
  use MySuperApp.DataCase
  alias MySuperApp.Accounts.User
  alias MySuperApp.Accounts.UserToken
  alias MySuperApp.Repo
  alias MySuperApp.CasinosAdmins
  alias MySuperApp.Operators

  alias MySuperApp.User

  defp setup_user_attrs do
    {:ok, operator} = MySuperApp.CasinosAdmins.create_operator(%{name: "SuperOperator"})
    {:ok, role} = MySuperApp.CasinosAdmins.create_role(%{name: "SuperSuper", operator_id: operator.id})
    %{operator_id: operator.id, role_id: role.id, password: "supersecretpassword"}
  end

  test "create_user/1 with valid data" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    valid_attrs = %{username: "Carl", email: "Carl_pikovic@gmail.com", password: password, operator_id: operator_id, role_id: role_id}

    assert {:ok, %MySuperApp.Accounts.User{} = user} = Accounts.register_user(valid_attrs)
    assert user.username == "Carl"
    assert user.email == "Carl_pikovic@gmail.com"
    assert user.hashed_password != nil
  end

  test "create_user/1 with invalid data" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    invalid_attrs = %{username: "hd", email: "gmail.com", password: password, operator_id: operator_id, role_id: role_id}

    assert {:error, _} = Accounts.create_user(invalid_attrs)
  end

  test "create_user/1 with wrong data" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    valid_attrs = %{username: "Georg", email: "Niranafad@gmail.com", password: password, operator_id: operator_id, role_id: role_id}

    assert {:ok, %MySuperApp.Accounts.User{} = user} = Accounts.register_user(valid_attrs)
    refute user.username == "Aserere"
    refute user.email == "Maunkovb@gmail.com"
  end

  test "change_user/2 test" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    valid_attrs = %{username: "Birn", email: "Nikaragua@gmail.com", password: password, operator_id: operator_id, role_id: role_id}

    assert {:ok, user} = Accounts.register_user(valid_attrs)

    assert {:ok, user} = Accounts.change_user(user.id, %{username: "Georg", email: "Niranafad@gmail.com"})

    assert user.username == "Georg"
    assert user.email == "Niranafad@gmail.com"
  end

  test "delete_user/1 test" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    valid_attrs = %{username: "Birn", email: "Nikaragua@gmail.com", password: password, operator_id: operator_id, role_id: role_id}

    assert {:ok, %MySuperApp.Accounts.User{} = user} = Accounts.register_user(valid_attrs)
    assert {:ok, _} = Accounts.delete_user(user)
  end

  test "get_all_users/0 returns all users" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    valid_attrs = %{username: "Carl", email: "Carl_pikovic@gmail.com", password: password, operator_id: operator_id, role_id: role_id}
    {:ok, _user} = Accounts.register_user(valid_attrs)

    users = Accounts.get_all_users()
    assert length(users) > 0
    assert Enum.any?(users, &(&1.username == "Carl"))
  end

  test "update_user_role/2 updates the user's role" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()

    new_role_attrs = %{name: "NewRole"}
    {:ok, new_role} = MySuperApp.CasinosAdmins.create_role(new_role_attrs)
    new_role_id = new_role.id

    valid_attrs = %{username: "Carl", email: "Carl_pikovic@gmail.com", password: password, operator_id: operator_id, role_id: role_id}
    {:ok, user} = Accounts.register_user(valid_attrs)

    assert {:ok, %Accounts.User{} = updated_user} = Accounts.update_user_role(user, new_role_id)
    assert updated_user.role_id == new_role_id
  end

  test "get_user_by_email/1 returns the user with the given email" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    valid_attrs = %{username: "Carl", email: "Carl_pikovic@gmail.com", password: password, operator_id: operator_id, role_id: role_id}
    {:ok, _user} = Accounts.register_user(valid_attrs)

    user = Accounts.get_user_by_email("Carl_pikovic@gmail.com")
    assert user != nil
    assert user.email == "Carl_pikovic@gmail.com"
  end

  test "get_user_by_email_and_password/2 returns the user with the correct email and password" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    valid_attrs = %{username: "Carl", email: "Carl_pikovic@gmail.com", password: password, operator_id: operator_id, role_id: role_id}
    {:ok, _user} = Accounts.register_user(valid_attrs)

    user = Accounts.get_user_by_email_and_password("Carl_pikovic@gmail.com", password)
    assert user != nil
    assert user.email == "Carl_pikovic@gmail.com"
  end

  test "change_user_registration/2 returns a changeset for changing the user registration" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    valid_attrs = %{username: "Carl", email: "Carl_pikovic@gmail.com", password: password, operator_id: operator_id, role_id: role_id}
    {:ok, user} = Accounts.register_user(valid_attrs)

    changeset = Accounts.change_user_registration(user, %{username: "NewName"})
    assert changeset.changes[:username] == "NewName"
  end

  test "update_user_password/3 updates the user password" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    new_password = "newsecretpassword"
    valid_attrs = %{username: "Carl", email: "Carl_pikovic@gmail.com", password: password, operator_id: operator_id, role_id: role_id}
    {:ok, user} = Accounts.register_user(valid_attrs)

    assert {:ok, %Accounts.User{} = updated_user} = Accounts.update_user_password(user, password, %{password: new_password})
  end

  test "reset_user_password/2 resets the user password" do
    %{operator_id: operator_id, role_id: role_id, password: password} = setup_user_attrs()
    new_password = "newpassword1111"
    valid_attrs = %{username: "Carl", email: "Carl_pikovic@gmail.com", password: password, operator_id: operator_id, role_id: role_id}
    {:ok, user} = Accounts.register_user(valid_attrs)

    assert {:ok, %Accounts.User{} = updated_user} = Accounts.reset_user_password(user, %{password: new_password, password_confirmation: new_password})
  end

  describe "registration_changeset/3" do
    test "with valid attributes" do
      attrs = %{email: "newuser@example.com", username: "newuser", password: "newpassword123456", role_id: 2, operator_id: 2}
      changeset = Accounts.User.registration_changeset(%Accounts.User{}, attrs)

      assert changeset.valid?
      assert changeset.changes.email == "newuser@example.com"
      assert changeset.changes.username == "newuser"
    end

    test "with invalid email" do
      attrs = %{email: "invalidemail", password: "password123456"}
      changeset = Accounts.User.registration_changeset(%Accounts.User{}, attrs)

      refute changeset.valid?
      assert %{password: ["should be at least 12 character(s)"]}
    end

    test "with short password" do
      attrs = %{email: "valid@example.com", password: "short", role_id: 1, operator_id: 1}
      changeset = Accounts.User.registration_changeset(%Accounts.User{}, attrs)

      refute changeset.valid?
      assert %{password: ["should be at least 12 character(s)"]}
    end
  end

describe "generate_user_session_token/1" do
    test "generates a session token for a user" do
      {:ok, operator} = CasinosAdmins.create_operator(%{name: "TestOperator"})
      {:ok, role} = CasinosAdmins.create_role(%{name: "TestRole", operator_id: operator.id})

  user_attrs = %{
    email: "test@example.com",
    username: "testuser",
    password: "password123456",
    role_id: role.id,
    operator_id: operator.id
  }
  {:ok, user} = Accounts.register_user(user_attrs)

  token = Accounts.generate_user_session_token(user)

  assert is_binary(token)
  assert token != ""

  query = from ut in UserToken, where: ut.token == ^token
  user_token = Repo.one(query)

  assert user_token
  assert user_token.user_id == user.id
end

test "fails if user is invalid" do
  invalid_user = %User{id: -1}

  assert_raise Ecto.ConstraintError, fn ->
    Accounts.generate_user_session_token(invalid_user)
  end
 end
end

end
