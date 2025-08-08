import Foundation
import HealthKit

// 日付区切り時刻の定数
let dayBoundaryHour = 4 // 午前4時を日付の区切りとする（将来的に設定可能に）

// ヘルスケアデータの共通モデル
struct HealthDataRecord: Codable, Identifiable {
    let id: UUID
    let type: HealthDataType
    let value: Double
    let unitString: String // 単位文字列（HKUnit.stringRepresentation）
    let startDate: Date  // 開始日時
    let endDate: Date?   // 終了日時（瞬間的なデータの場合はnil）
    let source: String   // "HealthKit", "Manual", etc
    
    // 後方互換性のための旧プロパティ
    var date: Date { startDate }
    var unit: String { unitString }
    
    init(id: UUID = UUID(), 
         type: HealthDataType, 
         value: Double, 
         unitString: String, 
         startDate: Date,
         endDate: Date? = nil,
         source: String = "HealthKit") {
        self.id = id
        self.type = type
        self.value = value
        self.unitString = unitString
        self.startDate = startDate
        self.endDate = endDate
        self.source = source
    }
    
    // 後方互換のための旧イニシャライザー
    init(id: UUID = UUID(), type: HealthDataType, value: Double, unit: String, date: Date, source: String = "HealthKit") {
        self.init(id: id, type: type, value: value, unitString: unit, startDate: date, endDate: nil, source: source)
    }
}

// データタイプの定義
enum HealthDataType: String, Codable, CaseIterable {
    // 身体測定
    case weight = "weight"
    case bodyFatPercentage = "bodyFatPercentage"
    case leanBodyMass = "leanBodyMass"
    case bmi = "bmi"
    case height = "height"
    
    // 活動データ
    case stepCount = "stepCount"
    case distanceWalking = "distanceWalking"
    case activeCalories = "activeCalories"
    case restingCalories = "restingCalories"
    case flightsClimbed = "flightsClimbed"
    
    // 睡眠データ
    case sleepHours = "sleepHours"
    case sleepInBed = "sleepInBed"
    case sleepAsleep = "sleepAsleep"
    case sleepAwake = "sleepAwake"
    case sleepREM = "sleepREM"
    case sleepDeep = "sleepDeep"
    case sleepCore = "sleepCore"
    
    // バイタル
    case heartRate = "heartRate"
    case heartRateVariability = "heartRateVariability"
    case restingHeartRate = "restingHeartRate"
    case bloodOxygen = "bloodOxygen"
    
    // 栄養データ
    case dietaryCalories = "dietaryCalories"
    case dietaryProtein = "dietaryProtein"
    case dietaryFat = "dietaryFat"
    case dietaryCarbs = "dietaryCarbs"
    
    // ワークアウト
    case workoutDuration = "workoutDuration"
    case workoutCalories = "workoutCalories"
    
    var displayName: String {
        switch self {
        case .weight: return "体重"
        case .bodyFatPercentage: return "体脂肪率"
        case .leanBodyMass: return "筋肉量"
        case .bmi: return "BMI"
        case .height: return "身長"
        case .stepCount: return "歩数"
        case .distanceWalking: return "歩行距離"
        case .activeCalories: return "アクティブカロリー"
        case .restingCalories: return "安静時カロリー"
        case .flightsClimbed: return "上った階数"
        case .sleepHours: return "睡眠時間"
        case .sleepInBed: return "就床時間"
        case .sleepAsleep: return "睡眠時間"
        case .sleepAwake: return "覚醒時間"
        case .sleepREM: return "レム睡眠"
        case .sleepDeep: return "深い睡眠"
        case .sleepCore: return "コア睡眠"
        case .heartRate: return "心拍数"
        case .heartRateVariability: return "心拍変動"
        case .restingHeartRate: return "安静時心拍数"
        case .bloodOxygen: return "血中酸素濃度"
        case .dietaryCalories: return "摂取カロリー"
        case .dietaryProtein: return "タンパク質"
        case .dietaryFat: return "脂質"
        case .dietaryCarbs: return "炭水化物"
        case .workoutDuration: return "運動時間"
        case .workoutCalories: return "運動カロリー"
        }
    }
    
    var defaultUnit: String {
        switch self {
        case .weight: return "kg"
        case .bodyFatPercentage: return "%"
        case .leanBodyMass: return "kg"
        case .bmi: return ""
        case .height: return "cm"
        case .stepCount: return "歩"
        case .distanceWalking: return "km"
        case .activeCalories, .restingCalories, .dietaryCalories, .workoutCalories: return "kcal"
        case .flightsClimbed: return "階"
        case .sleepHours, .sleepInBed, .sleepAsleep, .sleepAwake, .sleepREM, .sleepDeep, .sleepCore, .workoutDuration: return "時間"
        case .heartRate, .restingHeartRate: return "bpm"
        case .heartRateVariability: return "ms"
        case .bloodOxygen: return "%"
        case .dietaryProtein, .dietaryFat, .dietaryCarbs: return "g"
        }
    }
}

// 日ごとのヘルスデータ
struct DailyHealthData: Codable {
    let date: Date
    var records: [HealthDataRecord]
    
    init(date: Date, records: [HealthDataRecord] = []) {
        self.date = date
        self.records = records
    }
}

// ワークアウト詳細
struct WorkoutData: Codable {
    let id: UUID
    let workoutType: String // "筋トレ", "ランニング", etc
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalCalories: Double?
    let distance: Double?
    let source: String
    
    init(id: UUID = UUID(), workoutType: String, startDate: Date, endDate: Date, duration: TimeInterval, totalCalories: Double? = nil, distance: Double? = nil, source: String = "HealthKit") {
        self.id = id
        self.workoutType = workoutType
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.totalCalories = totalCalories
        self.distance = distance
        self.source = source
    }
}