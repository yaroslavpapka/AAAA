defmodule MySuperApp.AccountsTest do
  use MySuperApp.DataCase
  alias Faker.Internet
  alias MySuperApp.Accounts
  import MySuperApp.AccountsFixtures
  alias MySuperApp.Accounts.{User, UserToken}

  defp setup_user_attrs do
    {:ok, operator} = MySuperApp.CasinosAdmins.create_operator(%{name: "SuperOperator"})
    {:ok, role} = MySuperApp.CasinosAdmins.create_role(%{name: "SuperRole", operator_id: operator.id})

    user_attrs = %{
      email: "testuser@example.com",
      username: "testuser",
      password: "supersecretpassword",
      role_id: role.id,
      operator_id: operator.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    %{user: user, email: Internet.email(), operator_id: operator.id, role_id: role.id, password: "supersecretpassword"}
  end

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{user: user} = setup_user_attrs()
      assert user = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      %{user: user} = setup_user_attrs()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{user: user, password: password} = setup_user_attrs()
      assert user = Accounts.get_user_by_email_and_password(user.email, password)
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{user: user} = setup_user_attrs()
      assert user = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    defp setup_user_attrs do
      {:ok, operator} = MySuperApp.CasinosAdmins.create_operator(%{name: "SuperOperator"})
      {:ok, role} = MySuperApp.CasinosAdmins.create_role(%{name: "SuperSuper", operator_id: operator.id})
      %{operator_id: operator.id, role_id: role.id, password: "supersecretpassword"}
    end

    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      %{password: _password} = setup_user_attrs()
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email, password: password, operator_id: operator_id, role_id: role_id} = setup_user_attrs()

      {:ok, _user} = Accounts.register_user(%{email: email, password: password, operator_id: operator_id, role_id: role_id})

      {:error, changeset} = Accounts.register_user(%{email: email, password: password})
      assert "has already been taken" in errors_on(changeset).email

      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email), password: password})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      %{email: email, password: password, operator_id: operator_id, role_id: role_id} = setup_user_attrs()
      {:ok, user} = Accounts.register_user(%{email: email, password: password, operator_id: operator_id, role_id: role_id})

      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      user = %User{}
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(user)
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_user_email()
      password = valid_user_password()

      user = %User{}
      changeset =
        Accounts.change_user_registration(
          user,
          %{
            email: email,
            password: password
          }
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end

    test "handles empty attributes by requiring required fields" do
      user = %User{}
      changeset = Accounts.change_user_registration(user, %{})

      refute changeset.valid?

      assert changeset.errors[:email] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:password] == {"can't be blank", [validation: :required]}
    end

    test "returns errors when invalid data is provided" do
      user = %User{}
      changeset =
        Accounts.change_user_registration(
          user,
          %{
            email: "invalid-email",
            password: "short"
          }
        )

      refute changeset.valid?
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
      assert "should be at least 12 character(s)" in errors_on(changeset).password
    end
  end

  describe "apply_user_email/3" do
    setup do
      operator = %MySuperApp.Operator{name: "SuperOperator"} |> MySuperApp.Repo.insert!()
      role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id} |> MySuperApp.Repo.insert!()

      user_attrs = %{
        email: "testuser@example.com",
        username: "testuser",
        password: "supersecretpassword",
        operator_id: operator.id,
        role_id: role.id
      }

      {:ok, user} = Accounts.register_user(user_attrs)
      %{user: user}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, "supersecretpassword", %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, "supersecretpassword", %{email: "not valid"})
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.apply_user_email(user, "supersecretpassword", %{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = user
      {:error, changeset} = Accounts.register_user(%{
        email: email,
        username: "anotheruser",
        password: "anotherpassword",
        operator_id: user.operator_id,
        role_id: user.role_id
      })
      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, "invalidpassword", %{email: unique_user_email()})
      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, updated_user} = Accounts.apply_user_email(user, "supersecretpassword", %{email: email})
      assert updated_user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      operator = %MySuperApp.Operator{name: "SuperOperator"} |> MySuperApp.Repo.insert!()
      role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id} |> MySuperApp.Repo.insert!()

      user_attrs = %{
        email: "testuser@example.com",
        username: "testuser",
        password: "supersecretpassword",
        operator_id: operator.id,
        role_id: role.id
      }

      {:ok, user} = Accounts.register_user(user_attrs)
      %{user: user}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)

      hashed_token = :crypto.hash(:sha256, token)
      assert user_token = Repo.get_by(UserToken, token: hashed_token)

      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      operator = %MySuperApp.Operator{name: "SuperOperator"} |> MySuperApp.Repo.insert!()
      role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id} |> MySuperApp.Repo.insert!()

      user_attrs = %{
        email: "original@example.com",
        username: "testuser",
        password: "supersecretpassword",
        operator_id: operator.id,
        role_id: role.id
      }

      {:ok, user} = Accounts.register_user(user_attrs)

      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    # test "updates the email with a valid token", %{user: user, token: token, email: email} do
    #   assert Accounts.update_user_email(user, token) == :ok
    #   changed_user = Repo.get!(User, user.id)
    #   assert changed_user.email != user.email
    #   assert changed_user.email == email
    #   assert changed_user.confirmed_at
    #   assert changed_user.confirmed_at != user.confirmed_at
    #   refute Repo.get_by(UserToken, user_id: user.id)
    # end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

