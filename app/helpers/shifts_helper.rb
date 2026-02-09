# app/helpers/shifts_helper.rb
module ShiftsHelper
  # 指定年月の20日締め周期を計算
  # 例: 2026年1月 → 2025/12/21 〜 2026/1/20
  def period_for(year, month)
    end_date = Date.new(year, month, 20)
    start_date = (end_date << 1) + 1 # 前月21日
    { start_date: start_date, end_date: end_date, year: year, month: month }
  end

  # 指定日を含む周期を返す
  def current_period(date = Date.today)
    if date.day <= 20
      period_for(date.year, date.month)
    else
      # 21日以降は翌月周期
      next_month = date.next_month
      period_for(next_month.year, next_month.month)
    end
  end

  # 周期ラベル（表示用）
  def period_label(year, month)
    "#{year}年#{month}月度"
  end

  # 前月周期を取得
  def previous_period(year, month)
    date = Date.new(year, month, 1) - 1.month
    period_for(date.year, date.month)
  end

  # 翌月周期を取得
  def next_period(year, month)
    date = Date.new(year, month, 1) + 1.month
    period_for(date.year, date.month)
  end

  # 過不足ステータスに応じたセルのCSSクラス
  def status_cell_class(status)
    case status
    when :shortage
      'bg-red-500'
    when :surplus
      'bg-green-500'
    when :closed
      'bg-gray-400 opacity-50'
    else
      'bg-gray-300'
    end
  end

  # AM用のツールチップ生成
  def am_tooltip(store_data)
    return 'データなし' unless store_data
    period_tooltip(store_data[:am])
  end

  # PM用のツールチップ生成
  def pm_tooltip(store_data)
    return 'データなし' unless store_data
    period_tooltip(store_data[:pm])
  end

  # 時間帯ラベル
  def shift_period_label(period)
    case period.to_sym
    when :am then 'AM'
    when :pm then 'PM'
    when :full_day then '終日'
    else period.to_s
    end
  end

  private

  def period_tooltip(period_data)
    return 'データなし' unless period_data
    return '休業' if period_data[:status] == :closed
    ph_diff = period_data[:pharmacist][:diff]
    cl_diff = period_data[:clerk][:diff]
    "薬剤師: #{ph_diff >= 0 ? '+' : ''}#{ph_diff}, 事務: #{cl_diff >= 0 ? '+' : ''}#{cl_diff}"
  end
end
