class ChangeStoreOperatingHoursToSimpleTime < ActiveRecord::Migration[7.1]
  def change
    # AM/PM関連カラムを削除
    remove_column :store_operating_hours, :is_am_open, :boolean
    remove_column :store_operating_hours, :is_pm_open, :boolean
    remove_column :store_operating_hours, :am_open_time, :time
    remove_column :store_operating_hours, :am_close_time, :time
    remove_column :store_operating_hours, :pm_open_time, :time
    remove_column :store_operating_hours, :pm_close_time, :time

    # シンプルな営業時間カラムを追加
    add_column :store_operating_hours, :is_closed, :boolean, default: false, null: false
    add_column :store_operating_hours, :open_time, :time
    add_column :store_operating_hours, :close_time, :time
  end
end
