import Foundation
import HealthKit

class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    private var anchorStore: AnchorStoreProtocol
    
    @Published var bodyMassRecords: [HealthDataRecord] = []
    @Published var sleepRecords: [HealthDataRecord] = []
    @Published var activityRecords: [HealthDataRecord] = []  // 活動データ（歩数、カロリー、心拍、HRV）
    @Published var workoutRecords: [WorkoutData] = []       // ワークアウトデータ
    @Published var isLoading = false
    @Published var lastError: String?
    
    // ISO8601フォーマッター
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    init(anchorStore: AnchorStoreProtocol = RealAnchorStore()) {
        self.anchorStore = anchorStore
    }
    
    // MARK: - 権限リクエスト
    func requestAuthorization(for types: [HKObjectType]? = nil) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        var typesToRead: Set<HKObjectType> = []
        
        if let specificTypes = types {
            typesToRead = Set(specificTypes)
        } else {
            // デフォルトで全データタイプの権限をリクエスト
            if let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
                typesToRead.insert(bodyMassType)
            }
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                typesToRead.insert(sleepType)
            }
            if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
                typesToRead.insert(stepType)
            }
            if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                typesToRead.insert(activeEnergyType)
            }
            if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
                typesToRead.insert(heartRateType)
            }
            if let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
                typesToRead.insert(restingHeartRateType)
            }
            if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
                typesToRead.insert(hrvType)
            }
            if let exerciseTimeType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
                typesToRead.insert(exerciseTimeType)
            }
            typesToRead.insert(HKObjectType.workoutType())
        }
        
        let typesToWrite: Set<HKSampleType> = [] // 空のSetを指定
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    }
    
    // MARK: - 体重データ取得（Step2: 増分同期対応）
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
            
            // 保存されたアンカーを取得
            let typeIdentifier = HKQuantityTypeIdentifier.bodyMass.rawValue
            let savedAnchor = anchorStore.getAnchor(for: typeIdentifier)
            
            // 期間設定（アンカーがない場合は過去N日間）
            let predicate: NSPredicate?
            if savedAnchor == nil {
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
                predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
                print("📌 初回取得: 過去\(days)日間のデータを取得")
            } else {
                predicate = nil // アンカーがある場合は期間指定不要
                print("📌 増分取得: アンカー以降のデータを取得")
            }
            
            // HKAnchoredObjectQueryで取得
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(samples: [HKSample], newAnchor: HKQueryAnchor?), Error>) in
                let query = HKAnchoredObjectQuery(
                    type: bodyMassType,
                    predicate: predicate,
                    anchor: savedAnchor,
                    limit: HKObjectQueryNoLimit
                ) { _, addedSamples, deletedSamples, newAnchor, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        // 削除されたサンプルの処理（今回は無視）
                        if let deleted = deletedSamples, !deleted.isEmpty {
                            print("⚠️ 削除されたサンプル: \(deleted.count)件")
                        }
                        continuation.resume(returning: (samples: addedSamples ?? [], newAnchor: newAnchor))
                    }
                }
                
                healthStore.execute(query)
            }
            
            // 新しいアンカーを保存
            if let newAnchor = result.newAnchor {
                anchorStore.saveAnchor(newAnchor, for: typeIdentifier)
            }
            
            // HealthDataRecordに変換
            let newRecords = result.samples.compactMap { sample -> HealthDataRecord? in
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
            
            // 既存のレコードと統合（増分同期の場合）
            if savedAnchor != nil && !bodyMassRecords.isEmpty {
                // 新しいデータを追加（重複チェック）
                let existingIds = Set(bodyMassRecords.map { "\($0.startDate)-\($0.value)" })
                let filteredNewRecords = newRecords.filter { record in
                    !existingIds.contains("\(record.startDate)-\(record.value)")
                }
                
                await MainActor.run {
                    self.bodyMassRecords.append(contentsOf: filteredNewRecords)
                    self.bodyMassRecords.sort { $0.startDate > $1.startDate }
                    self.isLoading = false
                    print("✅ 新規データ \(filteredNewRecords.count)件追加（合計: \(self.bodyMassRecords.count)件）")
                }
            } else {
                // 初回取得
                await MainActor.run {
                    self.bodyMassRecords = newRecords.sorted { $0.startDate > $1.startDate }
                    self.isLoading = false
                    print("✅ 体重データ \(newRecords.count)件取得完了")
                }
            }
            
            // 日次サマリ生成
            await generateDailySummary(records: bodyMassRecords)
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLoading = false
                print("❌ 体重データ取得エラー: \(error)")
            }
        }
    }
    
    // MARK: - 睡眠データ取得（増分同期対応）
    func fetchSleepData(days: Int = 30) async {
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }
        
        do {
            // 権限確認
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                try await requestAuthorization(for: [sleepType])
            }
            
            // 睡眠タイプ取得
            guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
                throw HealthKitError.dataTypeNotAvailable
            }
            
            // 保存されたアンカーを取得
            let typeIdentifier = HKCategoryTypeIdentifier.sleepAnalysis.rawValue
            let savedAnchor = anchorStore.getAnchor(for: typeIdentifier)
            
            // 期間設定
            let predicate: NSPredicate?
            if savedAnchor == nil {
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
                predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
                print("📌 初回取得: 過去\(days)日間の睡眠データを取得")
            } else {
                predicate = nil
                print("📌 増分取得: アンカー以降の睡眠データを取得")
            }
            
            // HKAnchoredObjectQueryで取得
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(samples: [HKSample], newAnchor: HKQueryAnchor?), Error>) in
                let query = HKAnchoredObjectQuery(
                    type: sleepType,
                    predicate: predicate,
                    anchor: savedAnchor,
                    limit: HKObjectQueryNoLimit
                ) { _, addedSamples, deletedSamples, newAnchor, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        if let deleted = deletedSamples, !deleted.isEmpty {
                            print("⚠️ 削除された睡眠サンプル: \(deleted.count)件")
                        }
                        continuation.resume(returning: (samples: addedSamples ?? [], newAnchor: newAnchor))
                    }
                }
                
                healthStore.execute(query)
            }
            
            // 新しいアンカーを保存
            if let newAnchor = result.newAnchor {
                anchorStore.saveAnchor(newAnchor, for: typeIdentifier)
            }
            
            // HealthDataRecordに変換
            let newRecords = result.samples.compactMap { sample -> HealthDataRecord? in
                guard let categorySample = sample as? HKCategorySample else { return nil }
                
                // 睡眠の種類を判定
                let sleepValue = categorySample.value
                let sleepType: HealthDataType
                
                switch sleepValue {
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    sleepType = .sleepInBed
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    sleepType = .sleepAsleep
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    sleepType = .sleepAwake
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    sleepType = .sleepREM
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    sleepType = .sleepDeep
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    sleepType = .sleepCore
                default:
                    sleepType = .sleepAsleep
                }
                
                // 睡眠時間を時間単位で計算
                let duration = categorySample.endDate.timeIntervalSince(categorySample.startDate) / 3600
                
                return HealthDataRecord(
                    type: sleepType,
                    value: duration,
                    unitString: "時間",
                    startDate: categorySample.startDate,
                    endDate: categorySample.endDate,
                    source: categorySample.sourceRevision.source.name
                )
            }
            
            // 既存のレコードと統合
            if savedAnchor != nil && !sleepRecords.isEmpty {
                let existingIds = Set(sleepRecords.map { "\($0.startDate)-\($0.type)" })
                let filteredNewRecords = newRecords.filter { record in
                    !existingIds.contains("\(record.startDate)-\(record.type)")
                }
                
                await MainActor.run {
                    self.sleepRecords.append(contentsOf: filteredNewRecords)
                    self.sleepRecords.sort { $0.startDate > $1.startDate }
                    self.isLoading = false
                    print("✅ 新規睡眠データ \(filteredNewRecords.count)件追加（合計: \(self.sleepRecords.count)件）")
                }
            } else {
                await MainActor.run {
                    self.sleepRecords = newRecords.sorted { $0.startDate > $1.startDate }
                    self.isLoading = false
                    print("✅ 睡眠データ \(newRecords.count)件取得完了")
                }
            }
            
            // 睡眠サマリ生成
            await generateSleepSummary(records: sleepRecords)
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLoading = false
                print("❌ 睡眠データ取得エラー: \(error)")
            }
        }
    }
    
    // MARK: - 睡眠サマリ生成
    private func generateSleepSummary(records: [HealthDataRecord]) async {
        // 日付ごとにグループ化
        let calendar = Calendar.current
        var dailySleepSummaries: [String: SleepSummary] = [:]
        
        for record in records {
            // 睡眠は終了時刻の日付で集計
            var adjustedDate = record.endDate ?? record.startDate
            let hour = calendar.component(.hour, from: adjustedDate)
            if hour < dayBoundaryHour {
                adjustedDate = calendar.date(byAdding: .day, value: -1, to: adjustedDate) ?? adjustedDate
            }
            
            let dateKey = dateKeyFormatter.string(from: adjustedDate)
            
            if dailySleepSummaries[dateKey] == nil {
                dailySleepSummaries[dateKey] = SleepSummary(
                    date: dateKey,
                    totalSleep: 0,
                    inBed: 0,
                    asleep: 0,
                    awake: 0,
                    rem: 0,
                    deep: 0,
                    core: 0,
                    entries: []
                )
            }
            
            // 睡眠時間を集計
            switch record.type {
            case .sleepInBed:
                dailySleepSummaries[dateKey]?.inBed += record.value
            case .sleepAsleep:
                dailySleepSummaries[dateKey]?.asleep += record.value
                dailySleepSummaries[dateKey]?.totalSleep += record.value
            case .sleepAwake:
                dailySleepSummaries[dateKey]?.awake += record.value
            case .sleepREM:
                dailySleepSummaries[dateKey]?.rem += record.value
            case .sleepDeep:
                dailySleepSummaries[dateKey]?.deep += record.value
            case .sleepCore:
                dailySleepSummaries[dateKey]?.core += record.value
            default:
                break
            }
            
            dailySleepSummaries[dateKey]?.entries.append(
                SleepEntry(
                    type: record.type.rawValue,
                    duration: record.value,
                    startTime: isoFormatter.string(from: record.startDate),
                    endTime: record.endDate != nil ? isoFormatter.string(from: record.endDate!) : nil
                )
            )
        }
        
        // JSON保存
        await saveSleepSummaries(dailySleepSummaries)
    }
    
    // MARK: - 睡眠サマリ保存
    private func saveSleepSummaries(_ summaries: [String: SleepSummary]) async {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let summaryDirectory = documentsDirectory.appendingPathComponent("SleepSummaries")
        
        try? FileManager.default.createDirectory(at: summaryDirectory, withIntermediateDirectories: true)
        
        for (dateKey, summary) in summaries {
            let fileName = "\(dateKey).json"
            let fileURL = summaryDirectory.appendingPathComponent(fileName)
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(summary)
                try data.write(to: fileURL)
                print("📁 睡眠サマリ保存: \(fileName)")
            } catch {
                print("❌ 睡眠サマリ保存エラー: \(error)")
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
    
    // MARK: - 活動データ取得（歩数、カロリー、心拍、HRV）
    func fetchActivityData(days: Int = 7) async {
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }
        
        do {
            // 権限確認
            try await requestAuthorization()
            
            var allRecords: [HealthDataRecord] = []
            
            // 1. 歩数データ取得
            if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
                let stepRecords = await fetchQuantityData(
                    type: stepType,
                    dataType: .stepCount,
                    unit: HKUnit.count(),
                    days: days,
                    aggregationType: .sum
                )
                allRecords.append(contentsOf: stepRecords)
            }
            
            // 2. アクティブカロリー取得
            if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                let energyRecords = await fetchQuantityData(
                    type: activeEnergyType,
                    dataType: .activeCalories,
                    unit: HKUnit.kilocalorie(),
                    days: days,
                    aggregationType: .sum
                )
                allRecords.append(contentsOf: energyRecords)
            }
            
            // 3. 安静時心拍数取得
            if let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
                let restingHRRecords = await fetchQuantityData(
                    type: restingHeartRateType,
                    dataType: .restingHeartRate,
                    unit: HKUnit.count().unitDivided(by: HKUnit.minute()),
                    days: days,
                    aggregationType: .average
                )
                allRecords.append(contentsOf: restingHRRecords)
            }
            
            // 4. HRV取得
            if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
                let hrvRecords = await fetchQuantityData(
                    type: hrvType,
                    dataType: .heartRateVariability,
                    unit: HKUnit.secondUnit(with: .milli),
                    days: days,
                    aggregationType: .average
                )
                allRecords.append(contentsOf: hrvRecords)
            }
            
            // 5. エクササイズ時間取得
            if let exerciseTimeType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
                let exerciseRecords = await fetchQuantityData(
                    type: exerciseTimeType,
                    dataType: .workoutDuration,  // exerciseTimeの代わりにworkoutDurationを使用
                    unit: HKUnit.minute(),
                    days: days,
                    aggregationType: .sum
                )
                allRecords.append(contentsOf: exerciseRecords)
            }
            
            let finalRecords = allRecords
            await MainActor.run {
                self.activityRecords = finalRecords.sorted { $0.startDate > $1.startDate }
                self.isLoading = false
                print("✅ 活動データ \(finalRecords.count)件取得完了")
            }
            
            // 活動サマリ生成
            await generateActivitySummary(records: finalRecords)
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLoading = false
                print("❌ 活動データ取得エラー: \(error)")
            }
        }
    }
    
    // MARK: - 汎用的な量的データ取得メソッド
    private func fetchQuantityData(
        type: HKQuantityType,
        dataType: HealthDataType,
        unit: HKUnit,
        days: Int,
        aggregationType: AggregationType
    ) async -> [HealthDataRecord] {
        
        let typeIdentifier = type.identifier
        let savedAnchor = anchorStore.getAnchor(for: typeIdentifier)
        
        // 期間設定
        let predicate: NSPredicate?
        if savedAnchor == nil {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
            predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
            print("📌 初回取得: \(dataType.displayName)の過去\(days)日間")
        } else {
            predicate = nil
            print("📌 増分取得: \(dataType.displayName)のアンカー以降")
        }
        
        // データ取得
        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(samples: [HKSample], newAnchor: HKQueryAnchor?), Error>) in
                let query = HKAnchoredObjectQuery(
                    type: type,
                    predicate: predicate,
                    anchor: savedAnchor,
                    limit: HKObjectQueryNoLimit
                ) { _, addedSamples, deletedSamples, newAnchor, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: (samples: addedSamples ?? [], newAnchor: newAnchor))
                    }
                }
                
                healthStore.execute(query)
            }
            
            // アンカー保存
            if let newAnchor = result.newAnchor {
                anchorStore.saveAnchor(newAnchor, for: typeIdentifier)
            }
            
            // 日ごとに集計（aggregationTypeに応じて）
            let records = aggregateByDay(samples: result.samples, type: type, dataType: dataType, unit: unit, aggregationType: aggregationType)
            
            return records
            
        } catch {
            print("❌ \(dataType.displayName)取得エラー: \(error)")
            return []
        }
    }
    
    // MARK: - 日別集計メソッド
    private func aggregateByDay(
        samples: [HKSample],
        type: HKQuantityType,
        dataType: HealthDataType,
        unit: HKUnit,
        aggregationType: AggregationType
    ) -> [HealthDataRecord] {
        
        let calendar = Calendar.current
        var dailyData: [String: [Double]] = [:]
        
        for sample in samples {
            guard let quantitySample = sample as? HKQuantitySample else { continue }
            
            // 日付キー作成
            var date = quantitySample.startDate
            let hour = calendar.component(.hour, from: date)
            if hour < dayBoundaryHour {
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            }
            let dateKey = dateKeyFormatter.string(from: date)
            
            // 値を取得
            let value = quantitySample.quantity.doubleValue(for: unit)
            
            if dailyData[dateKey] == nil {
                dailyData[dateKey] = []
            }
            dailyData[dateKey]?.append(value)
        }
        
        // 集計タイプに応じて集計
        var records: [HealthDataRecord] = []
        for (dateKey, values) in dailyData {
            guard !values.isEmpty else { continue }
            
            let aggregatedValue: Double
            switch aggregationType {
            case .sum:
                aggregatedValue = values.reduce(0, +)
            case .average:
                aggregatedValue = values.reduce(0, +) / Double(values.count)
            case .max:
                aggregatedValue = values.max() ?? 0
            case .min:
                aggregatedValue = values.min() ?? 0
            }
            
            // 日付をDateに戻す
            guard let date = dateKeyFormatter.date(from: dateKey) else { continue }
            
            let record = HealthDataRecord(
                type: dataType,
                value: aggregatedValue,
                unitString: dataType.defaultUnit,
                startDate: date,
                endDate: nil,
                source: "HealthKit"
            )
            records.append(record)
        }
        
        return records
    }
    
    // MARK: - 活動サマリ生成
    private func generateActivitySummary(records: [HealthDataRecord]) async {
        // 日付ごとにグループ化
        var dailyActivitySummaries: [String: ActivitySummary] = [:]
        
        for record in records {
            let dateKey = dateKeyFormatter.string(from: record.startDate)
            
            if dailyActivitySummaries[dateKey] == nil {
                dailyActivitySummaries[dateKey] = ActivitySummary(
                    date: dateKey,
                    stepCount: nil,
                    activeCalories: nil,
                    restingHeartRate: nil,
                    hrv: nil,
                    exerciseTime: nil
                )
            }
            
            switch record.type {
            case .stepCount:
                dailyActivitySummaries[dateKey]?.stepCount = Int(record.value)
            case .activeCalories:
                dailyActivitySummaries[dateKey]?.activeCalories = record.value
            case .restingHeartRate:
                dailyActivitySummaries[dateKey]?.restingHeartRate = record.value
            case .heartRateVariability:
                dailyActivitySummaries[dateKey]?.hrv = record.value
            case .workoutDuration:
                dailyActivitySummaries[dateKey]?.exerciseTime = record.value
            default:
                break
            }
        }
        
        // JSON保存
        await saveActivitySummaries(dailyActivitySummaries)
    }
    
    // MARK: - 活動サマリ保存
    private func saveActivitySummaries(_ summaries: [String: ActivitySummary]) async {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let summaryDirectory = documentsDirectory.appendingPathComponent("ActivitySummaries")
        
        try? FileManager.default.createDirectory(at: summaryDirectory, withIntermediateDirectories: true)
        
        for (dateKey, summary) in summaries {
            let fileName = "\(dateKey).json"
            let fileURL = summaryDirectory.appendingPathComponent(fileName)
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(summary)
                try data.write(to: fileURL)
                print("📁 活動サマリ保存: \(fileName)")
            } catch {
                print("❌ 活動サマリ保存エラー: \(error)")
            }
        }
    }
    
    // MARK: - ワークアウトデータ取得
    func fetchWorkoutData(days: Int = 30) async {
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }
        
        do {
            // 権限確認
            let workoutType = HKObjectType.workoutType()
            try await requestAuthorization(for: [workoutType])
            
            // 保存されたアンカーを取得
            let typeIdentifier = "HKWorkoutType"
            let savedAnchor = anchorStore.getAnchor(for: typeIdentifier)
            
            // 期間設定
            let predicate: NSPredicate?
            if savedAnchor == nil {
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
                predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
                print("📌 初回取得: 過去\(days)日間のワークアウトデータ")
            } else {
                predicate = nil
                print("📌 増分取得: アンカー以降のワークアウトデータ")
            }
            
            // データ取得
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(samples: [HKSample], newAnchor: HKQueryAnchor?), Error>) in
                let query = HKAnchoredObjectQuery(
                    type: workoutType,
                    predicate: predicate,
                    anchor: savedAnchor,
                    limit: HKObjectQueryNoLimit
                ) { _, addedSamples, deletedSamples, newAnchor, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: (samples: addedSamples ?? [], newAnchor: newAnchor))
                    }
                }
                
                healthStore.execute(query)
            }
            
            // アンカー保存
            if let newAnchor = result.newAnchor {
                anchorStore.saveAnchor(newAnchor, for: typeIdentifier)
            }
            
            // WorkoutDataに変換
            let newWorkouts = result.samples.compactMap { sample -> WorkoutData? in
                guard let workout = sample as? HKWorkout else { return nil }
                
                let workoutTypeName = self.getWorkoutTypeName(workout.workoutActivityType)
                
                var totalCalories: Double? = nil
                if #available(iOS 18.0, *) {
                    // iOS 18以降は統計を使用
                    if let energyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                        totalCalories = workout.statistics(for: energyBurnedType)?.sumQuantity()?.doubleValue(for: .kilocalorie())
                    }
                } else {
                    // iOS 17以前は従来のプロパティを使用
                    totalCalories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                }
                
                return WorkoutData(
                    workoutType: workoutTypeName,
                    startDate: workout.startDate,
                    endDate: workout.endDate,
                    duration: workout.duration,
                    totalCalories: totalCalories,
                    distance: workout.totalDistance?.doubleValue(for: .meter()),
                    source: workout.sourceRevision.source.name
                )
            }
            
            // 既存データと統合
            if savedAnchor != nil && !workoutRecords.isEmpty {
                let existingIds = Set(workoutRecords.map { "\($0.startDate)" })
                let filteredNewWorkouts = newWorkouts.filter { workout in
                    !existingIds.contains("\(workout.startDate)")
                }
                
                await MainActor.run {
                    self.workoutRecords.append(contentsOf: filteredNewWorkouts)
                    self.workoutRecords.sort { $0.startDate > $1.startDate }
                    self.isLoading = false
                    print("✅ 新規ワークアウトデータ \(filteredNewWorkouts.count)件追加（合計: \(self.workoutRecords.count)件）")
                }
            } else {
                await MainActor.run {
                    self.workoutRecords = newWorkouts.sorted { $0.startDate > $1.startDate }
                    self.isLoading = false
                    print("✅ ワークアウトデータ \(newWorkouts.count)件取得完了")
                }
            }
            
            // ワークアウトサマリ生成
            await generateWorkoutSummary(records: workoutRecords)
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLoading = false
                print("❌ ワークアウトデータ取得エラー: \(error)")
            }
        }
    }
    
    // MARK: - ワークアウトタイプ名変換
    private func getWorkoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "ランニング"
        case .walking: return "ウォーキング"
        case .cycling: return "サイクリング"
        case .swimming: return "水泳"
        case .elliptical: return "エリプティカル"
        case .rowing: return "ローイング"
        case .stairClimbing: return "階段昇降"
        case .functionalStrengthTraining: return "筋トレ"
        case .traditionalStrengthTraining: return "ウェイトトレーニング"
        case .yoga: return "ヨガ"
        case .dance: return "ダンス"
        case .cooldown: return "クールダウン"
        case .coreTraining: return "体幹トレーニング"
        case .flexibility: return "ストレッチ"
        case .highIntensityIntervalTraining: return "HIIT"
        case .jumpRope: return "縄跳び"
        case .kickboxing: return "キックボクシング"
        case .pilates: return "ピラティス"
        case .stairs: return "階段"
        default: return "その他"
        }
    }
    
    // MARK: - ワークアウトサマリ生成
    private func generateWorkoutSummary(records: [WorkoutData]) async {
        let calendar = Calendar.current
        var dailyWorkoutSummaries: [String: WorkoutSummary] = [:]
        
        for workout in records {
            // 終了時刻の日付で集計
            var adjustedDate = workout.endDate
            let hour = calendar.component(.hour, from: adjustedDate)
            if hour < dayBoundaryHour {
                adjustedDate = calendar.date(byAdding: .day, value: -1, to: adjustedDate) ?? adjustedDate
            }
            
            let dateKey = dateKeyFormatter.string(from: adjustedDate)
            
            if dailyWorkoutSummaries[dateKey] == nil {
                dailyWorkoutSummaries[dateKey] = WorkoutSummary(
                    date: dateKey,
                    totalDuration: 0,
                    totalCalories: 0,
                    workouts: []
                )
            }
            
            dailyWorkoutSummaries[dateKey]?.totalDuration += workout.duration
            dailyWorkoutSummaries[dateKey]?.totalCalories += workout.totalCalories ?? 0
            dailyWorkoutSummaries[dateKey]?.workouts.append(
                WorkoutEntry(
                    type: workout.workoutType,
                    duration: workout.duration,
                    calories: workout.totalCalories,
                    distance: workout.distance,
                    startTime: isoFormatter.string(from: workout.startDate),
                    endTime: isoFormatter.string(from: workout.endDate)
                )
            )
        }
        
        // JSON保存
        await saveWorkoutSummaries(dailyWorkoutSummaries)
    }
    
    // MARK: - ワークアウトサマリ保存
    private func saveWorkoutSummaries(_ summaries: [String: WorkoutSummary]) async {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let summaryDirectory = documentsDirectory.appendingPathComponent("WorkoutSummaries")
        
        try? FileManager.default.createDirectory(at: summaryDirectory, withIntermediateDirectories: true)
        
        for (dateKey, summary) in summaries {
            let fileName = "\(dateKey).json"
            let fileURL = summaryDirectory.appendingPathComponent(fileName)
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(summary)
                try data.write(to: fileURL)
                print("📁 ワークアウトサマリ保存: \(fileName)")
            } catch {
                print("❌ ワークアウトサマリ保存エラー: \(error)")
            }
        }
    }
    
    // MARK: - 睡眠データ削除（全再取得用）
    func deleteAllSleepData() async {
        // アンカー削除
        let typeIdentifier = HKCategoryTypeIdentifier.sleepAnalysis.rawValue
        anchorStore.deleteAnchor(for: typeIdentifier)
        
        // ローカルJSON削除
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let summaryDirectory = documentsDirectory.appendingPathComponent("SleepSummaries")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: summaryDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            print("🗑️ 全睡眠データ削除完了")
        } catch {
            print("❌ 睡眠データ削除エラー: \(error)")
        }
        
        // メモリクリア
        await MainActor.run {
            self.sleepRecords = []
        }
        
        // 即座に全取得
        await fetchSleepData()
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
    
    // MARK: - 活動データ削除（全再取得用）
    func deleteAllActivityData() async {
        // 活動データ関連のアンカー削除
        let activityTypes = [
            HKQuantityTypeIdentifier.stepCount.rawValue,
            HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.restingHeartRate.rawValue,
            HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue,
            HKQuantityTypeIdentifier.appleExerciseTime.rawValue
        ]
        
        for typeIdentifier in activityTypes {
            anchorStore.deleteAnchor(for: typeIdentifier)
        }
        
        // ローカルJSON削除
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let summaryDirectory = documentsDirectory.appendingPathComponent("ActivitySummaries")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: summaryDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            print("🗑️ 全活動データ削除完了")
        } catch {
            print("❌ 活動データ削除エラー: \(error)")
        }
        
        // メモリクリア
        await MainActor.run {
            self.activityRecords = []
        }
        
        // 即座に全取得
        await fetchActivityData()
    }
    
    // MARK: - ワークアウトデータ削除（全再取得用）
    func deleteAllWorkoutData() async {
        // アンカー削除
        anchorStore.deleteAnchor(for: "HKWorkoutType")
        
        // ローカルJSON削除
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let summaryDirectory = documentsDirectory.appendingPathComponent("WorkoutSummaries")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: summaryDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            print("🗑️ 全ワークアウトデータ削除完了")
        } catch {
            print("❌ ワークアウトデータ削除エラー: \(error)")
        }
        
        // メモリクリア
        await MainActor.run {
            self.workoutRecords = []
        }
        
        // 即座に全取得
        await fetchWorkoutData()
    }
}

