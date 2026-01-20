class AddPermissionLevelToStaffs < ActiveRecord::Migration[7.1]
  def change
    add_column :staffs, :permission_level, :integer, default: 0, null: false
  end
end
