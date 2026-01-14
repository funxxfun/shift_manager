# app/models/shift.rb
class Shift < ApplicationRecord
  belongs_to :staff
  belongs_to :store

  enum status: { scheduled: 0, confirmed: 1, support: 2 }

  validates :date, presence: true
  validates :staff_id, uniqueness: { scope: :date, message: 'は同日に複数シフトを持てません' }

  scope :on_date, ->(date) { where(date: date) }
  scope :for_store, ->(store) { where(store: store) }
  scope :pharmacists, -> { joins(:staff).where(staffs: { role: :pharmacist }) }
  scope :clerks, -> { joins(:staff).where(staffs: { role: :clerk }) }

  def working_hours
    return 0 unless start_time && end_time
    
    hours = (end_time - start_time) / 1.hour
    hours - (break_minutes / 60.0)
  end

  def support?
    status == 'support' || store_id != staff.base_store_id
  end
end
