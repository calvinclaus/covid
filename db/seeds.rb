# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# Admin.all.destroy_all
# Admin.create!(email: "test@example.com", password: "dev123", unlocked: true)

# Company.all.destroy_all
# company = Company.create!(name: "Test Co.")

# User.all.destroy_all
# User.create!(email: "test@example.com", password: "dev123", company: company)
Statistic.create!(at: Time.parse("2020-03-16T15:00"), num_tested: 8409, num_infected: 1016, num_dead: 3, num_recovered: 6)
