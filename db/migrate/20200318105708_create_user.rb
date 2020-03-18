class CreateUser < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email
      t.boolean :subscribed, default: true
      t.timestamps
    end
  end
end
