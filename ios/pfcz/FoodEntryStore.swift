
import Foundation

class FoodEntryStore: ObservableObject {
    @Published var entries: [FoodEntry] = []
    
    private let userDefaults = UserDefaults.standard
    private let entriesKey = "saved_food_entries"
    
    init() {
        loadEntries()
    }
    
    func add(food: Food) {
        let entry = FoodEntry(food: food)
        entries.append(entry)
        sortEntries()
        saveEntries()
    }
    
    func remove(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveEntries()
    }
    
    func remove(entry: FoodEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    // MARK: - Persistence Methods
    
    private func loadEntries() {
        guard let data = userDefaults.data(forKey: entriesKey) else {
            // 初回起動時は空のエントリー配列
            return
        }
        
        do {
            let savedEntries = try JSONDecoder().decode([FoodEntry].self, from: data)
            self.entries = savedEntries
            sortEntries()
        } catch {
            print("❌ Failed to load food entries: \(error)")
            // デコードに失敗した場合は空にリセット
            self.entries = []
        }
    }
    
    private func saveEntries() {
        do {
            let data = try JSONEncoder().encode(entries)
            userDefaults.set(data, forKey: entriesKey)
        } catch {
            print("❌ Failed to save food entries: \(error)")
        }
    }
    
    private func sortEntries() {
        entries.sort { $0.date > $1.date }
    }
    
    var todayEntries: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return entries.filter { entry in
            entry.date >= today && entry.date < tomorrow
        }
    }
    
    var todayTotalProtein: Double {
        todayEntries.reduce(0) { $0 + $1.food.protein }
    }
    
    var todayTotalFat: Double {
        todayEntries.reduce(0) { $0 + $1.food.fat }
    }
    
    var todayTotalCarbs: Double {
        todayEntries.reduce(0) { $0 + $1.food.carbs }
    }
    
    var todayTotalCalories: Double {
        todayEntries.reduce(0) { $0 + $1.food.calories }
    }
}

