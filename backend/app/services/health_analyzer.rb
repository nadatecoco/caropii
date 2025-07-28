class HealthAnalyzer
  def initialize
    @client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: ENV['GEMINI_API_KEY']
      },
      options: { model: 'gemini-1.5-flash', server_sent_events: true }
    )
  end

  # 統合分析メソッド（type指定）
  def analyze(type, data = nil)
    case type
    when "nutrition"
      analyze_nutrition
    when "sleep"
      analyze_sleep(data)
    else
      { error: "無効なタイプです。'nutrition' または 'sleep' を指定してください。" }
    end
  end

  # 栄養分析（従来の機能）
  def analyze_nutrition
    # 今日の食事データを取得
    today_entries = FoodEntry.today
    
    return { error: "今日の食事記録がありません" } if today_entries.empty?

    # プロンプト生成
    prompt = generate_nutrition_prompt(today_entries)
    
    # Gemini API 呼び出し
    call_gemini_api(prompt)
  end

  # 睡眠分析（新機能）
  def analyze_sleep(sleep_data)
    return { error: "睡眠データが提供されていません" } if sleep_data.blank?

    # プロンプト生成
    prompt = generate_sleep_prompt(sleep_data)
    
    # Gemini API 呼び出し
    call_gemini_api(prompt)
  end

  # 従来のメソッド名も残す（互換性のため）
  def analyze_today_nutrition
    analyze_nutrition
  end

  private

  # 共通のGemini API呼び出し処理
  def call_gemini_api(prompt)
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

  def generate_nutrition_prompt(food_entries)
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

  def generate_sleep_prompt(sleep_data)
    <<~PROMPT
      以下の睡眠データを分析して、睡眠の質や改善点について評価してください。

      【睡眠データ】
      #{sleep_data.map { |d| "日付: #{d[:date]}, 睡眠時間: #{d[:duration]}時間, 寝付き時間: #{d[:fall_asleep_time]}分, 睡眠効率: #{d[:efficiency]}%" }.join("\n")}

      【評価してほしい内容】
      1. 睡眠時間・質の評価
      2. 改善すべき点があれば指摘
      3. より良い睡眠のための具体的なアドバイス

      300文字程度で分かりやすく回答してください。
    PROMPT
  end
end