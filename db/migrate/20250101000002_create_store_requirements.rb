# db/migrate/20250101000002_create_store_requirements.rb
class CreateStoreRequirements < ActiveRecord::Migration[7.1]
  def change
    create_table :store_requirements do |t|
      t.references :store, null: false, foreign_key: true
      t.integer :day_type, null: false, default: 0  # 0: 平日, 1: 土曜, 2: 日祝
      t.integer :pharmacist_count, null: false, default: 0
      t.integer :clerk_count, null: false, default: 0

      t.timestamps
    end

    add_index :store_requirements, [:store_id, :day_type], unique: true
  end
end
