# db/seeds.rb

puts "=== Shift Manager Seed ==="
puts ""

# ==============================
# 店舗マスタ
# ==============================
puts "Creating stores..."

stores_data = [
  { code: '001', name: '博多駅前店', address: '福岡市博多区博多駅前2-1-1', nearest_station: '博多駅' },
  { code: '002', name: '天神店', address: '福岡市中央区天神1-1-1', nearest_station: '天神駅' },
  { code: '003', name: '六本松店', address: '福岡市中央区六本松3-1-1', nearest_station: '六本松駅' },
  { code: '004', name: '薬院店', address: '福岡市中央区薬院1-1-1', nearest_station: '薬院駅' },
  { code: '005', name: '大橋店', address: '福岡市南区大橋1-1-1', nearest_station: '大橋駅' },
  { code: '006', name: '西新店', address: '福岡市早良区西新4-1-1', nearest_station: '西新駅' },
]

stores_data.each do |data|
  store = Store.find_or_create_by!(code: data[:code]) do |s|
    s.name = data[:name]
    s.address = data[:address]
    s.nearest_station = data[:nearest_station]
  end
  puts "  Created: #{store.name}"
end

# ==============================
# 必要人数設定（曜日別 × AM/PM）
# ==============================
puts ""
puts "Creating store requirements (day_of_week × AM/PM)..."

# day_of_week: 0=日, 1=月, 2=火, 3=水, 4=木, 5=金, 6=土
requirements_data = {
  # 店舗コード => { 曜日(0-6) => { am: [薬,事], pm: [薬,事] } }
  '001' => {
    0 => { am: [0, 0], pm: [0, 0] },  # 日曜: 休業
    1 => { am: [2, 1], pm: [2, 1] },  # 月曜
    2 => { am: [2, 1], pm: [2, 1] },  # 火曜
    3 => { am: [2, 1], pm: [2, 1] },  # 水曜
    4 => { am: [2, 1], pm: [2, 1] },  # 木曜
    5 => { am: [2, 1], pm: [2, 1] },  # 金曜
    6 => { am: [1, 1], pm: [1, 1] },  # 土曜
  },
  '002' => {
    0 => { am: [0, 0], pm: [0, 0] },
    1 => { am: [2, 2], pm: [2, 2] },
    2 => { am: [2, 2], pm: [2, 2] },
    3 => { am: [2, 2], pm: [2, 2] },
    4 => { am: [2, 2], pm: [2, 2] },
    5 => { am: [2, 2], pm: [2, 2] },
    6 => { am: [1, 1], pm: [1, 1] },
  },
  '003' => {
    0 => { am: [0, 0], pm: [0, 0] },
    1 => { am: [1, 1], pm: [1, 1] },
    2 => { am: [1, 1], pm: [1, 1] },
    3 => { am: [0, 0], pm: [0, 0] },  # 水曜定休
    4 => { am: [1, 1], pm: [1, 1] },
    5 => { am: [1, 1], pm: [1, 1] },
    6 => { am: [1, 1], pm: [0, 0] },  # 土曜午前のみ
  },
  '004' => {
    0 => { am: [0, 0], pm: [0, 0] },
    1 => { am: [1, 1], pm: [1, 1] },
    2 => { am: [1, 1], pm: [1, 1] },
    3 => { am: [1, 1], pm: [1, 1] },
    4 => { am: [1, 1], pm: [1, 1] },
    5 => { am: [1, 1], pm: [1, 1] },
    6 => { am: [1, 1], pm: [0, 0] },  # 土曜午前のみ
  },
  '005' => {
    0 => { am: [0, 0], pm: [0, 0] },
    1 => { am: [2, 1], pm: [2, 1] },
    2 => { am: [2, 1], pm: [2, 1] },
    3 => { am: [2, 1], pm: [2, 1] },
    4 => { am: [2, 1], pm: [2, 1] },
    5 => { am: [2, 1], pm: [2, 1] },
    6 => { am: [1, 1], pm: [1, 1] },
  },
  '006' => {
    0 => { am: [0, 0], pm: [0, 0] },
    1 => { am: [1, 1], pm: [1, 1] },
    2 => { am: [1, 1], pm: [1, 1] },
    3 => { am: [1, 1], pm: [1, 1] },
    4 => { am: [1, 1], pm: [1, 1] },
    5 => { am: [1, 1], pm: [1, 1] },
    6 => { am: [1, 1], pm: [1, 0] },  # 土曜午後は事務不要
  }
}

