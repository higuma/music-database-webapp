def option_numerical_range(min, max)
  { numericality: {
      greater_than_or_equal_to: min,
      less_than_or_equal_to: max
    }
  }
end

class Track < ActiveRecord::Base
  belongs_to :release

  validates :number, option_numerical_range(0, 99)
  validates :title, presence: true
  validates :seconds, option_numerical_range(0, 59)
  validates :minutes, option_numerical_range(0, 59)
end
