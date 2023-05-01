require "faker"
require "bcrypt"

Faker::Config.random = Random.new(5)

10.times do
  User.create(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: Faker::Internet.email,
    password: Faker::Internet.password,
  )
end

20.times do
  Property.create(
    user_id: Faker::Number.between(from: 1, to: 10),
    title: Faker::Mountain.name,
    address: Faker::Address.full_address,
    description: Faker::ChuckNorris.fact,
    daily_rate: Faker::Number.between(from: 50, to: 150),
  )
end

10.times do
  Booking.create(
    user_id: Faker::Number.between(from: 1, to: 10),
    property_id: Faker::Number.unique.between(from: 1, to: 20),
    start_date: Faker::Date.between(from: "2023-04-01", to: "2023-04-15"),
    end_date: Faker::Date.between(from: "2023-04-16", to: "2023-04-30"),
    approved: Faker::Boolean.boolean(true_ratio: 0.7),
  )
end

@counter = 0

20.times do
  @counter += 1
  Avail.create(
    property_id: @counter,
    first_available: Faker::Date.in_date_period(month: 3),
    last_available: Faker::Date.in_date_period(month: 5),
  )
end
