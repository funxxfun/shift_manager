# app/models/staff.rb
class Staff < ApplicationRecord
  belongs_to :base_store, class_name: 'Store', optional: true
  has_many :shifts, dependent: :destroy

  enum role: { pharmacist: 0, clerk: 1 }

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, presence: true

  def role_label
    case role
    when 'pharmacist' then '薬剤師'
    when 'clerk' then '事務'
    end
  end

  # 指定日にシフトがあるか
  def working_on?(date)
    shifts.exists?(date: date)
  end

  # 指定日のシフト
  def shift_on(date)
    shifts.find_by(date: date)
  end

  # 指定日に応援可能か（その日シフトがある かつ 所属店舗で余剰）
  def available_for_support_on?(date)
    shift = shift_on(date)
    return false unless shift

    store_shortage = shift.store.shortage_on(date)
    
    if pharmacist?
      store_shortage[:pharmacist] > 0  # 余剰があれば応援可能
    else
      store_shortage[:clerk] > 0
    end
  end
end
