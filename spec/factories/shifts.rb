FactoryBot.define do
  factory :shift do
    date { Date.current }
    start_time { Time.zone.parse('09:00') }
    end_time { Time.zone.parse('18:00') }
    break_minutes { 60 }
    status { :scheduled }
    association :staff
    association :store

    trait :confirmed do
      status { :confirmed }
    end

    trait :support do
      status { :support }
    end
  end
end
