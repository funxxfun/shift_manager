# db/migrate/20250101000001_create_stores.rb
class CreateStores < ActiveRecord::Migration[7.1]
  def change
    create_table :stores do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :address
      t.string :nearest_station

      t.timestamps
    end

    add_index :stores, :code, unique: true
  end
end
