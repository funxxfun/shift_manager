# db/migrate/20250101000003_create_staffs.rb
class CreateStaffs < ActiveRecord::Migration[7.1]
  def change
    create_table :staffs do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.integer :role, null: false, default: 0  # 0: 薬剤師, 1: 事務
      t.references :base_store, foreign_key: { to_table: :stores }
      t.string :nearest_station

      t.timestamps
    end

    add_index :staffs, :code, unique: true
  end
end
