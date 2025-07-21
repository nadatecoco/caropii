import Foundation

struct Food: Identifiable, Codable {
    let id: UUID
    let name: String
    let protein: Double
    let fat: Double
    let carbs: Double
    let calories: Double
    
    init(id: UUID = UUID(), name: String, protein: Double, fat: Double, carbs: Double, calories: Double) {
        self.id = id
        self.name = name
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.calories = calories
    }
}