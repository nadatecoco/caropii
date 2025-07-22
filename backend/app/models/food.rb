class Food < ApplicationRecord
  validates :name, presence: true
  validates :protein, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fat, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :carbs, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :calories, presence: true, numericality: { greater_than_or_equal_to: 0 }
end