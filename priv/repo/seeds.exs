alias MySuperApp.{Repo, Phone, Room, Blog}
alias Faker.Internet

rooms_with_phones = %{
  "301" => ["0991122301", "0993344301"],
  "302" => ["0990000302", "0991111302"],
  "303" => ["0992222303"],
  "304" => ["0993333304", "0994444304"],
  "305" => ["0935555305", "09306666305", "0937777305"]
}

MySuperApp.CasinosAdmins.create_permission(%{name: "superadmin"})
# edit and delete
MySuperApp.CasinosAdmins.create_permission(%{name: "operator"})
# only edit
MySuperApp.CasinosAdmins.create_permission(%{name: "admin-oerator"})
# only read
MySuperApp.CasinosAdmins.create_permission(%{name: "admin "})
MySuperApp.CasinosAdmins.create_permission(%{name: "readonly-admin"})

MySuperApp.CasinosAdmins.create_operator(%{name: "test_operator"})
MySuperApp.CasinosAdmins.create_operator(%{name: "rosr_operator"})
MySuperApp.CasinosAdmins.create_operator(%{name: "Viktor_operator"})

MySuperApp.CasinosAdmins.create_role(%{name: "user ", operator_id: 1})

MySuperApp.CasinosAdmins.create_role(%{name: "super_admin", operator_id: 1, permission_id: 1})

MySuperApp.CasinosAdmins.create_role(%{name: "first operator", operator_id: 1, permission_id: 2})
MySuperApp.CasinosAdmins.create_role(%{name: "second operator", operator_id: 2, permission_id: 2})
MySuperApp.CasinosAdmins.create_role(%{name: "third operator", operator_id: 3, permission_id: 2})

MySuperApp.CasinosAdmins.create_role(%{name: "first admin", operator_id: 1, permission_id: 3})
MySuperApp.CasinosAdmins.create_role(%{name: "second admin ", operator_id: 2, permission_id: 3})
MySuperApp.CasinosAdmins.create_role(%{name: "third_admin", operator_id: 1, permission_id: 3})

MySuperApp.CasinosAdmins.create_role(%{name: "game_admin", operator_id: 1, permission_id: 4})
MySuperApp.CasinosAdmins.create_role(%{name: "sixth_admin", operator_id: 2, permission_id: 4})

MySuperApp.CasinosAdmins.create_role(%{
  name: "adjustment_transacion_access",
  operator_id: 3,
  permission_id: 4
})

MySuperApp.CasinosAdmins.create_role(%{
  name: "user_admin_read_write",
  operator_id: 1,
  permission_id: 5
})

MySuperApp.CasinosAdmins.create_role(%{
  name: "user_admin_adjustment_transaction",
  operator_id: 2,
  permission_id: 5
})

MySuperApp.Accounts.register_user(%{
  email: "admin1111@admin11111",
  username: "admin",
  password: "admin1111@admin1111",
  operator_id: 1,
  role_id: 2
})

for x <- 3..12 do
  email = Internet.email()
  username = Internet.user_name()
  password = "qwe123qwe123"

  MySuperApp.Accounts.register_user(%{
    email: email,
    username: username,
    password: password,
    role_id: x,
    operator_id: 1
  })
end

for x <- 3..12 do
  email = Internet.email()
  username = Internet.user_name()
  password = "qwe123qwe123"

  MySuperApp.Accounts.register_user(%{
    email: email,
    username: username,
    password: password,
    role_id: x,
    operator_id: 2
  })
end

for x <- 3..12 do
  email = Internet.email()
  username = Internet.user_name()
  password = "qwe123qwe123"

  MySuperApp.Accounts.register_user(%{
    email: email,
    username: username,
    password: password,
    role_id: x,
    operator_id: 3
  })
end

for _ <- 1..10 do
  for x <- 1..3 do
    email = Internet.email()
    username = Internet.user_name()
    password = "qwe123qwe123"

    MySuperApp.Accounts.register_user(%{
      email: email,
      username: username,
      password: password,
      role_id: 1,
      operator_id: x
    })
  end
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

{:ok, tag1} = Blog.create_tag(%{name: "Elixir"})
{:ok, tag2} = Blog.create_tag(%{name: "Programming"})

tags = [tag1, tag2]

{:ok, post1} =
  MySuperApp.Blog.create_post(%{
    title: "Первый пост",
    body: "Это содержимое первого поста",
    user_id: 1,
    tags: [tag1]
  })

{:ok, _post2} =
  Blog.create_post(%{
    title: "Второй пост",
    body: "Это содержимое второго поста",
    user_id: 2,
    tags: [tag1, tag2]
  })

Enum.map(1..40, fn x ->
  tag = Enum.random(tags)
  id = Enum.random(1..30)
  Blog.create_post(%{body: "Post #{x}", title: "Title #{x}", user_id: id, tags: [tag]})
end)
