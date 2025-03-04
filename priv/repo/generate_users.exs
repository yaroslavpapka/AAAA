alias Faker.Internet

for _ <- 1..50 do
  email = Internet.email()
  username = Internet.user_name()
  MySuperApp.Accounts.create_user(%{email: email, username: username})
end
