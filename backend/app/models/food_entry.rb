class FoodEntry < ApplicationRecord
  validates :food_name, presence: true
  validates :protein, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fat, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :carbs, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :calories, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :consumed_at, presence: true
  
  # 今日の食事記録を取得するスコープ
  scope :today, -> { where(consumed_at: Date.current.beginning_of_day..Date.current.end_of_day) }
end