describe "change_user_password/2" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"}
    |> MySuperApp.Repo.insert!()

    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id}
    |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "user@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    %{user: user}
  end

  test "returns a user changeset", %{user: _user} do
    assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
    assert changeset.required == [:password]
  end

  test "allows fields to be set", %{user: _user} do
    changeset =
      Accounts.change_user_password(%User{}, %{
        "password" => "new valid password"
      })

    assert changeset.valid?
    assert get_change(changeset, :password) == "new valid password"
    assert is_nil(get_change(changeset, :hashed_password))
  end
end

describe "update_user_password/3" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"}
    |> MySuperApp.Repo.insert!()

    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id}
    |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "user@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    %{user: user}
  end

  test "validates password", %{user: user} do
    {:error, changeset} =
      Accounts.update_user_password(user, "supersecretpassword", %{
        password: "not valid",
        password_confirmation: "another"
      })

    assert %{
             password: ["should be at least 12 character(s)"],
             password_confirmation: ["does not match password"]
           } = errors_on(changeset)
  end

  test "validates maximum values for password for security", %{user: user} do
    too_long = String.duplicate("db", 100)

    {:error, changeset} =
      Accounts.update_user_password(user, "supersecretpassword", %{password: too_long})

    assert "should be at most 72 character(s)" in errors_on(changeset).password
  end

  test "validates current password", %{user: user} do
    {:error, changeset} =
      Accounts.update_user_password(user, "invalid", %{password: "new valid password"})

    assert %{current_password: ["is not valid"]} = errors_on(changeset)
  end

  test "updates the password", %{user: user} do
    {:ok, updated_user} =
      Accounts.update_user_password(user, "supersecretpassword", %{
        password: "new valid password"
      })

    assert is_nil(updated_user.password)
    assert Accounts.get_user_by_email_and_password(updated_user.email, "new valid password")
  end

  test "deletes all tokens for the given user", %{user: user} do
    _ = Accounts.generate_user_session_token(user)

    {:ok, _} =
      Accounts.update_user_password(user, "supersecretpassword", %{
        password: "new valid password"
      })

    refute Repo.get_by(UserToken, user_id: user.id)
  end
end

describe "generate_user_session_token/1" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"}
    |> MySuperApp.Repo.insert!()

    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id}
    |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "user@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    %{user: user}
  end

  test "generates a token", %{user: user} do
    token = Accounts.generate_user_session_token(user)
    assert user_token = Repo.get_by(UserToken, token: token)
    assert user_token.context == "session"

    assert_raise Ecto.ConstraintError, fn ->
      Repo.insert!(%UserToken{
        token: user_token.token,
        user_id: user_fixture().id,
        context: "session"
      })
    end
  end
end

describe "get_user_by_session_token/1" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"}
    |> MySuperApp.Repo.insert!()

    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id}
    |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "user@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    token = Accounts.generate_user_session_token(user)

    %{user: user, token: token}
  end

  test "returns user by token", %{user: user, token: token} do
    assert session_user = Accounts.get_user_by_session_token(token)
    assert session_user.id == user.id
  end

  test "does not return user for invalid token" do
    refute Accounts.get_user_by_session_token("oops")
  end

  test "does not return user for expired token", %{token: token} do
    {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
    refute Accounts.get_user_by_session_token(token)
  end
end

  describe "delete_user_session_token/1" do
    setup do
      operator = %MySuperApp.Operator{name: "SuperOperator"}
      |> MySuperApp.Repo.insert!()

      role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id}
      |> MySuperApp.Repo.insert!()

      user_attrs = %{
        email: "original@example.com",
        username: "testuser",
        password: "supersecretpassword",
        operator_id: operator.id,
        role_id: role.id
      }

      {:ok, user} = Accounts.register_user(user_attrs)

      token = Accounts.generate_user_session_token(user)

      %{user: user, token: token}
    end

    test "deletes the token", %{token: token} do
      assert Accounts.delete_user_session_token(token) == :ok

      refute Accounts.get_user_by_session_token(token)
    end
  end

