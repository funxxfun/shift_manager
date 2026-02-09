# app/models/store_operating_hour.rb
class StoreOperatingHour < ApplicationRecord
  belongs_to :store

  validates :day_of_week, presence: true,
            inclusion: { in: 0..6 },
            uniqueness: { scope: :store_id, message: 'は既に登録されています' }

  DAY_NAMES = %w[日 月 火 水 木 金 土].freeze

  def day_name
    DAY_NAMES[day_of_week]
  end

  # 営業時間の表示用文字列
  def hours_display
    return '休業' if is_closed
    return '未設定' unless open_time && close_time

    "#{format_time(open_time)}〜#{format_time(close_time)}"
  end

  # AM営業しているか（営業時間が12:00より前に始まる）
  def covers_am?
    return false if is_closed || !open_time

    open_time.hour < 12
  end

  # PM営業しているか（営業時間が12:00以降まで続く）
  def covers_pm?
    return false if is_closed || !close_time

    close_time.hour >= 12
  end

  private

  def format_time(time)
    time.strftime('%H:%M')
  end
end
