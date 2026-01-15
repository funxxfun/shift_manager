FactoryBot.define do
  factory :store do
    sequence(:code) { |n| "STORE#{n.to_s.rjust(3, '0')}" }
    sequence(:name) { |n| "テスト店舗#{n}" }
  end
end
