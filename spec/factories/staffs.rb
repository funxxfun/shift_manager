FactoryBot.define do
  factory :staff do
    sequence(:code) { |n| "EMP#{n.to_s.rjust(4, '0')}" }
    sequence(:name) { |n| "テストスタッフ#{n}" }
    password { 'password123' }
    role { :pharmacist }
    association :base_store, factory: :store

    trait :pharmacist do
      role { :pharmacist }
    end

    trait :clerk do
      role { :clerk }
    end
  end
end
