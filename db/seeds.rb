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
Statistic.all.delete_all
Statistic.create!(at: Time.parse("2020-02-25T14:00"), num_tested: 218, num_infected: 2, num_dead: 0, num_recovered: 0)
Statistic.create!(at: Time.parse("2020-02-26T14:00"), num_tested: 321, num_infected: 2, num_dead: 0, num_recovered: 0)
Statistic.create!(at: Time.parse("2020-02-27T14:00"), num_tested: 447, num_infected: 3, num_dead: 0, num_recovered: 0)
Statistic.create!(at: Time.parse("28.2.2020T14:00"), num_tested:	763, num_infected:	6, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("29.2.2020T14:00"), num_tested:	1649, num_infected:	9, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("1.3.2020T14:00"), num_tested:	1826, num_infected:	10, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("2.3.2020T14:00"), num_tested:	2120, num_infected:	10, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("3.3.2020T14:00"), num_tested:	2683, num_infected:	24, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("4.3.2020T14:00"), num_tested:	3138, num_infected:	27, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("5.3.2020T14:00"), num_tested:	3711, num_infected:	41, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("6.3.2020T14:00"), num_tested:	4000, num_infected:	55, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("7.3.2020T14:00"), num_tested:	4308, num_infected:	79, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("8.3.2020T14:00"), num_tested:	4509, num_infected:	99, num_dead:	0, num_recovered:	0)
Statistic.create!(at: Time.parse("9.3.2020T14:00"), num_tested:	4743, num_infected:	131, num_recovered:	2, num_dead:	0)
Statistic.create!(at: Time.parse("10.3.2020t14:00"), num_tested:	5026, num_infected:	182, num_recovered:	4, num_dead:	0)
Statistic.create!(at: Time.parse("11.3.2020T14:00"), num_tested:	5362, num_infected:	246, num_recovered:	4, num_dead:	0)
Statistic.create!(at: Time.parse("12.3.2020T14:00"), num_tested:	5869, num_infected:	361, num_recovered:	4, num_dead:	1)
Statistic.create!(at: Time.parse("13.3.2020T14:00"), num_tested:	6582, num_infected:	504, num_recovered:	6, num_dead:	1)
Statistic.create!(at: Time.parse("14.3.2020T14:00"), num_tested:	7467, num_infected:	655, num_recovered:	6, num_dead:	1)
Statistic.create!(at: Time.parse("15.3.2020T14:00"), num_tested:	8167, num_infected:	860, num_recovered:	6, num_dead:	1)
Statistic.create!(at: Time.parse("16.3.2020T14:00"), num_tested:	8490, num_infected:	1016, num_recovered:	6, num_dead:	3)
Statistic.create!(at: Time.parse("17.3.2020T14:00"), num_tested:	10278, num_infected:	1332, num_recovered:	9, num_dead:	3)




