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

  # AI提案カードのレンダリング
  def render_suggestion(suggestion, date)
    can_request = current_staff.manager_or_above?
    already_requested = suggestion[:shift_id] && SupportRequest.pending.exists?(
      shift_id: suggestion[:shift_id],
      requesting_store_id: suggestion[:to_store].id
    )

    content_tag(:div, class: 'bg-gray-50 rounded-lg p-4 flex flex-col md:flex-row md:items-center md:justify-between gap-4') do
      info_section = content_tag(:div, class: 'flex-1') do
        staff_line = content_tag(:div, class: 'font-medium') do
          content_tag(:span, suggestion[:staff].name, class: 'text-purple-600 font-bold') +
          content_tag(:span, "（#{suggestion[:staff].role_label}）", class: 'text-gray-500') +
          'を'
        end

        move_line = content_tag(:div, class: 'text-lg mt-1') do
          content_tag(:span, suggestion[:from_store].name, class: 'font-bold') +
          content_tag(:span, '→', class: 'mx-2') +
          content_tag(:span, suggestion[:to_store].name, class: 'font-bold text-red-600') +
          'へ移動'
        end

        reason_line = content_tag(:div, suggestion[:reason], class: 'text-sm text-gray-500 mt-2')

        staff_line + move_line + reason_line
      end

      button_section = if already_requested
        content_tag(:span, '要請済み', class: 'px-6 py-3 bg-yellow-100 text-yellow-700 rounded-lg font-bold text-sm')
      elsif can_request && suggestion[:shift_id]
        button_to support_requests_path,
          method: :post,
          params: {
            support_request: {
              shift_id: suggestion[:shift_id],
              requesting_store_id: suggestion[:to_store].id,
              reason: suggestion[:reason]
            },
            date: date
          },
          class: 'px-6 py-3 bg-purple-600 text-white rounded-lg font-bold hover:bg-purple-700 transition' do
          '応援要請'
        end
      else
        content_tag(:span, '権限なし', class: 'px-6 py-3 bg-gray-300 text-gray-500 rounded-lg font-bold text-sm')
      end

      info_section + button_section
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