// MARK: - 集計タイプ
enum AggregationType {
    case sum
    case average
    case max
    case min
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

// MARK: - 睡眠サマリ構造体
struct SleepSummary: Codable {
    let date: String
    var totalSleep: Double // 合計睡眠時間
    var inBed: Double      // ベッドにいた時間
    var asleep: Double     // 実際に寝ていた時間
    var awake: Double      // 覚醒時間
    var rem: Double        // レム睡眠
    var deep: Double       // 深い睡眠
    var core: Double       // コア睡眠
    var entries: [SleepEntry]
}

struct SleepEntry: Codable {
    let type: String
    let duration: Double
    let startTime: String
    let endTime: String?
}

// MARK: - 活動サマリ構造体
struct ActivitySummary: Codable {
    let date: String
    var stepCount: Int?
    var activeCalories: Double?
    var restingHeartRate: Double?
    var hrv: Double?
    var exerciseTime: Double?
}

// MARK: - ワークアウトサマリ構造体
struct WorkoutSummary: Codable {
    let date: String
    var totalDuration: TimeInterval
    var totalCalories: Double
    var workouts: [WorkoutEntry]
}

struct WorkoutEntry: Codable {
    let type: String
    let duration: TimeInterval
    let calories: Double?
    let distance: Double?
    let startTime: String
    let endTime: String
}