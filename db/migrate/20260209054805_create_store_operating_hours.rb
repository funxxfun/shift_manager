class CreateStoreOperatingHours < ActiveRecord::Migration[7.1]
  def change
    create_table :store_operating_hours do |t|
      t.references :store, null: false, foreign_key: true
      t.integer :day_of_week, null: false  # 0=日, 1=月, ..., 6=土
      t.boolean :is_am_open, default: true, null: false
      t.boolean :is_pm_open, default: true, null: false
      t.time :am_open_time
      t.time :am_close_time
      t.time :pm_open_time
      t.time :pm_close_time

      t.timestamps
    end

    add_index :store_operating_hours, [:store_id, :day_of_week], unique: true
  end
end