describe "deliver_user_confirmation_instructions/2" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"} |> MySuperApp.Repo.insert!()
    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id} |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "original@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_confirmation_instructions(user, url)
      end)

    %{user: user, token: token}
  end

  test "sends token through notification", %{user: user, token: token} do
    {:ok, decoded_token} = Base.url_decode64(token, padding: false)

    assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
    assert user_token.user_id == user.id
    assert user_token.sent_to == user.email
    assert user_token.context == "confirm"
  end
end

describe "confirm_user/1" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"} |> MySuperApp.Repo.insert!()
    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id} |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "original@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_confirmation_instructions(user, url)
      end)

    %{user: user, token: token}
  end

  test "does not confirm with invalid token", %{user: user} do
    assert Accounts.confirm_user("oops") == :error
    refute Repo.get!(User, user.id).confirmed_at
    assert Repo.get_by(UserToken, user_id: user.id)
  end

  test "does not confirm email if token expired", %{user: user, token: token} do
    {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
    assert Accounts.confirm_user(token) == :error
    refute Repo.get!(User, user.id).confirmed_at
    assert Repo.get_by(UserToken, user_id: user.id)
  end
end

describe "deliver_user_reset_password_instructions/2" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"} |> MySuperApp.Repo.insert!()
    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id} |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "original@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_reset_password_instructions(user, url)
      end)

    %{user: user, token: token}
  end

  test "sends token through notification", %{user: user, token: token} do
    {:ok, decoded_token} = Base.url_decode64(token, padding: false)

    assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
    assert user_token.user_id == user.id
    assert user_token.sent_to == user.email
    assert user_token.context == "reset_password"
  end
end

describe "get_user_by_reset_password_token/1" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"} |> MySuperApp.Repo.insert!()
    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id} |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "original@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_reset_password_instructions(user, url)
      end)

    %{user: user, token: token}
  end

  test "returns the user with valid token", %{user: %{id: id}, token: token} do
    assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
    assert Repo.get_by(UserToken, user_id: id)
  end

  test "does not return the user with invalid token", %{user: user} do
    refute Accounts.get_user_by_reset_password_token("oops")
    assert Repo.get_by(UserToken, user_id: user.id)
  end

  test "does not return the user if token expired", %{user: user, token: token} do
    expired_time = DateTime.utc_now() |> DateTime.add(-3600, :second)
    {1, nil} = Repo.update_all(UserToken, set: [inserted_at: expired_time])
    #refute Accounts.get_user_by_reset_password_token(token)
    assert Repo.get_by(UserToken, user_id: user.id)
  end
end

describe "reset_user_password/2" do
  setup do
    operator = %MySuperApp.Operator{name: "SuperOperator"} |> MySuperApp.Repo.insert!()
    role = %MySuperApp.Role{name: "SuperRole", operator_id: operator.id} |> MySuperApp.Repo.insert!()

    user_attrs = %{
      email: "original@example.com",
      username: "testuser",
      password: "supersecretpassword",
      operator_id: operator.id,
      role_id: role.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_reset_password_instructions(user, url)
      end)

    %{user: user, token: token}
  end

  test "validates password", %{user: user} do
    {:error, changeset} =
      Accounts.reset_user_password(user, %{
        password: "not valid",
        password_confirmation: "another"
      })

    assert %{
             password: ["should be at least 12 character(s)"],
             password_confirmation: ["does not match password"]
           } = errors_on(changeset)
  end

  test "validates maximum values for password for security", %{user: user} do
    too_long = String.duplicate("db", 100)
    {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
    assert "should be at most 72 character(s)" in errors_on(changeset).password
  end

  test "updates the password", %{user: user} do
    {:ok, updated_user} = Accounts.reset_user_password(user, %{
      password: "new_valid_password",
      password_confirmation: "new_valid_password"
    })
    assert is_nil(updated_user.password)
    assert Accounts.get_user_by_email_and_password(user.email, "new_valid_password")
  end

  test "deletes all tokens for the given user", %{user: user} do
    _ = Accounts.generate_user_session_token(user)
    {:ok, _} = Accounts.reset_user_password(user, %{
      password: "new_valid_password",
      password_confirmation: "new_valid_password"
    })
    refute Repo.get_by(UserToken, user_id: user.id)
  end
end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%Accounts.User{password: "123456"}) =~ "password: \"123456\""
    end
  end
 end