requirements_data.each do |store_code, days|
  store = Store.find_by!(code: store_code)

  days.each do |day_of_week, periods|
    periods.each do |period, counts|
      StoreRequirement.find_or_create_by!(
        store: store,
        day_of_week: day_of_week,
        shift_period: period
      ) do |r|
        r.pharmacist_count = counts[0]
        r.clerk_count = counts[1]
      end
    end
  end
  puts "  #{store.name}: 必要人数設定完了"
end

# ==============================
# 営業時間設定
# ==============================
puts ""
puts "Creating store operating hours..."

operating_hours_data = {
  # 店舗コード => { 曜日(0-6) => [開店, 閉店] または :closed }
  '001' => {
    0 => :closed,                    # 日曜: 休業
    1 => ['08:30', '19:00'],         # 月曜
    2 => ['08:30', '19:00'],         # 火曜
    3 => ['08:30', '19:00'],         # 水曜
    4 => ['08:30', '19:00'],         # 木曜
    5 => ['08:30', '19:00'],         # 金曜
    6 => ['09:00', '17:00'],         # 土曜
  },
  '002' => {
    0 => :closed,
    1 => ['09:00', '20:00'],
    2 => ['09:00', '20:00'],
    3 => ['09:00', '20:00'],
    4 => ['09:00', '20:00'],
    5 => ['09:00', '20:00'],
    6 => ['09:00', '18:00'],
  },
  '003' => {
    0 => :closed,
    1 => ['09:00', '18:00'],
    2 => ['09:00', '18:00'],
    3 => :closed,                    # 水曜定休
    4 => ['09:00', '18:00'],
    5 => ['09:00', '18:00'],
    6 => ['09:00', '13:00'],         # 土曜午前のみ
  },
  '004' => {
    0 => :closed,
    1 => ['08:30', '18:30'],
    2 => ['08:30', '18:30'],
    3 => ['08:30', '18:30'],
    4 => ['08:30', '18:30'],
    5 => ['08:30', '18:30'],
    6 => ['09:00', '12:00'],         # 土曜午前のみ
  },
  '005' => {
    0 => :closed,
    1 => ['08:30', '19:00'],
    2 => ['08:30', '19:00'],
    3 => ['08:30', '19:00'],
    4 => ['08:30', '19:00'],
    5 => ['08:30', '19:00'],
    6 => ['09:00', '17:00'],
  },
  '006' => {
    0 => :closed,
    1 => ['09:00', '18:00'],
    2 => ['09:00', '18:00'],
    3 => ['09:00', '18:00'],
    4 => ['09:00', '18:00'],
    5 => ['09:00', '18:00'],
    6 => ['09:00', '15:00'],
  }
}

operating_hours_data.each do |store_code, days|
  store = Store.find_by!(code: store_code)

  days.each do |day_of_week, hours|
    attrs = { store: store, day_of_week: day_of_week }

    if hours == :closed
      StoreOperatingHour.find_or_create_by!(attrs) do |oh|
        oh.is_closed = true
        oh.open_time = nil
        oh.close_time = nil
      end
    else
      StoreOperatingHour.find_or_create_by!(attrs) do |oh|
        oh.is_closed = false
        oh.open_time = hours[0]
        oh.close_time = hours[1]
      end
    end
  end
  puts "  #{store.name}: 営業時間設定完了"
