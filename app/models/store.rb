# app/models/store.rb
class Store < ApplicationRecord
  has_many :store_requirements, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :staffs, foreign_key: :base_store_id

  accepts_nested_attributes_for :store_requirements, allow_destroy: true

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  # 指定日の必要人数を取得
  def requirement_for(date)
    day_type = self.class.day_type_for(date)
    store_requirements.find_by(day_type: day_type)
  end

  # 指定日のシフトを取得
  def shifts_on(date)
    shifts.where(date: date)
  end

  # 指定日の過不足を算出
  def shortage_on(date)
    requirement = requirement_for(date)
    return { pharmacist: 0, clerk: 0 } unless requirement

    current_shifts = shifts_on(date).includes(:staff)
    
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

  # 日付から曜日タイプを判定
  def self.day_type_for(date)
    return :holiday if HolidayJp.holiday?(date)
    
    case date.wday
    when 0 then :holiday   # 日曜
    when 6 then :saturday  # 土曜
    else :weekday          # 平日
    end
  end
end
