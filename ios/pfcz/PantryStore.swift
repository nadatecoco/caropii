import Foundation
import SwiftUI

// MARK: - 在庫管理ストア
class PantryStore: ObservableObject {
    @Published var items: [PantryItem] = []
    
    private let saveKey = "pantryItems"
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadItems()
    }
    
    // MARK: - データ永続化
    
    private func loadItems() {
        if let data = userDefaults.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([PantryItem].self, from: data) {
            items = decoded
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults.set(encoded, forKey: saveKey)
        }
    }
    
    // MARK: - CRUD操作
    
    // アイテムを追加（同名商品があれば数量を加算）
    func addItem(name: String, unit: String, quantity: Int) {
        if let index = items.firstIndex(where: { $0.name == name && $0.unit == unit }) {
            items[index].add(amount: quantity)
            items[index].addedAt = Date() // 追加日時を更新
        } else {
            let newItem = PantryItem(name: name, unit: unit, quantity: quantity)
            items.append(newItem)
        }
        saveItems()
    }
    
    // アイテムを消費
    func consumeItem(id: UUID, amount: Int) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].consume(amount: amount)
            
            // 在庫が0になったら削除（オプション）
            if items[index].quantity <= 0 {
                items.remove(at: index)
            }
            
            saveItems()
        }
    }
    
    // アイテムを削除
    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        saveItems()
    }
    
    // 失効したアイテムを削除
    func removeExpiredItems(daysUntilExpiration: Int = 7) {
        items.removeAll { $0.isExpired(daysUntilExpiration: daysUntilExpiration) }
        saveItems()
    }
    
    // MARK: - 検索・フィルタ
    
    // 在庫がある（quantity > 0）アイテムのみ取得
    func availableItems() -> [PantryItem] {
        items.filter { $0.quantity > 0 }
    }
    
    // 期限切れ間近のアイテム取得（残り日数でソート）
    func expiringItems(daysUntilExpiration: Int = 7, warningDays: Int = 2) -> [PantryItem] {
        availableItems()
            .filter { $0.daysRemaining(daysUntilExpiration: daysUntilExpiration) <= warningDays }
            .sorted { $0.daysRemaining(daysUntilExpiration: daysUntilExpiration) < $1.daysRemaining(daysUntilExpiration: daysUntilExpiration) }
    }
    
    // 名前で検索
    func searchItems(query: String) -> [PantryItem] {
        guard !query.isEmpty else { return availableItems() }
        
        return availableItems().filter { item in
            item.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - レシートOCR連携用（将来実装）
    
    // 複数アイテムを一括追加（レシートOCR後に使用）
    func addMultipleItems(_ items: [(name: String, unit: String, quantity: Int)]) {
        for item in items {
            addItem(name: item.name, unit: item.unit, quantity: item.quantity)
        }
    }
}