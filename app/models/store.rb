# app/models/store.rb
class Store < ApplicationRecord
  has_many :store_requirements, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :staffs, foreign_key: :base_store_id

  accepts_nested_attributes_for :store_requirements, allow_destroy: true

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  # 指定日・時間帯の必要人数を取得
  def requirement_for(date, shift_period = nil)
    day_type = self.class.day_type_for(date)

    if shift_period
      store_requirements.find_by(day_type: day_type, shift_period: shift_period)
    else
      store_requirements.find_by(day_type: day_type)
    end
  end

  # 指定日・時間帯のシフトを取得
  def shifts_on(date, shift_period = nil)
    base = shifts.where(date: date)

    return base unless shift_period

    case shift_period.to_sym
    when :am
      base.am_shifts
    when :pm
      base.pm_shifts
    else
      base
    end
  end

  # 指定日・時間帯の過不足を算出
  def shortage_on(date, shift_period = nil)
    requirement = requirement_for(date, shift_period)
    return zero_shortage unless requirement

    current_shifts = shifts_on(date, shift_period).includes(:staff)

    pharmacist_count = current_shifts.joins(:staff).where(staffs: { role: :pharmacist }).count
    clerk_count = current_shifts.joins(:staff).where(staffs: { role: :clerk }).count

    {
      pharmacist: pharmacist_count - requirement.pharmacist_count,
      clerk: clerk_count - requirement.clerk_count,
      pharmacist_current: pharmacist_count,
      pharmacist_required: requirement.pharmacist_count,
      clerk_current: clerk_count,
      clerk_required: requirement.clerk_count
    }
  end

  # AM/PM別の過不足をまとめて算出
  def shortage_by_period(date)
    {
      am: shortage_on(date, :am),
      pm: shortage_on(date, :pm)
    }
  end

  # 日付から曜日タイプを判定
  def self.day_type_for(date)
    return :holiday if HolidayJp.holiday?(date)

    case date.wday
    when 0 then :holiday   # 日曜
    when 6 then :saturday  # 土曜
    else :weekday          # 平日
    end
  end

  private

  def zero_shortage
    {
      pharmacist: 0, clerk: 0,
      pharmacist_current: 0, pharmacist_required: 0,
      clerk_current: 0, clerk_required: 0
    }
  end
end
