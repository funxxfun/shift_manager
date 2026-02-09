# app/models/shift.rb
class Shift < ApplicationRecord
  belongs_to :staff
  belongs_to :store
  has_many :support_requests, dependent: :destroy

  enum :status, { scheduled: 0, confirmed: 1, support: 2 }
  enum :shift_period, { am: 0, pm: 1, full_day: 2 }

  validates :date, presence: true
  validates :staff_id, uniqueness: {
    scope: [:date, :shift_period],
    message: 'は同日同時間帯に複数シフトを持てません'
  }
  validate :no_overlap_with_full_day

  scope :on_date, ->(date) { where(date: date) }
  scope :for_store, ->(store) { where(store: store) }
  scope :for_period, ->(period) { where(shift_period: period) }
  scope :am_shifts, -> { where(shift_period: [:am, :full_day]) }
  scope :pm_shifts, -> { where(shift_period: [:pm, :full_day]) }
  scope :pharmacists, -> { joins(:staff).where(staffs: { role: :pharmacist }) }
  scope :clerks, -> { joins(:staff).where(staffs: { role: :clerk }) }

  # 時間帯を自動判定（12:00境界）
  def self.determine_period(start_time, end_time)
    return :full_day unless start_time && end_time

    noon = Time.zone.parse('12:00')
    start_hour = start_time.is_a?(String) ? Time.zone.parse(start_time) : start_time
    end_hour = end_time.is_a?(String) ? Time.zone.parse(end_time) : end_time

    if end_hour <= noon
      :am
    elsif start_hour >= noon
      :pm
    else
      :full_day
    end
  end

  def shift_period_label
    case shift_period
    when 'am' then 'AM'
    when 'pm' then 'PM'
    when 'full_day' then '終日'
    end
  end

  def working_hours
    return 0 unless start_time && end_time

    hours = (end_time - start_time) / 1.hour
    hours - (break_minutes / 60.0)
  end

  def support?
    status == 'support' || store_id != staff.base_store_id
  end

  private

  def no_overlap_with_full_day
    return unless date && staff_id

    existing_shifts = staff.shifts.where(date: date).where.not(id: id)

    if full_day?
      if existing_shifts.exists?
        errors.add(:shift_period, '終日シフトは他の時間帯シフトと共存できません')
      end
    else
      if existing_shifts.where(shift_period: :full_day).exists?
        errors.add(:shift_period, '終日シフトがある日に時間帯シフトは作成できません')
      end
    end
  end
end
