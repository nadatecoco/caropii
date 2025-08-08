import Foundation
import HealthKit

// アンカーストアのプロトコル定義
protocol AnchorStoreProtocol {
    func getAnchor(for typeIdentifier: String) -> HKQueryAnchor?
    func saveAnchor(_ anchor: HKQueryAnchor, for typeIdentifier: String)
    func deleteAnchor(for typeIdentifier: String)
    func deleteAllAnchors()
}

// Step1: ダミー実装（全取得のみ対応）
class DummyAnchorStore: AnchorStoreProtocol {
    func getAnchor(for typeIdentifier: String) -> HKQueryAnchor? {
        // 常にnilを返して全取得を強制
        return nil
    }
    
    func saveAnchor(_ anchor: HKQueryAnchor, for typeIdentifier: String) {
        // Step1では何もしない
        print("📌 アンカー保存（ダミー）: \(typeIdentifier)")
    }
    
    func deleteAnchor(for typeIdentifier: String) {
        // Step1では何もしない
        print("🗑️ アンカー削除（ダミー）: \(typeIdentifier)")
    }
    
    func deleteAllAnchors() {
        // Step1では何もしない
        print("🗑️ 全アンカー削除（ダミー）")
    }
}

// Step2で実装予定の本番用ストア
class RealAnchorStore: AnchorStoreProtocol {
    private let userDefaults = UserDefaults.standard
    private let anchorKeyPrefix = "healthkit.anchor."
    
    func getAnchor(for typeIdentifier: String) -> HKQueryAnchor? {
        let key = anchorKeyPrefix + typeIdentifier
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        do {
            let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
            return anchor
        } catch {
            print("❌ アンカー読み込みエラー: \(error)")
            return nil
        }
    }
    
    func saveAnchor(_ anchor: HKQueryAnchor, for typeIdentifier: String) {
        let key = anchorKeyPrefix + typeIdentifier
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            userDefaults.set(data, forKey: key)
            print("✅ アンカー保存成功: \(typeIdentifier)")
        } catch {
            print("❌ アンカー保存エラー: \(error)")
        }
    }
    
    func deleteAnchor(for typeIdentifier: String) {
        let key = anchorKeyPrefix + typeIdentifier
        userDefaults.removeObject(forKey: key)
        print("🗑️ アンカー削除: \(typeIdentifier)")
    }
    
    func deleteAllAnchors() {
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(anchorKeyPrefix) }
        keys.forEach { userDefaults.removeObject(forKey: $0) }
        print("🗑️ 全アンカー削除: \(keys.count)件")
    }
}