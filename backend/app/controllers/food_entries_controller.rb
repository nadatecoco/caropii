class FoodEntriesController < ApplicationController
  # iOS からの食事データ受信
  def create
    @food_entry = FoodEntry.new(food_entry_params)
    
    if @food_entry.save
      render json: @food_entry, status: :created
    else
      render json: { errors: @food_entry.errors }, status: :unprocessable_entity
    end
  end
  
  # 今日の食事データ一覧取得
  def today
    @food_entries = FoodEntry.today
    render json: @food_entries
  end
  
  private
  
  def food_entry_params
    params.require(:food_entry).permit(:food_name, :protein, :fat, :carbs, :calories, :consumed_at)
  end
end