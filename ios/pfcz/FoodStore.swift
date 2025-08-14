import Foundation

class FoodStore: ObservableObject {
    @Published var foods: [Food] = []
    
    private let userDefaults = UserDefaults.standard
    private let foodsKey = "saved_foods"
    
    init() {
        loadFoods()
    }
    
    // MARK: - Persistence Methods
    
    private func loadFoods() {
        guard let data = userDefaults.data(forKey: foodsKey) else {
            // 初回起動時はサンプルデータをロード
            setupSampleFoods()
            saveFoods() // サンプルデータを保存
            return
        }
        
        do {
            let savedFoods = try JSONDecoder().decode([Food].self, from: data)
            self.foods = savedFoods
        } catch {
            print("❌ Failed to load foods: \(error)")
            // デコードに失敗した場合はサンプルデータで復旧
            setupSampleFoods()
            saveFoods()
        }
    }
    
    private func saveFoods() {
        do {
            let data = try JSONEncoder().encode(foods)
            userDefaults.set(data, forKey: foodsKey)
        } catch {
            print("❌ Failed to save foods: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func addFood(_ food: Food) {
        foods.append(food)
        saveFoods()
    }
    
    func removeFood(at offsets: IndexSet) {
        foods.remove(atOffsets: offsets)
        saveFoods()
    }
    
    // MARK: - Sample Data
    
    private func setupSampleFoods() {
        foods = [
            // 肉類
            Food(name: "鶏胸肉", protein: 23.0, fat: 1.5, carbs: 0.0, calories: 108),
            Food(name: "鶏もも肉", protein: 18.0, fat: 14.0, carbs: 0.0, calories: 200),
            Food(name: "豚ロース", protein: 19.0, fat: 20.0, carbs: 0.0, calories: 263),
            Food(name: "牛肉", protein: 20.0, fat: 15.0, carbs: 0.0, calories: 224),
            Food(name: "サラダチキン", protein: 27.0, fat: 1.2, carbs: 0.3, calories: 108),
            
            // 魚類
            Food(name: "サーモン", protein: 25.0, fat: 12.0, carbs: 0.0, calories: 208),
            Food(name: "まぐろ", protein: 26.0, fat: 1.4, carbs: 0.0, calories: 125),
            Food(name: "さば", protein: 20.0, fat: 16.0, carbs: 0.0, calories: 247),
            
            // 穀物
            Food(name: "白米", protein: 2.5, fat: 0.5, carbs: 37.0, calories: 168),
            Food(name: "玄米", protein: 2.8, fat: 1.0, carbs: 35.6, calories: 165),
            Food(name: "パン", protein: 9.0, fat: 4.4, carbs: 46.0, calories: 264),
            Food(name: "うどん", protein: 2.6, fat: 0.4, carbs: 21.6, calories: 105),
            Food(name: "そば", protein: 4.8, fat: 0.7, carbs: 26.0, calories: 132),
            Food(name: "パスタ", protein: 5.4, fat: 0.9, carbs: 31.0, calories: 149),
            Food(name: "オートミール", protein: 13.7, fat: 5.7, carbs: 69.0, calories: 380),
            
            // 卵・乳製品
            Food(name: "卵", protein: 6.2, fat: 5.2, carbs: 0.2, calories: 76),
            Food(name: "牛乳", protein: 3.3, fat: 3.8, carbs: 4.8, calories: 67),
            Food(name: "ヨーグルト", protein: 3.6, fat: 3.0, carbs: 4.9, calories: 62),
            Food(name: "チーズ", protein: 22.7, fat: 26.0, carbs: 1.3, calories: 339),
            
            // 豆類
            Food(name: "納豆", protein: 8.0, fat: 5.0, carbs: 6.0, calories: 100),
            Food(name: "豆腐", protein: 6.6, fat: 4.2, carbs: 2.0, calories: 72),
            
            // 野菜
            Food(name: "ブロッコリー", protein: 3.0, fat: 0.4, carbs: 4.3, calories: 33),
            Food(name: "キャベツ", protein: 1.3, fat: 0.2, carbs: 5.2, calories: 23),
            Food(name: "トマト", protein: 0.9, fat: 0.2, carbs: 3.9, calories: 19),
            Food(name: "レタス", protein: 0.9, fat: 0.1, carbs: 2.8, calories: 12),
            Food(name: "きゅうり", protein: 1.0, fat: 0.1, carbs: 3.0, calories: 14),
            Food(name: "アボカド", protein: 2.5, fat: 18.7, carbs: 6.2, calories: 187),
            
            // 果物
            Food(name: "バナナ", protein: 1.1, fat: 0.2, carbs: 22.5, calories: 86),
            Food(name: "りんご", protein: 0.2, fat: 0.3, carbs: 15.5, calories: 61),
            Food(name: "みかん", protein: 0.7, fat: 0.1, carbs: 11.0, calories: 46),
            
            // 飲料
            Food(name: "コーヒー", protein: 0.2, fat: 0.0, carbs: 0.7, calories: 4),
            Food(name: "緑茶", protein: 0.2, fat: 0.0, carbs: 0.2, calories: 2),
            Food(name: "オレンジジュース", protein: 0.7, fat: 0.2, carbs: 10.0, calories: 45),
            Food(name: "コカコーラ", protein: 0.0, fat: 0.0, carbs: 11.0, calories: 45),
            Food(name: "プロテイン", protein: 20.0, fat: 1.0, carbs: 3.0, calories: 100)
        ]
    }
}