class CreateStatistics < ActiveRecord::Migration[5.2]
  def change
    create_table :statistics do |t|
      t.timestamp :at
      t.integer :num_tested, default: 0
      t.integer :num_infected, default: 0
      t.integer :num_recovered, default: 0
      t.integer :num_dead, default: 0
      t.timestamps
    end
  end
end
