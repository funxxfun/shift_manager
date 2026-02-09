class CreateSupportRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :support_requests do |t|
      t.references :shift, null: false, foreign_key: true
      t.references :requesting_store, null: false, foreign_key: { to_table: :stores }
      t.references :requested_by, null: false, foreign_key: { to_table: :staffs }
      t.references :responded_by, foreign_key: { to_table: :staffs }
      t.integer :status, default: 0, null: false
      t.text :reason
      t.text :response_note
      t.datetime :responded_at

      t.timestamps
    end

    add_index :support_requests, [:shift_id, :requesting_store_id],
              unique: true,
              where: "status = 0",
              name: 'idx_pending_support_requests'
  end
end
