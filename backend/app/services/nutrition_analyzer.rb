class NutritionAnalyzer
  def initialize
    @client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: ENV['GEMINI_API_KEY']
      },
      options: { model: 'gemini-1.5-flash', server_sent_events: true }
    )
  end

  def analyze_today_nutrition
    # 今日の食事データを取得
    today_entries = FoodEntry.today
    
    return { error: "今日の食事記録がありません" } if today_entries.empty?

    # プロンプト生成
    prompt = generate_prompt(today_entries)
    
    # Gemini API 呼び出し
    begin
      response = @client.stream_generate_content({ contents: { parts: { text: prompt } } })
      
      result = ""
      response.each do |chunk|
        result += chunk.dig('candidates', 0, 'content', 'parts', 0, 'text').to_s
      end
      
      { success: true, analysis: result }
    rescue => e
      { error: "AI分析でエラーが発生しました: #{e.message}" }
    end
  end

  private

  def generate_prompt(food_entries)
    # 合計カロリー・PFC計算
    total_calories = food_entries.sum(&:calories)
    total_protein = food_entries.sum(&:protein)
    total_fat = food_entries.sum(&:fat)
    total_carbs = food_entries.sum(&:carbs)

    # 食事リスト作成
    food_list = food_entries.map { |entry| "#{entry.food_name}(#{entry.calories}kcal)" }.join(", ")

    <<~PROMPT
      今日摂取した食事の栄養バランスを評価してください。

      【摂取した食事】
      #{food_list}

      【合計栄養素】
      - カロリー: #{total_calories}kcal
      - タンパク質: #{total_protein}g
      - 脂質: #{total_fat}g
      - 炭水化物: #{total_carbs}g

      【評価してほしい内容】
      1. 栄養バランスの評価（良い点・改善点）
      2. 不足している栄養素があれば指摘
      3. 今後の食事に対する具体的なアドバイス

      300文字程度で分かりやすく回答してください。
    PROMPT
  end
end