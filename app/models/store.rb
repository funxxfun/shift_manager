# app/models/store.rb
class Store < ApplicationRecord
  has_many :store_requirements, dependent: :destroy
  has_many :store_operating_hours, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :staffs, foreign_key: :base_store_id

  accepts_nested_attributes_for :store_requirements, allow_destroy: true
  accepts_nested_attributes_for :store_operating_hours, allow_destroy: true

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  # 指定日・時間帯の必要人数を取得
  def requirement_for(date, shift_period = nil)
    if shift_period
      store_requirements.find_by(day_of_week: date.wday, shift_period: shift_period)
    else
      # shift_periodが指定されない場合はAMを返す（後方互換性）
      store_requirements.find_by(day_of_week: date.wday, shift_period: :am)
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
    # 休業の場合は閉店状態を返す
    return closed_shortage unless open_on?(date, shift_period)

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

  # 指定日の営業時間設定を取得
  def operating_hour_for(date)
    store_operating_hours.find_by(day_of_week: date.wday)
  end

  # 指定日・時間帯に営業しているか
  def open_on?(date, shift_period = nil)
    oh = operating_hour_for(date)
    return true unless oh  # 設定なしはオープン扱い
    return false if oh.is_closed

    case shift_period&.to_sym
    when :am then oh.covers_am?
    when :pm then oh.covers_pm?
    else oh.covers_am? || oh.covers_pm?
    end
  end

  # 指定日に完全休業か
  def closed_on?(date)
    !open_on?(date)
  end

  private

  def zero_shortage
    {
      pharmacist: 0, clerk: 0,
      pharmacist_current: 0, pharmacist_required: 0,
      clerk_current: 0, clerk_required: 0
    }
  end

  def closed_shortage
    {
      pharmacist: 0, clerk: 0,
      pharmacist_current: 0, pharmacist_required: 0,
      clerk_current: 0, clerk_required: 0,
      closed: true
    }
  end
end
