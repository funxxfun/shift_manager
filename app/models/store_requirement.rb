# app/models/store_requirement.rb
class StoreRequirement < ApplicationRecord
  belongs_to :store

  enum :shift_period, { am: 0, pm: 1 }

  validates :day_of_week, presence: true,
            inclusion: { in: 0..6 }
  validates :pharmacist_count, numericality: { greater_than_or_equal_to: 0 }
  validates :clerk_count, numericality: { greater_than_or_equal_to: 0 }
  validates :store_id, uniqueness: { scope: [:day_of_week, :shift_period] }

  DAY_NAMES = %w[日 月 火 水 木 金 土].freeze

  def day_name
    DAY_NAMES[day_of_week]
  end

  def shift_period_label
    case shift_period
    when 'am' then 'AM'
    when 'pm' then 'PM'
    end
  end

  def combined_label
    "#{day_name}曜 #{shift_period_label}"
  end
end
