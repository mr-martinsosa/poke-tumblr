class CreateUsersTable < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t| 
      t.string :first_name
      t.string :last_name
      t.string :password
      t.string :email
      t.string :trainer_name
      t.datetime :birthday
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