end

# ==============================
# スタッフマスタ
# ==============================
puts ""
puts "Creating staffs..."

staffs_data = [
  # 本部管理者
  { code: 'ADMIN', name: '管理者', role: :pharmacist, store_code: '001', permission_level: :admin },
  # エリアマネージャー
  { code: 'M001', name: '斉藤マネージャー', role: :pharmacist, store_code: '001', permission_level: :area_manager },
  # 店舗管理者
  { code: 'E001', name: '山田太郎', role: :pharmacist, store_code: '001', permission_level: :store_manager },
  { code: 'E004', name: '田中美咲', role: :pharmacist, store_code: '002', permission_level: :store_manager },
  # 一般スタッフ
  { code: 'E002', name: '佐藤花子', role: :pharmacist, store_code: '001' },
  { code: 'E003', name: '鈴木一郎', role: :clerk, store_code: '001' },
  { code: 'E005', name: '高橋健太', role: :pharmacist, store_code: '002' },
  { code: 'E006', name: '伊藤さくら', role: :clerk, store_code: '002' },
  { code: 'E007', name: '渡辺大輔', role: :clerk, store_code: '002' },
  { code: 'E008', name: '小林恵子', role: :pharmacist, store_code: '003' },
  { code: 'E009', name: '加藤真一', role: :clerk, store_code: '003' },
  { code: 'E010', name: '吉田愛', role: :pharmacist, store_code: '004' },
  { code: 'E011', name: '山本翔太', role: :clerk, store_code: '004' },
  { code: 'E012', name: '中村美穂', role: :pharmacist, store_code: '005' },
  { code: 'E013', name: '松本康介', role: :pharmacist, store_code: '005' },
  { code: 'E014', name: '井上由美', role: :clerk, store_code: '005' },
  { code: 'E015', name: '木村拓也', role: :pharmacist, store_code: '006' },
  { code: 'E016', name: '林美香', role: :clerk, store_code: '006' },
]

staffs_data.each do |data|
  store = Store.find_by(code: data[:store_code])
  Staff.find_or_create_by!(code: data[:code]) do |staff|
    staff.name = data[:name]
    staff.role = data[:role]
    staff.base_store = store
    staff.permission_level = data[:permission_level] || :staff
  end
  permission = data[:permission_level]&.to_s || 'staff'
  puts "  Created: #{data[:name]} (#{permission})"
end

# ==============================
# シフト作成ヘルパー
# ==============================
def create_shift(date:, store_code:, staff_code:, period: :full_day, start_time: nil, end_time: nil)
  store = Store.find_by!(code: store_code)
  staff = Staff.find_by!(code: staff_code)

  # 時間帯に応じたデフォルト時刻
  times = case period.to_sym
          when :am
            { start: '09:00', end: '12:00' }
          when :pm
            { start: '13:00', end: '18:00' }
          else # full_day
            { start: '09:00', end: '18:00' }
          end

  Shift.find_or_create_by!(date: date, staff: staff, shift_period: period) do |s|
    s.store = store
    s.start_time = start_time || times[:start]
    s.end_time = end_time || times[:end]
    s.break_minutes = period == :full_day ? 60 : 0
  end
end

def create_shifts_for_day(date, assignments)
  assignments.each do |store_code, staff_list|
    staff_list.each do |staff_info|
      if staff_info.is_a?(String)
        # シンプルな形式: 終日勤務
        create_shift(date: date, store_code: store_code, staff_code: staff_info, period: :full_day)
      elsif staff_info.is_a?(Hash)
        # 詳細形式: { code: 'E001', period: :am }
        create_shift(
          date: date,
          store_code: store_code,
          staff_code: staff_info[:code],
          period: staff_info[:period] || :full_day
        )
      end
    end
  end
end

