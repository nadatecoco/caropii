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

  # 栄養分析実行
  def analyze_nutrition
    analyzer = NutritionAnalyzer.new
    result = analyzer.analyze_today_nutrition
    
    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: { analysis: result[:analysis] }, status: :ok
    end
  end
  
  private
  
  def food_entry_params
    params.require(:food_entry).permit(:food_name, :protein, :fat, :carbs, :calories, :consumed_at)
  end
end