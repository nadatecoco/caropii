import Foundation
import HealthKit

class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    private var anchorStore: AnchorStoreProtocol
    
    @Published var bodyMassRecords: [HealthDataRecord] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    // ISO8601フォーマッター
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    init(anchorStore: AnchorStoreProtocol = DummyAnchorStore()) {
        self.anchorStore = anchorStore
    }
    
    // MARK: - 権限リクエスト
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        // 体重データの読み取り権限をリクエスト
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [bodyMassType]
        let typesToWrite: Set<HKSampleType> = [] // 空のSetを指定
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    }
    
    // MARK: - 体重データ取得（Step1: 全取得のみ）
    func fetchBodyMass(days: Int = 30) async {
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }
        
        do {
            // 権限確認
            try await requestAuthorization()
            
            // 体重タイプ取得
            guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
                throw HealthKitError.dataTypeNotAvailable
            }
            
            // 期間設定（過去N日間）
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
            
            // クエリ作成
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
            
            // Step1: 通常のサンプルクエリで全取得
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: bodyMassType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples ?? [])
                    }
                }
                
                healthStore.execute(query)
            }
            
            // HealthDataRecordに変換
            let records = samples.compactMap { sample -> HealthDataRecord? in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                
                let value = quantitySample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                
                return HealthDataRecord(
                    type: .weight,
                    value: value,
                    unitString: "kg",
                    startDate: quantitySample.startDate,
                    endDate: quantitySample.endDate,
                    source: quantitySample.sourceRevision.source.name
                )
            }
            
            await MainActor.run {
                self.bodyMassRecords = records
                self.isLoading = false
                print("✅ 体重データ \(records.count)件取得完了")
            }
            
            // 日次サマリ生成
            await generateDailySummary(records: records)
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLoading = false
                print("❌ 体重データ取得エラー: \(error)")
            }
        }
    }
    
    // MARK: - 日次サマリ生成
    private func generateDailySummary(records: [HealthDataRecord]) async {
        // 日付ごとにグループ化（dayBoundaryHourを考慮）
        let calendar = Calendar.current
        var dailySummaries: [String: DailySummary] = [:]
        
        for record in records {
            // dayBoundaryHourを考慮した日付計算
            var adjustedDate = record.startDate
            let hour = calendar.component(.hour, from: adjustedDate)
            if hour < dayBoundaryHour {
                // 午前4時より前なら前日扱い
                adjustedDate = calendar.date(byAdding: .day, value: -1, to: adjustedDate) ?? adjustedDate
            }
            
            let dateKey = dateKeyFormatter.string(from: adjustedDate)
            
            if dailySummaries[dateKey] == nil {
                dailySummaries[dateKey] = DailySummary(date: dateKey, bodyMass: [])
            }
            
            dailySummaries[dateKey]?.bodyMass.append(
                BodyMassEntry(
                    value: record.value,
                    unit: record.unitString,
                    timestamp: isoFormatter.string(from: record.startDate)
                )
            )
        }
        
        // JSON保存
        await saveDailySummaries(dailySummaries)
    }
    
    // 日付キー用フォーマッター
    private let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - サマリ保存
    private func saveDailySummaries(_ summaries: [String: DailySummary]) async {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let summaryDirectory = documentsDirectory.appendingPathComponent("HealthSummaries")
        
        // ディレクトリ作成
        try? FileManager.default.createDirectory(at: summaryDirectory, withIntermediateDirectories: true)
        
        // 各日付のサマリを保存
        for (dateKey, summary) in summaries {
            let fileName = "\(dateKey).json"
            let fileURL = summaryDirectory.appendingPathComponent(fileName)
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(summary)
                try data.write(to: fileURL)
                print("📁 サマリ保存: \(fileName)")
            } catch {
                print("❌ サマリ保存エラー: \(error)")
            }
        }
    }
    
    // MARK: - 全データ削除（全再取得用）
    func deleteAllLocalData() async {
        // アンカー削除
        anchorStore.deleteAllAnchors()
        
        // ローカルJSON削除
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let summaryDirectory = documentsDirectory.appendingPathComponent("HealthSummaries")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: summaryDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            print("🗑️ 全ローカルデータ削除完了")
        } catch {
            print("❌ ローカルデータ削除エラー: \(error)")
        }
        
        // メモリクリア
        await MainActor.run {
            self.bodyMassRecords = []
        }
        
        // 即座に全取得
        await fetchBodyMass()
    }
}

// MARK: - エラー定義
enum HealthKitError: LocalizedError {
    case notAvailable
    case dataTypeNotAvailable
    case noData
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKitが利用できません"
        case .dataTypeNotAvailable:
            return "データタイプが利用できません"
        case .noData:
            return "データがありません"
        }
    }
}

// MARK: - 日次サマリ構造体
struct DailySummary: Codable {
    let date: String // "yyyy-MM-dd"
    var bodyMass: [BodyMassEntry]
    // 将来的に睡眠、運動などを追加
}

struct BodyMassEntry: Codable {
    let value: Double
    let unit: String
    let timestamp: String // ISO8601形式
}