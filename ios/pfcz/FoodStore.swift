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
            Food(name: "鶏胸肉(100g)", protein: 23.0, fat: 1.5, carbs: 0.0, calories: 108),
            Food(name: "白米(150g)", protein: 3.8, fat: 0.5, carbs: 55.2, calories: 252),
            Food(name: "卵(1個)", protein: 6.2, fat: 5.2, carbs: 0.2, calories: 76),
            Food(name: "アボカド(1/2個)", protein: 2.0, fat: 15.0, carbs: 6.0, calories: 160),
            Food(name: "バナナ(1本)", protein: 1.1, fat: 0.2, carbs: 22.5, calories: 86),
            Food(name: "サーモン(100g)", protein: 25.0, fat: 12.0, carbs: 0.0, calories: 208),
            Food(name: "ブロッコリー(100g)", protein: 3.0, fat: 0.4, carbs: 4.3, calories: 25),
            Food(name: "オートミール(30g)", protein: 4.4, fat: 2.0, carbs: 20.7, calories: 114)
        ]
    }
}