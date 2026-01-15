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
  { code: 'E001', name: '山田太郎', role: :pharmacist, store_code: '001' },
  { code: 'E002', name: '佐藤花子', role: :pharmacist, store_code: '001' },
  { code: 'E003', name: '鈴木一郎', role: :clerk, store_code: '001' },
  { code: 'E004', name: '田中美咲', role: :pharmacist, store_code: '002' },
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
  staff = Staff.find_or_initialize_by(code: data[:code])
  staff.name = data[:name]
  staff.role = data[:role]
  staff.base_store = store
  staff.password = 'password123' if staff.new_record? || staff.password_digest.blank?
  staff.save!
  puts "  Created: #{data[:name]}"
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

# 2026年2月のサンプルシフト
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
