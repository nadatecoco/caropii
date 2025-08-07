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
    
    // 新しい記録を追加または更新
    func updateRecord(exerciseName: String, sets: [SetData]) {
        // 空でないセットのみフィルタリング
        let validSets = sets.filter { !$0.weight.isEmpty && !$0.reps.isEmpty }
        
        if validSets.isEmpty {
            // 全て空の場合は記録から削除
            todayRecords.removeAll { $0.exerciseName == exerciseName }
        } else {
            // 既存の記録を探す
            if let index = todayRecords.firstIndex(where: { $0.exerciseName == exerciseName }) {
                // 更新
                todayRecords[index] = WorkoutRecord(
                    exerciseName: exerciseName,
                    weight: validSets.first?.weight ?? "",
                    sets: validSets.map { "\($0.reps)" }
                )
            } else {
                // 新規追加
                let newRecord = WorkoutRecord(
                    exerciseName: exerciseName,
                    weight: validSets.first?.weight ?? "",
                    sets: validSets.map { "\($0.reps)" }
                )
                todayRecords.append(newRecord)
            }
        }
    }
}