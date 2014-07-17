class Artist < ActiveRecord::Base
  has_many :releases, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
