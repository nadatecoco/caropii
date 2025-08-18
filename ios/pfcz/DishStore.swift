import Foundation
import SwiftUI

// MARK: - 料理データ管理ストア
class DishStore: ObservableObject {
    @Published var dishes: [Dish] = []
    
    private let saveKey = "dishes"
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadDishes()
    }
    
    // MARK: - データ永続化
    
    private func loadDishes() {
        if let data = userDefaults.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Dish].self, from: data) {
            dishes = decoded
        }
    }
    
    private func saveDishes() {
        if let encoded = try? JSONEncoder().encode(dishes) {
            userDefaults.set(encoded, forKey: saveKey)
        }
    }
    
    // MARK: - 料理の作成
    
    // 在庫から料理を作成（PantryStoreと連携）
    func createDish(name: String, 
                   totalWeight: Double,
                   ingredients: [Ingredient],
                   pantryStore: PantryStore) {
        
        // 新しい料理を作成
        let newDish = Dish(
            name: name,
            totalWeight: totalWeight,
            ingredients: ingredients
        )
        
        // 料理リストに追加
        dishes.append(newDish)
        
        // 在庫から材料を消費（調味料以外）
        for ingredient in ingredients where ingredient.isFromPantry {
            // 材料名で在庫を検索して消費
            if let pantryItem = pantryStore.items.first(where: { $0.name == ingredient.name }) {
                let consumeAmount = Int(ingredient.amount ?? 0)
                pantryStore.consumeItem(id: pantryItem.id, amount: consumeAmount)
            }
        }
        
        saveDishes()
    }
    
    // MARK: - 料理の消費
    
    // 料理を部分的に消費（200g食べた等）
    func consumeDish(dishId: UUID, amount: Double) -> Nutrition? {
        guard let index = dishes.firstIndex(where: { $0.id == dishId }) else {
            return nil
        }
        
        // 消費前に栄養計算
        let nutrition = dishes[index].calculateNutrition(for: amount)
        
        // 残量を減らす
        dishes[index].consume(amount: amount)
        
        // 残量が0になったら削除
        if dishes[index].isEmpty {
            dishes.remove(at: index)
        }
        
        saveDishes()
        return nutrition
    }
    
    // MARK: - 料理の検索・取得
    
    // 利用可能な料理（残量がある）を取得
    func availableDishes() -> [Dish] {
        dishes.filter { !$0.isEmpty }
    }
    
    // 料理を名前で検索
    func searchDishes(query: String) -> [Dish] {
        guard !query.isEmpty else { return availableDishes() }
        
        return availableDishes().filter { dish in
            dish.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    // 作成日でソート（新しい順）
    func recentDishes() -> [Dish] {
        availableDishes().sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - 料理の削除
    
    // 特定の料理を削除
    func deleteDish(dishId: UUID) {
        dishes.removeAll { $0.id == dishId }
        saveDishes()
    }
    
    // 空の料理を全て削除
    func removeEmptyDishes() {
        dishes.removeAll { $0.isEmpty }
        saveDishes()
    }
    
    // MARK: - レシピ機能（将来実装用）
    
    // レシピとして保存されている料理を取得
    func getRecipes() -> [Dish] {
        dishes.filter { $0.isRecipe }
    }
    
    // レシピから料理を再作成（将来実装）
    func createFromRecipe(recipeId: UUID, pantryStore: PantryStore) -> Bool {
        guard dishes.first(where: { $0.id == recipeId && $0.isRecipe }) != nil else {
            return false
        }
        
        // TODO: 在庫チェックして、足りない材料をリストアップ
        // TODO: 材料が揃っていれば自動で料理作成
        
        return true
    }
}