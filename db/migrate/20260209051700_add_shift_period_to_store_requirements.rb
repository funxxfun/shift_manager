class AddShiftPeriodToStoreRequirements < ActiveRecord::Migration[7.1]
  def change
    # shift_period: 0=am, 1=pm, 2=full_day（既存データ互換）
    add_column :store_requirements, :shift_period, :integer, default: 2, null: false

    # 旧ユニーク制約を削除
    remove_index :store_requirements, [:store_id, :day_type]

    # 新ユニーク制約を追加（store_id, day_type, shift_period）
    add_index :store_requirements, [:store_id, :day_type, :shift_period], unique: true
  end
end
