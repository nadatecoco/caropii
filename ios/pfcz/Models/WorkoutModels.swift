import Foundation

// MARK: - 保存用のデータモデル

struct WorkoutDayRecord: Codable {
    let date: String // "2024-01-15" 形式
    var exercises: [ExerciseRecord]
}

struct ExerciseRecord: Codable {
    let id: UUID
    let exerciseName: String
    let timestamp: Date
    var sets: [SetRecord]
}

struct SetRecord: Codable {
    let id: UUID
    var weight: Double // kg単位で保存
    var reps: Int
    var memo: String
    var isCompleted: Bool
    var timestamp: Date? // セット完了時刻
}

// MARK: - 保存管理用の拡張

extension WorkoutDayRecord {
    // 日付文字列から Date オブジェクトを取得
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: date)
    }
    
    // 現在の日付で新しいレコードを作成
    static func createForToday() -> WorkoutDayRecord {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return WorkoutDayRecord(
            date: formatter.string(from: Date()),
            exercises: []
        )
    }
}

// MARK: - LLM送信用の圧縮

extension WorkoutDayRecord {
    // トークン削減のための圧縮表現
    func compressedForLLM() -> String {
        var compressed = date.replacingOccurrences(of: "-", with: "") + ":"
        
        let exerciseStrings = exercises.map { exercise in
            let exerciseCode = compressExerciseName(exercise.exerciseName)
            let setsString = exercise.sets
                .filter { $0.isCompleted }
                .map { "\(Int($0.weight))x\($0.reps)" }
                .joined(separator: ",")
            return "\(exerciseCode)-\(setsString)"
        }
        
        compressed += exerciseStrings.joined(separator: ";")
        return compressed
    }
    
    private func compressExerciseName(_ name: String) -> String {
        // 一般的な種目の略称マッピング
        let abbreviations: [String: String] = [
            "ベンチプレス": "BP",
            "スクワット": "SQ",
            "デッドリフト": "DL",
            "ショルダープレス": "SP",
            "ラットプルダウン": "LP",
            "レッグプレス": "LGP",
            "ダンベルカール": "DC",
            "トライセプスエクステンション": "TE"
        ]
        
        return abbreviations[name] ?? String(name.prefix(3))
    }
}