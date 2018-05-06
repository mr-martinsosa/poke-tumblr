class CreatePokemonTable < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.string :name
      t.string :sprite
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :user_id
    end
  end
end