# ==============================
# サンプルシフトデータ（2026年2月〜3月）
# ==============================
puts ""
puts "Creating sample shifts for February and March..."

# ========================================
# 2月: 週ごとに異なるパターン
# ========================================

# --- 第1週 (2/2-2/7): 通常運用（概ね充足） ---
puts "  2月第1週: 通常運用"

(Date.new(2026, 2, 2)..Date.new(2026, 2, 7)).each do |date|
  next if date.sunday?  # 日曜休業

  # 水曜定休の店舗をスキップ
  skip_003 = date.wednesday?

  assignments = {
    '001' => [
      { code: 'E001', period: :full_day },
      { code: 'E002', period: :full_day },
      { code: 'E003', period: :full_day }
    ],
    '002' => [
      { code: 'E004', period: :full_day },
      { code: 'E005', period: :full_day },
      { code: 'E006', period: :full_day },
      { code: 'E007', period: :full_day }
    ],
    '003' => skip_003 ? [] : [
      { code: 'E008', period: :full_day },
      { code: 'E009', period: :full_day }
    ],
    '004' => [
      { code: 'E010', period: date.saturday? ? :am : :full_day },
      { code: 'E011', period: date.saturday? ? :am : :full_day }
    ],
    '005' => [
      { code: 'E012', period: :full_day },
      { code: 'E013', period: :full_day },
      { code: 'E014', period: :full_day }
    ],
    '006' => [
      { code: 'E015', period: :full_day },
      { code: 'E016', period: :full_day }
    ]
  }

  create_shifts_for_day(date, assignments)
end

# --- 第2週 (2/9-2/14): AM/PMで状況が異なるパターン ---
puts "  2月第2週: AM/PM別パターン"

# 2/9（月）- AM余剰・PM不足
create_shifts_for_day(Date.new(2026, 2, 9), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :am },         # AM余剰
    { code: 'E003', period: :am }          # PM事務不足
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :am },         # PM薬剤師不足
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :am }          # PM事務不足
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :pm }          # AM事務不足
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :pm },         # AM薬剤師不足
    { code: 'E016', period: :full_day }
  ]
})

# 2/10（火）- 全店舗でPM不足傾向
create_shifts_for_day(Date.new(2026, 2, 10), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :am },
    { code: 'E003', period: :am }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :am },
    { code: 'E006', period: :am },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :am },
    { code: 'E009', period: :am }
  ],
  '004' => [
    { code: 'E010', period: :am },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :am },
    { code: 'E014', period: :am }
  ],
  '006' => [
    { code: 'E015', period: :am },
    { code: 'E016', period: :am }
  ]
})

# 2/11（水・祝）- 祝日対応（一部休業）
create_shifts_for_day(Date.new(2026, 2, 11), {
  '001' => [{ code: 'E001', period: :am }],
  '002' => [{ code: 'E004', period: :am }],
  '003' => [],  # 水曜定休
  '004' => [],
  '005' => [{ code: 'E012', period: :am }],
  '006' => []
})

# 2/12（木）- 全店舗でAM不足傾向
create_shifts_for_day(Date.new(2026, 2, 12), {
  '001' => [
    { code: 'E001', period: :pm },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :pm }
  ],
  '002' => [
    { code: 'E004', period: :pm },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :pm },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :pm },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :pm },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :pm },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :pm }
  ],
  '006' => [
    { code: 'E015', period: :pm },
    { code: 'E016', period: :full_day }
  ]
})

# 2/13（金）- 充足パターン
create_shifts_for_day(Date.new(2026, 2, 13), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 2/14（土）
create_shifts_for_day(Date.new(2026, 2, 14), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E006', period: :full_day }
  ],
  '003' => [{ code: 'E008', period: :am }],
  '004' => [{ code: 'E010', period: :am }],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [{ code: 'E015', period: :full_day }]
})

# --- 第3週 (2/16-2/21): 薬剤師不足週 ---
puts "  2月第3週: 薬剤師不足週"

