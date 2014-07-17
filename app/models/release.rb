class Release < ActiveRecord::Base
  belongs_to :artist
  has_many :tracks, dependent: :destroy

  validates :title, presence: true
  validates :year, numericality: {
    greater_than_or_equal_to: 1900,
    less_than_or_equal_to: Time.now.year + 1
  }
end
