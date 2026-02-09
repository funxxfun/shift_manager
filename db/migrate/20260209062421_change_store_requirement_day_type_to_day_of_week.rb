class ChangeStoreRequirementDayTypeToDayOfWeek < ActiveRecord::Migration[7.1]
  def change
    # 既存データを全削除（Seedで再作成する）
    execute "TRUNCATE store_requirements"

    # 既存のインデックスを削除
    remove_index :store_requirements, name: 'idx_on_store_id_day_type_shift_period_0c4830b254'

    # day_typeカラムを削除してday_of_weekを追加
    remove_column :store_requirements, :day_type, :integer

    # day_of_week（0=日曜〜6=土曜）を追加
    add_column :store_requirements, :day_of_week, :integer, null: false

    # shift_periodをam/pmのみに（full_dayは削除）
    change_column_default :store_requirements, :shift_period, from: 2, to: 0

    # 新しいユニークインデックス
    add_index :store_requirements, [:store_id, :day_of_week, :shift_period], unique: true, name: 'idx_store_requirements_unique'
  end
end