# 2/16（月）- 複数店舗で薬剤師不足
create_shifts_for_day(Date.new(2026, 2, 16), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E003', period: :full_day }    # 薬剤師-1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }    # 薬剤師-1
  ],
  '003' => [
    { code: 'E009', period: :full_day }    # 薬剤師-1
  ],
  '004' => [
    { code: 'E011', period: :full_day }    # 薬剤師-1
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }    # 充足
  ],
  '006' => [
    { code: 'E016', period: :full_day }    # 薬剤師-1
  ]
})

# 2/17（火）- 博多駅前店と天神店のみ薬剤師不足
create_shifts_for_day(Date.new(2026, 2, 17), {
  '001' => [
    { code: 'E001', period: :am },         # PM薬剤師-1
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :pm },         # AM薬剤師-1
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 2/18（水）
create_shifts_for_day(Date.new(2026, 2, 18), {
  '001' => [
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }    # 薬剤師-1
  ],
  '002' => [
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }    # 薬剤師-1
  ],
  '003' => [],  # 水曜定休
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E014', period: :full_day }    # 薬剤師-1
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 2/19（木）- 全店舗で深刻な薬剤師不足
create_shifts_for_day(Date.new(2026, 2, 19), {
  '001' => [{ code: 'E003', period: :full_day }],    # 薬剤師-2
  '002' => [
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }              # 薬剤師-2
  ],
  '003' => [{ code: 'E009', period: :full_day }],    # 薬剤師-1
  '004' => [{ code: 'E011', period: :full_day }],    # 薬剤師-1
  '005' => [{ code: 'E014', period: :full_day }],    # 薬剤師-2
  '006' => [{ code: 'E016', period: :full_day }]     # 薬剤師-1
})

# 2/20（金）- 薬剤師余剰店舗あり（応援可能）
create_shifts_for_day(Date.new(2026, 2, 20), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'M001', period: :full_day },
    { code: 'E003', period: :full_day }    # 薬剤師+1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }    # 充足
  ],
  '003' => [
    { code: 'E009', period: :full_day }    # 薬剤師-1
  ],
  '004' => [
    { code: 'E011', period: :full_day }    # 薬剤師-1
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }    # 充足
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 2/21（土）
create_shifts_for_day(Date.new(2026, 2, 21), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E005', period: :full_day },
    { code: 'E007', period: :full_day }    # 薬剤師-1
  ],
  '003' => [{ code: 'E009', period: :am }],  # 薬剤師-1
  '004' => [{ code: 'E011', period: :am }],  # 薬剤師-1
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [{ code: 'E015', period: :full_day }]
})

# --- 第4週 (2/23-2/28): 事務不足週 ---
puts "  2月第4週: 事務不足週"

# 2/23（月・祝）- 祝日対応
create_shifts_for_day(Date.new(2026, 2, 23), {
  '001' => [{ code: 'E001', period: :am }],
  '002' => [
    { code: 'E004', period: :am },
    { code: 'E006', period: :am }
  ],
  '003' => [],
  '004' => [],
  '005' => [{ code: 'E012', period: :am }],
  '006' => []
})

# 2/24（火）- 事務不足パターン
create_shifts_for_day(Date.new(2026, 2, 24), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day }    # 事務-1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day }    # 事務-1
  ],
  '003' => [
    { code: 'E008', period: :full_day }    # 事務-1
  ],
  '004' => [
    { code: 'E010', period: :full_day }    # 事務-1
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day }    # 事務-1
  ],
  '006' => [
    { code: 'E015', period: :full_day }    # 事務-1
  ]
})

# 2/25（水）
create_shifts_for_day(Date.new(2026, 2, 25), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :am }          # PM事務不足
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :am },
    { code: 'E007', period: :pm }
  ],
  '003' => [],  # 水曜定休
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :pm }          # AM事務不足
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :am }          # PM事務不足
  ]
})

