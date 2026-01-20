# db/seeds.rb

puts "Creating stores..."

stores_data = [
  { code: '001', name: '博多駅前店', weekday: [2, 1], saturday: [1, 1] },
  { code: '002', name: '天神店', weekday: [2, 2], saturday: [1, 1] },
  { code: '003', name: '六本松店', weekday: [1, 1], saturday: [1, 1] },
  { code: '004', name: '薬院店', weekday: [1, 1], saturday: [1, 1] },
  { code: '005', name: '大橋店', weekday: [2, 1], saturday: [1, 1] },
  { code: '006', name: '西新店', weekday: [1, 1], saturday: [1, 1] },
]

stores_data.each do |data|
  store = Store.find_or_create_by!(code: data[:code]) do |s|
    s.name = data[:name]
  end

  # 必要人数を設定
  StoreRequirement.find_or_create_by!(store: store, day_type: :weekday) do |r|
    r.pharmacist_count = data[:weekday][0]
    r.clerk_count = data[:weekday][1]
  end

  StoreRequirement.find_or_create_by!(store: store, day_type: :saturday) do |r|
    r.pharmacist_count = data[:saturday][0]
    r.clerk_count = data[:saturday][1]
  end

  StoreRequirement.find_or_create_by!(store: store, day_type: :holiday) do |r|
    r.pharmacist_count = 0
    r.clerk_count = 0
  end

  puts "  Created: #{store.name}"
end

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
  puts "  Created: #{data[:name]} (#{data[:permission_level] || 'staff'})"
end

# シフト作成用ヘルパー
def create_shifts(date, assignments)
  assignments.each do |store_code, staff_codes|
    store = Store.find_by(code: store_code)

    staff_codes.each do |staff_code|
      staff = Staff.find_by(code: staff_code)

      Shift.find_or_create_by!(date: date, staff: staff) do |s|
        s.store = store
        s.start_time = "09:00"
        s.end_time = "18:00"
        s.break_minutes = 60
      end
    end
  end
end

puts "Creating sample shifts..."

# ==============================
# 2026年1月20日〜31日（AI提案テスト用）
# ==============================
puts "Creating January shifts for AI suggestion testing..."

# 1/20（火）- 大幅な不足（複数店舗で薬剤師不足）
create_shifts(Date.new(2026, 1, 20), {
  "001" => %w[E003],                    # 薬-2 事0（深刻な薬剤師不足）
  "002" => %w[E006 E007],               # 薬-2 事0（薬剤師ゼロ）
  "003" => %w[E008 E009],               # ちょうど
  "004" => %w[E010 E011],               # ちょうど
  "005" => %w[E012 E013 E014],          # ちょうど
  "006" => %w[E015 E016],               # ちょうど
})
puts "  1/20: 博多・天神で薬剤師不足"

# 1/21（水）- 余剰店舗から不足店舗へ補填可能なパターン
create_shifts(Date.new(2026, 1, 21), {
  "001" => %w[E001 E002 E003 M001],     # 薬+1（余剰あり）
  "002" => %w[E004 E005 E006 E007],     # ちょうど
  "003" => %w[E009],                    # 薬-1 事0（不足）
  "004" => %w[E011],                    # 薬-1 事0（不足）
  "005" => %w[E012 E013 E014],          # ちょうど
  "006" => %w[E015 E016 E008],          # 薬+1（E008応援で余剰）
})
puts "  1/21: 博多・西新が余剰、六本松・薬院が不足"

# 1/22（木）- 事務スタッフ不足パターン
create_shifts(Date.new(2026, 1, 22), {
  "001" => %w[E001 E002],               # 薬0 事-1
  "002" => %w[E004 E005],               # 薬0 事-2
  "003" => %w[E008],                    # 薬0 事-1
  "004" => %w[E010 E011],               # ちょうど
  "005" => %w[E012 E013 E014],          # ちょうど
  "006" => %w[E015 E016 E003 E006],     # 事+2（事務余剰）
})
puts "  1/22: 複数店舗で事務不足、西新で事務余剰"

# 1/23（金）- 全店舗で軽微な不足
create_shifts(Date.new(2026, 1, 23), {
  "001" => %w[E001 E003],               # 薬-1
  "002" => %w[E004 E006],               # 薬-1 事-1
  "003" => %w[E009],                    # 薬-1
  "004" => %w[E010],                    # 事-1
  "005" => %w[E012 E014],               # 薬-1
  "006" => %w[E015],                    # 事-1
})
puts "  1/23: 全店舗で軽微な不足"

# 1/24（土）- 土曜シフト（必要人数が少ない）
create_shifts(Date.new(2026, 1, 24), {
  "001" => %w[E001 E002 E003],          # 薬+1（土曜は薬1事1なので余剰）
  "002" => %w[E004 E005 E006],          # 薬+1 事+1（余剰）
  "003" => %w[E008],                    # 薬0 事-1
  "004" => %w[E011],                    # 薬-1 事0
  "005" => %w[E012 E014],               # 薬0 事0（ちょうど...薬1事1）
  "006" => %w[E015],                    # 薬0 事-1
})
puts "  1/24（土）: 博多・天神が余剰、他店舗で微不足"

# 1/25（日・祝）- 日祝は必要人数0なので全員余剰
create_shifts(Date.new(2026, 1, 25), {
  "001" => %w[E001],                    # 余剰
  "002" => %w[E004],                    # 余剰
  "003" => %w[],                        # なし
  "004" => %w[],                        # なし
  "005" => %w[E012],                    # 余剰
  "006" => %w[],                        # なし
})
puts "  1/25（日）: 日祝シフト"

