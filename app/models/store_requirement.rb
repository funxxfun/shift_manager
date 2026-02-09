# app/models/store_requirement.rb
class StoreRequirement < ApplicationRecord
  belongs_to :store

  enum :day_type, { weekday: 0, saturday: 1, holiday: 2 }
  enum :shift_period, { am: 0, pm: 1, full_day: 2 }

  validates :day_type, presence: true
  validates :pharmacist_count, numericality: { greater_than_or_equal_to: 0 }
  validates :clerk_count, numericality: { greater_than_or_equal_to: 0 }
  validates :store_id, uniqueness: { scope: [:day_type, :shift_period] }

  def day_type_label
    case day_type
    when 'weekday' then '平日'
    when 'saturday' then '土曜'
    when 'holiday' then '日祝'
    end
  end

  def shift_period_label
    case shift_period
    when 'am' then 'AM'
    when 'pm' then 'PM'
    when 'full_day' then '終日'
    end
  end

  def combined_label
    "#{day_type_label} #{shift_period_label}"
  end
end