# 2/26（木）- 両方不足
create_shifts_for_day(Date.new(2026, 2, 26), {
  '001' => [
    { code: 'E001', period: :full_day }    # 薬剤師-1, 事務-1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E006', period: :full_day }    # 薬剤師-1, 事務-1
  ],
  '003' => [],                              # 完全不足
  '004' => [
    { code: 'E010', period: :am }          # PM両方不足
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :am }          # PM薬剤師-1
  ],
  '006' => [
    { code: 'E015', period: :pm }          # AM薬剤師-1, 事務-1
  ]
})

# 2/27（金）- 一部店舗のみ事務余剰
create_shifts_for_day(Date.new(2026, 2, 27), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day },
    { code: 'E009', period: :full_day }    # 事務+1（応援）
  ],
  '003' => [
    { code: 'E008', period: :full_day }    # 事務-1
  ],
  '004' => [
    { code: 'E010', period: :full_day }    # 事務-1
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day },
    { code: 'E011', period: :pm }          # 事務+1（応援）
  ],
  '006' => [
    { code: 'E015', period: :full_day }    # 事務-1
  ]
})

# 2/28（土）
create_shifts_for_day(Date.new(2026, 2, 28), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E006', period: :full_day }
  ],
  '003' => [{ code: 'E008', period: :am }],
  '004' => [{ code: 'E010', period: :am }],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [{ code: 'E016', period: :full_day }]  # 薬剤師-1
})

# ========================================
# 3月: 繁忙期と閑散期の混在
# ========================================

# --- 第1週 (3/2-3/7): 店舗により異なるパターン ---
puts "  3月第1週: 店舗別パターン"

# 3/2（月）- 博多・天神は余剰、その他は不足
create_shifts_for_day(Date.new(2026, 3, 2), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'M001', period: :full_day },
    { code: 'E003', period: :full_day }    # 薬剤師+1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E008', period: :full_day },   # 応援
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }    # 薬剤師+1
  ],
  '003' => [],                              # 完全不足
  '004' => [{ code: 'E011', period: :full_day }],  # 薬剤師-1
  '005' => [{ code: 'E014', period: :full_day }],  # 薬剤師-2
  '006' => []                               # 完全不足
})

# 3/3（火）- 逆パターン
create_shifts_for_day(Date.new(2026, 3, 3), {
  '001' => [{ code: 'E003', period: :full_day }],  # 薬剤師-2
  '002' => [
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }            # 薬剤師-2
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day },
    { code: 'M001', period: :full_day }            # 応援で薬剤師+1
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/4（水）
create_shifts_for_day(Date.new(2026, 3, 4), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [],  # 水曜定休
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/5（木）- 午前は充足、午後は不足
create_shifts_for_day(Date.new(2026, 3, 5), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :am },
    { code: 'E003', period: :am }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :am },
    { code: 'E006', period: :am },
    { code: 'E007', period: :am }
  ],
  '003' => [
    { code: 'E008', period: :am },
    { code: 'E009', period: :am }
  ],
  '004' => [
    { code: 'E010', period: :am },
    { code: 'E011', period: :am }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :am },
    { code: 'E014', period: :am }
  ],
  '006' => [
    { code: 'E015', period: :am },
    { code: 'E016', period: :am }
  ]
})

# 3/6（金）- 午前は不足、午後は充足
create_shifts_for_day(Date.new(2026, 3, 6), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :pm },
    { code: 'E003', period: :pm }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :pm },
    { code: 'E006', period: :pm },
    { code: 'E007', period: :pm }
  ],
  '003' => [
    { code: 'E008', period: :pm },
    { code: 'E009', period: :pm }
  ],
  '004' => [
    { code: 'E010', period: :pm },
    { code: 'E011', period: :pm }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :pm },
    { code: 'E014', period: :pm }
  ],
  '006' => [
    { code: 'E015', period: :pm },
    { code: 'E016', period: :pm }
  ]
})