# 1/26（月）- バランス良好
create_shifts(Date.new(2026, 1, 26), {
  "001" => %w[E001 E002 E003],          # ちょうど
  "002" => %w[E004 E005 E006 E007],     # ちょうど
  "003" => %w[E008 E009],               # ちょうど
  "004" => %w[E010 E011],               # ちょうど
  "005" => %w[E012 E013 E014],          # ちょうど
  "006" => %w[E015 E016],               # ちょうど
})
puts "  1/26: バランス良好（過不足なし）"

# 1/27（火）- 大規模な偏り（一部店舗に集中）
create_shifts(Date.new(2026, 1, 27), {
  "001" => %w[E001 E002 E003 E008 E010 E015], # 薬+3（大幅余剰）
  "002" => %w[E004 E005 E006 E007],     # ちょうど
  "003" => %w[E009],                    # 薬-1 事0
  "004" => %w[E011],                    # 薬-1 事0
  "005" => %w[E014],                    # 薬-2 事0
  "006" => %w[E016],                    # 薬-1 事0
})
puts "  1/27: 博多駅前に集中、他店舗で薬剤師不足"

# 1/28（水）- 事務過剰・薬剤師不足
create_shifts(Date.new(2026, 1, 28), {
  "001" => %w[E003 E009 E011],          # 薬-2 事+2
  "002" => %w[E006 E007 E014 E016],     # 薬-2 事+2
  "003" => %w[E008],                    # 薬0 事-1
  "004" => %w[E010],                    # 薬0 事-1
  "005" => %w[E012 E013],               # 薬0 事-1
  "006" => %w[E015],                    # 薬0 事-1
})
puts "  1/28: 博多・天神で事務過剰＆薬剤師不足"

# 1/29（木）- 薬剤師のみ大幅余剰
create_shifts(Date.new(2026, 1, 29), {
  "001" => %w[E001 E002 E003 E004],     # 薬+1
  "002" => %w[E005 E006 E007 E008],     # 薬+1（E008応援）
  "003" => %w[E010 E009],               # 薬+1（E010応援）
  "004" => %w[E011],                    # 薬-1 事0
  "005" => %w[E012 E013 E014 E015],     # 薬+1（E015応援）
  "006" => %w[E016],                    # 薬-1 事0
})
puts "  1/29: 薬剤師余剰、薬院・西新で不足"

# 1/30（金）- 複雑な過不足パターン
create_shifts(Date.new(2026, 1, 30), {
  "001" => %w[E002 E003],               # 薬-1 事0
  "002" => %w[E004 E005 E006],          # 薬0 事-1
  "003" => %w[E008 E009 E001],          # 薬+1（E001応援で余剰）
  "004" => %w[E010 E011 E015],          # 薬+1（E015応援で余剰）
  "005" => %w[E013],                    # 薬-1 事-1
  "006" => %w[E016],                    # 薬-1 事0
})
puts "  1/30: 六本松・薬院が余剰、他店舗で不足"

# 1/31（土）- 土曜の偏り
create_shifts(Date.new(2026, 1, 31), {
  "001" => %w[E001 E002 E003],          # 薬+1 事0（土曜）
  "002" => %w[E004],                    # 薬0 事-1
  "003" => %w[],                        # 薬-1 事-1（誰もいない）
  "004" => %w[E010 E011],               # 薬0 事0
  "005" => %w[E012 E013 E014],          # 薬+1 事+1
  "006" => %w[],                        # 薬-1 事-1（誰もいない）
})
puts "  1/31（土）: 六本松・西新が完全不足"

# ==============================
# 2026年2月のサンプルシフト
# ==============================
base_date = Date.new(2026, 2, 3) # 火曜日

5.times do |day_offset|
  date = base_date + day_offset
  puts "  Creating shifts for #{date}..."

  case day_offset
  when 0
    # 2/3 - 余剰あり（過剰スタッフ発生）
    # 001: 必要(薬2 事1) → 薬3 事1 で薬剤師が余剰
    # 002: 必要(薬2 事2) → 薬3 事2 で薬剤師が余剰
    create_shifts(date, {
      "001" => %w[E001 E002 E003 E004], # E004を応援で入れて薬剤師+1
      "002" => %w[E005 E006 E007 E008], # E008を応援で入れて薬剤師+1
      "003" => %w[E009],                # 不足（薬1事1に対して事務のみ）
      "004" => %w[E010],                # 不足（薬1事1に対して薬剤師のみ）
      "005" => %w[E012 E014],            # 不足（薬2事1に対して薬-1）
      "006" => %w[E015 E016],            # ちょうど
    })

  when 1
    # 2/4 - 不足多め
    create_shifts(date, {
      "001" => %w[E001 E003],            # 薬剤師-1
      "002" => %w[E005 E006],            # 薬剤師-1 & 事務-1
      "003" => %w[E008],                 # 事務-1
      "004" => %w[E010 E011],
      "005" => %w[E012],                 # 薬剤師-1 事務-1
      "006" => %w[E015 E016],
    })

  when 2
    # 2/5 - 一部不足
    create_shifts(date, {
      "001" => %w[E001 E002 E003],
      "002" => %w[E004 E005 E006],       # 事務-1
      "003" => %w[E008 E009],
      "004" => %w[E010 E011],
      "005" => %w[E013 E014],            # 薬剤師-1
      "006" => %w[E015 E016],
    })

  else
    # 2/6, 2/7 - ほぼ正常（不足なしに近い）
    create_shifts(date, {
      "001" => %w[E001 E002 E003],
      "002" => %w[E004 E005 E006 E007],
      "003" => %w[E008 E009],
      "004" => %w[E010 E011],
      "005" => %w[E012 E013 E014],
      "006" => %w[E015 E016],
    })
  end
end

puts "Seed completed!"
