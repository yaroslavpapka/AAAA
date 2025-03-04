defmodule MySuperApp.RunSeeds do
  @moduledoc false
  alias MySuperApp.{Repo, Phone, Room}
  alias Faker.Internet

  def run_seeds() do
    rooms_with_phones = %{
      "301" => ["0991122301", "0993344301"],
      "302" => ["0990000302", "0991111302"],
      "303" => ["0992222303"],
      "304" => ["0993333304", "0994444304"],
      "305" => ["0935555305", "09306666305", "0937777305"]
    }

    MySuperApp.CasinosAdmins.create_permission(%{name: "superadmin"})
    MySuperApp.CasinosAdmins.create_permission(%{name: "admin"})
    MySuperApp.CasinosAdmins.create_permission(%{name: "readonly-admin"})

    MySuperApp.CasinosAdmins.create_operator(%{name: "test_operator"})
    MySuperApp.CasinosAdmins.create_operator(%{name: "rosr_operator"})
    MySuperApp.CasinosAdmins.create_operator(%{name: "3th-operator"})

    MySuperApp.CasinosAdmins.create_role(%{name: "user ", operator_id: 1})
    MySuperApp.CasinosAdmins.create_role(%{name: "admin ", operator_id: 1, permission_id: 2})

    MySuperApp.CasinosAdmins.create_role(%{
      name: "finance_admin",
      operator_id: 2,
      permission_id: 2
    })

    MySuperApp.CasinosAdmins.create_role(%{name: "super_admin", operator_id: 1, permission_id: 1})
    MySuperApp.CasinosAdmins.create_role(%{name: "user_admin", operator_id: 2, permission_id: 3})
    MySuperApp.CasinosAdmins.create_role(%{name: "game_admin", operator_id: 3, permission_id: 3})
    MySuperApp.CasinosAdmins.create_role(%{name: "sixth_admin", operator_id: 2, permission_id: 3})

    MySuperApp.CasinosAdmins.create_role(%{
      name: "adjustment_transacion_access",
      operator_id: 2,
      permission_id: 3
    })

    MySuperApp.CasinosAdmins.create_role(%{
      name: "user_admin_read_only",
      operator_id: 1,
      permission_id: 3
    })

    MySuperApp.CasinosAdmins.create_role(%{
      name: "user_admin_read_write",
      operator_id: 1,
      permission_id: 2
    })

    MySuperApp.CasinosAdmins.create_role(%{
      name: "user_admin_adjustment_transaction",
      operator_id: 2,
      permission_id: 3
    })

    for _ <- 1..5 do
      email = Internet.email()
      username = Internet.user_name()
      password = "qwe123qwe123"

      MySuperApp.Accounts.register_user(%{
        email: email,
        username: username,
        password: password,
        role_id: 2,
        operator_id: 1
      })
    end

    for _ <- 1..5 do
      email = Internet.email()
      username = Internet.user_name()
      password = "qwe123qwe123"

      MySuperApp.Accounts.register_user(%{
        email: email,
        username: username,
        password: password,
        role_id: 3,
        operator_id: 1
      })
    end

    for _ <- 1..5 do
      email = Internet.email()
      username = Internet.user_name()
      password = "qwe123qwe123"

      MySuperApp.Accounts.register_user(%{
        email: email,
        username: username,
        password: password,
        role_id: 2,
        operator_id: 2
      })
    end

    for _ <- 1..10 do
      email = Internet.email()
      username = Internet.user_name()
      password = "qwe123qwe123"

      MySuperApp.Accounts.register_user(%{
        email: email,
        username: username,
        password: password,
        role_id: 6,
        operator_id: 2
      })
    end

    for _ <- 1..10 do
      email = Internet.email()
      username = Internet.user_name()
      password = "qwe123qwe123"

      MySuperApp.Accounts.register_user(%{
        email: email,
        username: username,
        password: password,
        role_id: 6,
        operator_id: 1
      })
    end

    Repo.transaction(fn ->
      rooms_with_phones
      |> Enum.each(fn {room, phones} ->
        %Room{}
        |> Room.changeset(%{room_number: room})
        |> Ecto.Changeset.put_assoc(
          :phones,
          phones
          |> Enum.map(
            &(%Phone{}
              |> Phone.changeset(%{phone_number: &1}))
          )
        )
        |> Repo.insert!()
      end)

      MySuperApp.Repo.insert_all(
        Room,
        [
          %{room_number: 666},
          %{room_number: 1408},
          %{room_number: 237}
        ]
      )

      MySuperApp.Repo.insert_all(
        Phone,
        [
          %{phone_number: "380661112233"},
          %{phone_number: "380669997788"},
          %{phone_number: "380665554466"}
        ]
      )
    end)

    MySuperApp.Accounts.register_user(%{
      email: "administrator@administrator",
      username: "admin",
      password: "administrator@administrator",
      role: "admin",
      operator_id: 1,
      role_id: 4
    })
  end
end
