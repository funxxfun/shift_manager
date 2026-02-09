# app/services/ai_suggestion_service.rb
class AiSuggestionService
  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
  end

  # 指定日の補填提案を生成（AM/PM別）
  def suggest(date)
    shortage_data = ShortageCalculatorService.calculate_all(date)

    # AM/PM別に提案を生成
    suggestions = []

    [:am, :pm].each do |period|
      period_suggestions = suggest_for_period(date, shortage_data, period)
      suggestions.concat(period_suggestions)
    end

    suggestions
  end

  private

  def suggest_for_period(date, shortage_data, period)
    # 不足店舗がなければ提案不要
    shortage_stores = shortage_data[:stores].select { |s| s[period][:status] == :shortage }
    return [] if shortage_stores.empty?

    # 補填候補を抽出
    candidates = find_support_candidates(date, shortage_data, period)
    return [] if candidates.empty?

    # AIで最適な組み合わせを提案
    if @api_key.present?
      ai_suggestions_for_period(date, shortage_data, candidates, period)
    else
      rule_based_suggestions_for_period(date, shortage_data, candidates, period)
    end
  end

  # 補填候補（余剰店舗のスタッフ）を抽出
  def find_support_candidates(date, shortage_data, period)
    surplus_stores = shortage_data[:stores].select { |s| s[period][:status] == :surplus }

    candidates = []

    surplus_stores.each do |store_data|
      store = Store.find(store_data[:id])
      shifts = store.shifts_on(date, period).includes(:staff)

      shifts.each do |shift|
        staff = shift.staff
        period_data = store_data[period]

        if staff.pharmacist? && period_data[:pharmacist][:diff] > 0
          candidates << {
            staff: staff,
            shift: shift,
            from_store: store,
            role: :pharmacist,
            surplus: period_data[:pharmacist][:diff],
            period: period
          }
        elsif staff.clerk? && period_data[:clerk][:diff] > 0
          candidates << {
            staff: staff,
            shift: shift,
            from_store: store,
            role: :clerk,
            surplus: period_data[:clerk][:diff],
            period: period
          }
        end
      end
    end

    # 余剰数が多い店舗を優先
    candidates.sort_by { |c| -c[:surplus] }
  end

  # ルールベースの提案（API未設定時）
  def rule_based_suggestions_for_period(date, shortage_data, candidates, period)
    suggestions = []

    shortage_stores = shortage_data[:stores].select { |s| s[period][:status] == :shortage }

    shortage_stores.each do |store_data|
      store = Store.find(store_data[:id])
      period_data = store_data[period]

      # 薬剤師不足の場合
      if period_data[:pharmacist][:diff] < 0
        pharmacist_candidates = candidates.select { |c| c[:role] == :pharmacist }
        needed = period_data[:pharmacist][:diff].abs

        pharmacist_candidates.first(needed).each do |candidate|
          suggestions << build_suggestion(candidate, store, date,
            "#{candidate[:from_store].name}は薬剤師が#{candidate[:surplus]}名余剰のため")
        end
      end

      # 事務不足の場合
      if period_data[:clerk][:diff] < 0
        clerk_candidates = candidates.select { |c| c[:role] == :clerk }
        needed = period_data[:clerk][:diff].abs

        clerk_candidates.first(needed).each do |candidate|
          suggestions << build_suggestion(candidate, store, date,
            "#{candidate[:from_store].name}は事務が#{candidate[:surplus]}名余剰のため")
        end
      end
    end

    suggestions
  end

  # Claude APIで提案を生成
  def ai_suggestions_for_period(date, shortage_data, candidates, period)
    return rule_based_suggestions_for_period(date, shortage_data, candidates, period) if candidates.empty?

    prompt = build_prompt_for_period(date, shortage_data, candidates, period)

    response = call_claude_api(prompt)
    parse_ai_response(response, date, shortage_data, candidates, period)
  rescue => e
    Rails.logger.error "AI API Error: #{e.message}"
    rule_based_suggestions_for_period(date, shortage_data, candidates, period)
  end

  def build_prompt_for_period(date, shortage_data, candidates, period)
    period_label = period == :am ? 'AM（午前）' : 'PM（午後）'

    <<~PROMPT
      あなたは調剤薬局チェーンのシフト管理AIアシスタントです。
      以下の情報を基に、最適な人員補填を提案してください。

      ## 日付・時間帯
      #{date} #{period_label}

      ## 各店舗の状況（#{period_label}）
      #{format_store_status_for_period(shortage_data, period)}

      ## 補填候補者
      #{format_candidates(candidates)}

      ## 制約条件
      - 余剰がある店舗からのみ補填可能
      - 同じ職種同士でのみ補填可能（薬剤師→薬剤師、事務→事務）
      - 同じ時間帯（#{period_label}）のみ補填可能
      - 1人のスタッフは1日1店舗のみ（同時間帯内）

      ## 出力形式
      以下のJSON形式で提案してください：
      [
        {
          "staff_id": 1,
          "from_store_id": 2,
          "to_store_id": 3,
          "reason": "理由"
        }
      ]
    PROMPT
  end

  def format_store_status_for_period(shortage_data, period)
    shortage_data[:stores].map do |s|
      period_data = s[period]
      "#{s[:name]}: 薬剤師#{period_data[:pharmacist][:diff]}, 事務#{period_data[:clerk][:diff]} (#{period_data[:status]})"
    end.join("\n")
  end

  def format_candidates(candidates)
    candidates.map do |c|
      period_label = c[:period] == :am ? 'AM' : 'PM'
      "#{c[:staff].name}(#{c[:role] == :pharmacist ? '薬剤師' : '事務'}) - #{c[:from_store].name}から（余剰#{c[:surplus]}名）[#{period_label}]"
    end.join("\n")
  end

  def call_claude_api(prompt)
    conn = Faraday.new(url: 'https://api.anthropic.com') do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end

    response = conn.post('/v1/messages') do |req|
      req.headers['x-api-key'] = @api_key
      req.headers['anthropic-version'] = '2023-06-01'
      req.headers['content-type'] = 'application/json'
      req.body = {
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        messages: [{ role: 'user', content: prompt }]
      }
    end

    response.body
  end

  def parse_ai_response(response, date, shortage_data, candidates, period)
    content = response.dig('content', 0, 'text')
    return rule_based_suggestions_for_period(date, shortage_data, candidates, period) unless content

    # JSONを抽出
    json_match = content.match(/\[[\s\S]*\]/)
    return rule_based_suggestions_for_period(date, shortage_data, candidates, period) unless json_match

    ai_suggestions = JSON.parse(json_match[0])

    ai_suggestions.map do |s|
      staff = Staff.find_by(id: s['staff_id'])
      from_store = Store.find_by(id: s['from_store_id'])
      to_store = Store.find_by(id: s['to_store_id'])

      next unless staff && from_store && to_store

      # candidateからshiftを取得
      candidate = candidates.find { |c| c[:staff].id == staff.id }
      shift_id = candidate&.dig(:shift)&.id

      {
        staff: staff,
        from_store: from_store,
        to_store: to_store,
        role: staff.role,
        reason: s['reason'],
        date: date,
        shift_period: period,
        shift_id: shift_id
      }
    end.compact
  rescue JSON::ParserError
    rule_based_suggestions_for_period(date, shortage_data, candidates, period)
  end

  def build_suggestion(candidate, to_store, date, reason)
    {
      staff: candidate[:staff],
      from_store: candidate[:from_store],
      to_store: to_store,
      role: candidate[:role],
      reason: reason,
      date: date,
      shift_period: candidate[:period],
      shift_id: candidate[:shift]&.id
    }
  end
end