# 3/7（土）
create_shifts_for_day(Date.new(2026, 3, 7), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E006', period: :full_day }
  ],
  '003' => [{ code: 'E008', period: :am }],
  '004' => [{ code: 'E010', period: :am }],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [{ code: 'E015', period: :full_day }]
})

# --- 第2週 (3/9-3/14): 余剰週（閑散期） ---
puts "  3月第2週: 余剰週"

# 3/9（月）- 全店舗で余剰
create_shifts_for_day(Date.new(2026, 3, 9), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'M001', period: :full_day },
    { code: 'E003', period: :full_day }        # 薬剤師+1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }        # 充足
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }        # 充足
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }        # 充足
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }        # 充足
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }        # 充足
  ]
})

# 3/10（火）
create_shifts_for_day(Date.new(2026, 3, 10), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'M001', period: :am },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/11（水）
create_shifts_for_day(Date.new(2026, 3, 11), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [],  # 水曜定休
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/12（木）- 特定店舗のみ薬剤師余剰
create_shifts_for_day(Date.new(2026, 3, 12), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'M001', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/13（金）- 特定店舗のみ事務余剰
create_shifts_for_day(Date.new(2026, 3, 13), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day },
    { code: 'M001', period: :pm }          # 薬剤師応援
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/14（土）
create_shifts_for_day(Date.new(2026, 3, 14), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :am },
    { code: 'E009', period: :am }
  ],
  '004' => [
    { code: 'E010', period: :am },
    { code: 'E011', period: :am }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# --- 第3週 (3/16-3/21): 繁忙期（大規模不足） ---
puts "  3月第3週: 繁忙期"

# 3/16（月）- 全店舗で不足（繁忙期スタート）
create_shifts_for_day(Date.new(2026, 3, 16), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E003', period: :am }          # 薬剤師-1, PM事務-1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E006', period: :pm }          # 薬剤師-1, AM事務-1
  ],
  '003' => [{ code: 'E009', period: :full_day }],  # 薬剤師-1
  '004' => [{ code: 'E011', period: :pm }],        # AM両方-1
  '005' => [
    { code: 'E012', period: :am },
    { code: 'E014', period: :pm }          # 全時間帯薬剤師-1
  ],
  '006' => [{ code: 'E016', period: :am }]         # PM両方-1
})

# 3/17（火）- 深刻な不足
create_shifts_for_day(Date.new(2026, 3, 17), {
  '001' => [{ code: 'E001', period: :am }],        # PM全員-1以上
  '002' => [{ code: 'E004', period: :pm }],        # AM全員-1以上
  '003' => [],                                      # 完全不足
  '004' => [],                                      # 完全不足
  '005' => [{ code: 'E012', period: :full_day }],  # 薬剤師-1, 事務-1
  '006' => []                                       # 完全不足
})

# 3/18（水）
create_shifts_for_day(Date.new(2026, 3, 18), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :am }          # PM薬剤師-1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :pm },
    { code: 'E006', period: :am }
  ],
  '003' => [],  # 水曜定休
  '004' => [{ code: 'E010', period: :full_day }],  # 事務-1
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E014', period: :am }
  ],
  '006' => [{ code: 'E015', period: :pm }]         # AM薬剤師-1
})

# 3/19（木）- 一部店舗に応援
create_shifts_for_day(Date.new(2026, 3, 19), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [{ code: 'E009', period: :full_day }],  # 薬剤師-1
  '004' => [{ code: 'E011', period: :full_day }],  # 薬剤師-1
  '005' => [
    { code: 'E014', period: :full_day }            # 薬剤師-2
  ],
  '006' => [{ code: 'E016', period: :full_day }]   # 薬剤師-1
})

