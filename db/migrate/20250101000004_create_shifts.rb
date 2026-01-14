# db/migrate/20250101000004_create_shifts.rb
class CreateShifts < ActiveRecord::Migration[7.1]
  def change
    create_table :shifts do |t|
      t.date :date, null: false
      t.references :staff, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.time :start_time
      t.time :end_time
      t.integer :break_minutes, default: 60
      t.integer :status, default: 0  # 0: 予定, 1: 確定, 2: 応援

      t.timestamps
    end

    add_index :shifts, [:date, :staff_id], unique: true
    add_index :shifts, [:date, :store_id]
  end
end
