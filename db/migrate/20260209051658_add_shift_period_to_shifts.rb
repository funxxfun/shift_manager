class AddShiftPeriodToShifts < ActiveRecord::Migration[7.1]
  def change
    # shift_period: 0=am, 1=pm, 2=full_day（既存データ互換）
    add_column :shifts, :shift_period, :integer, default: 2, null: false

    # 旧ユニーク制約を削除
    remove_index :shifts, [:date, :staff_id]

    # 新ユニーク制約を追加（date, staff_id, shift_period）
    add_index :shifts, [:date, :staff_id, :shift_period], unique: true
  end
end
