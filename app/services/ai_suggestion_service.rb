# app/services/ai_suggestion_service.rb
class AiSuggestionService
  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
  end

  # 指定日の補填提案を生成
  def suggest(date)
    shortage_data = ShortageCalculatorService.calculate_all(date)
    
    # 不足店舗がなければ提案不要
    return [] if shortage_data[:summary][:shortage_stores] == 0

    # 補填候補を抽出
    candidates = find_support_candidates(date, shortage_data)
    
    # AIで最適な組み合わせを提案
    if @api_key.present?
      ai_suggestions(date, shortage_data, candidates)
    else
      rule_based_suggestions(date, shortage_data, candidates)
    end
  end

  private

  # 補填候補（余剰店舗のスタッフ）を抽出
  def find_support_candidates(date, shortage_data)
    surplus_stores = shortage_data[:stores].select { |s| s[:status] == :surplus }
    
    candidates = []
    
    surplus_stores.each do |store_data|
      store = Store.find(store_data[:id])
      shifts = store.shifts_on(date).includes(:staff)
      
      shifts.each do |shift|
        staff = shift.staff
        # 余剰の職種のスタッフのみ候補
        if staff.pharmacist? && store_data[:pharmacist][:diff] > 0
          candidates << {
            staff: staff,
            from_store: store,
            role: :pharmacist,
            surplus: store_data[:pharmacist][:diff]
          }
        elsif staff.clerk? && store_data[:clerk][:diff] > 0
          candidates << {
            staff: staff,
            from_store: store,
            role: :clerk,
            surplus: store_data[:clerk][:diff]
          }
        end
      end
    end
    
    candidates
  end

  # ルールベースの提案（API未設定時）
  def rule_based_suggestions(date, shortage_data, candidates)
    suggestions = []
    
    shortage_stores = shortage_data[:stores].select { |s| s[:status] == :shortage }
    
    shortage_stores.each do |store_data|
      store = Store.find(store_data[:id])
      
      # 薬剤師不足の場合
      if store_data[:pharmacist][:diff] < 0
        pharmacist_candidates = candidates.select { |c| c[:role] == :pharmacist }
        needed = store_data[:pharmacist][:diff].abs
        
        pharmacist_candidates.first(needed).each do |candidate|
          suggestions << build_suggestion(candidate, store, date, 
            "#{candidate[:from_store].name}は薬剤師が#{candidate[:surplus]}名余剰のため")
        end
      end
      
      # 事務不足の場合
      if store_data[:clerk][:diff] < 0
        clerk_candidates = candidates.select { |c| c[:role] == :clerk }
        needed = store_data[:clerk][:diff].abs
        
        clerk_candidates.first(needed).each do |candidate|
          suggestions << build_suggestion(candidate, store, date,
            "#{candidate[:from_store].name}は事務が#{candidate[:surplus]}名余剰のため")
        end
      end
    end
    
    suggestions
  end

  # Claude APIで提案を生成
  def ai_suggestions(date, shortage_data, candidates)
    return rule_based_suggestions(date, shortage_data, candidates) if candidates.empty?

    prompt = build_prompt(date, shortage_data, candidates)
    
    response = call_claude_api(prompt)
    parse_ai_response(response, date, shortage_data, candidates)
  rescue => e
    Rails.logger.error "AI API Error: #{e.message}"
    rule_based_suggestions(date, shortage_data, candidates)
  end

  def build_prompt(date, shortage_data, candidates)
    <<~PROMPT
      あなたは調剤薬局チェーンのシフト管理AIアシスタントです。
      以下の情報を基に、最適な人員補填を提案してください。

      ## 日付
      #{date}

      ## 各店舗の状況
      #{format_store_status(shortage_data)}

      ## 補填候補者
      #{format_candidates(candidates)}

      ## 制約条件
      - 余剰がある店舗からのみ補填可能
      - 同じ職種同士でのみ補填可能（薬剤師→薬剤師、事務→事務）
      - 1人のスタッフは1日1店舗のみ

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

  def format_store_status(shortage_data)
    shortage_data[:stores].map do |s|
      "#{s[:name]}: 薬剤師#{s[:pharmacist][:diff]}, 事務#{s[:clerk][:diff]} (#{s[:status]})"
    end.join("\n")
  end

  def format_candidates(candidates)
    candidates.map do |c|
      "#{c[:staff].name}(#{c[:role] == :pharmacist ? '薬剤師' : '事務'}) - #{c[:from_store].name}から（余剰#{c[:surplus]}名）"
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

  def parse_ai_response(response, date, shortage_data, candidates)
    content = response.dig('content', 0, 'text')
    return rule_based_suggestions(date, shortage_data, candidates) unless content

    # JSONを抽出
    json_match = content.match(/\[[\s\S]*\]/)
    return rule_based_suggestions(date, shortage_data, candidates) unless json_match

    ai_suggestions = JSON.parse(json_match[0])
    
    ai_suggestions.map do |s|
      staff = Staff.find_by(id: s['staff_id'])
      from_store = Store.find_by(id: s['from_store_id'])
      to_store = Store.find_by(id: s['to_store_id'])
      
      next unless staff && from_store && to_store
      
      {
        staff: staff,
        from_store: from_store,
        to_store: to_store,
        role: staff.role,
        reason: s['reason'],
        date: date
      }
    end.compact
  rescue JSON::ParserError
    rule_based_suggestions(date, shortage_data, candidates)
  end

  def build_suggestion(candidate, to_store, date, reason)
    {
      staff: candidate[:staff],
      from_store: candidate[:from_store],
      to_store: to_store,
      role: candidate[:role],
      reason: reason,
      date: date
    }
  end
end