# 3/20（金・祝）- 祝日対応
create_shifts_for_day(Date.new(2026, 3, 20), {
  '001' => [{ code: 'E001', period: :am }],
  '002' => [{ code: 'E004', period: :am }],
  '003' => [],
  '004' => [],
  '005' => [{ code: 'E012', period: :am }],
  '006' => []
})

# 3/21（土）
create_shifts_for_day(Date.new(2026, 3, 21), {
  '001' => [{ code: 'E001', period: :full_day }],  # 事務-1
  '002' => [{ code: 'E004', period: :full_day }],  # 薬剤師-1, 事務-1
  '003' => [],                                      # 不足
  '004' => [],                                      # 不足
  '005' => [{ code: 'E012', period: :full_day }],  # 薬剤師-1
  '006' => []                                       # 不足
})

# --- 第4週 (3/23-3/28): 繁忙期終盤 ---
puts "  3月第4週: 繁忙期終盤"

# 3/23（月）- 一部回復
create_shifts_for_day(Date.new(2026, 3, 23), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :am },
    { code: 'E007', period: :pm }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :am }
  ],
  '004' => [
    { code: 'E010', period: :pm },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :am },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :pm }
  ]
})

# 3/24（火）- さらに回復
create_shifts_for_day(Date.new(2026, 3, 24), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :am }          # PM事務-1
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :pm }          # AM事務-1
  ],
  '006' => [
    { code: 'E015', period: :am },         # PM薬剤師-1
    { code: 'E016', period: :full_day }
  ]
})

# 3/25（水）
create_shifts_for_day(Date.new(2026, 3, 25), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [],  # 水曜定休
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/26（木）- 完全充足
create_shifts_for_day(Date.new(2026, 3, 26), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/27（金）- 余剰傾向（年度末対応）
create_shifts_for_day(Date.new(2026, 3, 27), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'M001', period: :full_day },
    { code: 'E003', period: :full_day }        # 薬剤師+1
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/28（土）
create_shifts_for_day(Date.new(2026, 3, 28), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :am },
    { code: 'E009', period: :am }
  ],
  '004' => [
    { code: 'E010', period: :am },
    { code: 'E011', period: :am }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# --- 第5週 (3/30-3/31): 年度末 ---
puts "  3月第5週: 年度末"

# 3/30（月）- 最終週スタート
create_shifts_for_day(Date.new(2026, 3, 30), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :full_day },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :full_day },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :full_day }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :full_day }
  ],
  '004' => [
    { code: 'E010', period: :full_day },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :full_day },
    { code: 'E014', period: :full_day }
  ],
  '006' => [
    { code: 'E015', period: :full_day },
    { code: 'E016', period: :full_day }
  ]
})

# 3/31（火）- 年度末
create_shifts_for_day(Date.new(2026, 3, 31), {
  '001' => [
    { code: 'E001', period: :full_day },
    { code: 'E002', period: :am },
    { code: 'M001', period: :pm },
    { code: 'E003', period: :full_day }
  ],
  '002' => [
    { code: 'E004', period: :full_day },
    { code: 'E005', period: :am },
    { code: 'E006', period: :full_day },
    { code: 'E007', period: :pm }
  ],
  '003' => [
    { code: 'E008', period: :full_day },
    { code: 'E009', period: :am }
  ],
  '004' => [
    { code: 'E010', period: :pm },
    { code: 'E011', period: :full_day }
  ],
  '005' => [
    { code: 'E012', period: :full_day },
    { code: 'E013', period: :pm },
    { code: 'E014', period: :am }
  ],
  '006' => [
    { code: 'E015', period: :am },
    { code: 'E016', period: :pm }
  ]
})

puts ""
puts "=== Seed completed! ==="
puts ""
puts "ログイン情報:"
puts "  管理者: ADMIN"
puts "  エリアマネージャー: M001"
puts "  店舗管理者: E001, E004"
puts "  一般スタッフ: E002〜E016"
puts ""
