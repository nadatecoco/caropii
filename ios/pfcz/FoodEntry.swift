import Foundation

struct FoodEntry: Identifiable, Codable {
    let id: UUID
    let food: Food
    let date: Date
    
    init(id: UUID = UUID(), food: Food, date: Date = Date()) {
        self.id = id
        self.food = food
        self.date = date
    }
}