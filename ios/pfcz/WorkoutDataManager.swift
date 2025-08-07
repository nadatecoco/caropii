import SwiftUI

// セットごとのデータ
struct SetData: Identifiable, Equatable {
    let id = UUID()
    var weight: String = ""
    var reps: String = ""
    var memo: String = ""
    var isCompleted: Bool = false
}

// 筋トレデータ管理クラス
class WorkoutDataManager: ObservableObject {
    @Published var todayRecords: [WorkoutRecord] = []
    @Published var currentDayRecord: WorkoutDayRecord?
    
    private let storageService = WorkoutStorageService.shared
    private var currentDate: Date
    
    init() {
        // 現在の日付を取得（デフォルトは0時区切り）
        currentDate = storageService.getTodayDate(cutoffHour: 0)
        loadTodayRecords()
    }
    
    // 今日の記録を読み込み
    private func loadTodayRecords() {
        if let record = storageService.load(for: currentDate) {
            currentDayRecord = record
            // WorkoutDayRecordから表示用のWorkoutRecordに変換
            todayRecords = convertToDisplayRecords(from: record)
        } else {
            currentDayRecord = WorkoutDayRecord.createForToday()
            todayRecords = []
        }
    }
    
    // 表示用のレコードに変換
    private func convertToDisplayRecords(from dayRecord: WorkoutDayRecord) -> [WorkoutRecord] {
        return dayRecord.exercises.map { exercise in
            let latestWeight = exercise.sets.last?.weight ?? 0
            let reps = exercise.sets.map { "\($0.reps)" }
            return WorkoutRecord(
                exerciseName: exercise.exerciseName,
                weight: String(format: "%.1f", latestWeight).replacingOccurrences(of: ".0", with: ""),
                sets: reps
            )
        }
    }
    
    // 新しい記録を追加または更新
    func updateRecord(exerciseName: String, sets: [SetData]) {
        // 空でないセットのみフィルタリング
        let validSets = sets.filter { !$0.weight.isEmpty && !$0.reps.isEmpty }
        
        if validSets.isEmpty {
            // 全て空の場合は記録から削除
            todayRecords.removeAll { $0.exerciseName == exerciseName }
            currentDayRecord?.exercises.removeAll { $0.exerciseName == exerciseName }
        } else {
            // SetDataをSetRecordに変換
            let setRecords = validSets.map { setData in
                SetRecord(
                    id: setData.id,
                    weight: Double(setData.weight) ?? 0,
                    reps: Int(setData.reps) ?? 0,
                    memo: setData.memo,
                    isCompleted: setData.isCompleted,
                    timestamp: Date() // 保存時の現在時刻を記録
                )
            }
            
            // ExerciseRecordを作成または更新
            if let exerciseIndex = currentDayRecord?.exercises.firstIndex(where: { $0.exerciseName == exerciseName }) {
                // 既存の種目を更新
                currentDayRecord?.exercises[exerciseIndex].sets = setRecords
            } else {
                // 新しい種目を追加
                let newExercise = ExerciseRecord(
                    id: UUID(),
                    exerciseName: exerciseName,
                    timestamp: Date(),
                    sets: setRecords
                )
                currentDayRecord?.exercises.append(newExercise)
            }
            
            // 表示用のレコードも更新
            if let index = todayRecords.firstIndex(where: { $0.exerciseName == exerciseName }) {
                todayRecords[index] = WorkoutRecord(
                    exerciseName: exerciseName,
                    weight: validSets.first?.weight ?? "",
                    sets: validSets.map { "\($0.reps)" }
                )
            } else {
                let newRecord = WorkoutRecord(
                    exerciseName: exerciseName,
                    weight: validSets.first?.weight ?? "",
                    sets: validSets.map { "\($0.reps)" }
                )
                todayRecords.append(newRecord)
            }
        }
        
        // 永続保存
        saveCurrentRecord()
    }
    
    // 現在の記録を保存
    private func saveCurrentRecord() {
        guard let record = currentDayRecord else { return }
        
        do {
            try storageService.save(record)
        } catch {
            print("保存エラー: \(error)")
        }
    }
    
    // 日付が変わったかチェック（タイマーなどで定期的に呼ぶ）
    func checkDateChange() {
        let newDate = storageService.getTodayDate(cutoffHour: 0)
        let calendar = Calendar.current
        
        if !calendar.isDate(currentDate, inSameDayAs: newDate) {
            // 日付が変わった
            currentDate = newDate
            loadTodayRecords()
        }
    }
}