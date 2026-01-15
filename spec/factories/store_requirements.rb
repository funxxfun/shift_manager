FactoryBot.define do
  factory :store_requirement do
    association :store
    day_type { :weekday }
    pharmacist_count { 2 }
    clerk_count { 1 }

    trait :weekday do
      day_type { :weekday }
    end

    trait :saturday do
      day_type { :saturday }
    end

    trait :holiday do
      day_type { :holiday }
    end
  end
end
