import Foundation

// MARK: - 在庫アイテムモデル
struct PantryItem: Identifiable, Codable {
    let id: UUID
    var name: String        // 商品名
    var unit: String        // 単位（g/ml/個/本）
    var quantity: Int       // 在庫量
    var addedAt: Date       // 追加日時（失効計算用）
    
    init(id: UUID = UUID(), name: String, unit: String, quantity: Int, addedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.unit = unit
        self.quantity = quantity
        self.addedAt = addedAt
    }
    
    // 失効判定（デフォルト7日）
    func isExpired(daysUntilExpiration: Int = 7) -> Bool {
        let expirationDate = addedAt.addingTimeInterval(TimeInterval(daysUntilExpiration * 24 * 60 * 60))
        return Date() > expirationDate
    }
    
    // ソフト失効（期限切れても灰色表示で残す）
    func daysRemaining(daysUntilExpiration: Int = 7) -> Int {
        let expirationDate = addedAt.addingTimeInterval(TimeInterval(daysUntilExpiration * 24 * 60 * 60))
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return max(0, remaining)
    }
    
    // 在庫の減算（0以下にならないように）
    mutating func consume(amount: Int) {
        quantity = max(0, quantity - amount)
    }
    
    // 在庫の追加
    mutating func add(amount: Int) {
        quantity += amount
    }
}