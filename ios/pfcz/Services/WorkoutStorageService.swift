import Foundation

class WorkoutStorageService {
    static let shared = WorkoutStorageService()
    
    private let documentsDirectory: URL
    private let workoutDirectory: URL
    
    private init() {
        // ドキュメントディレクトリを取得
        documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        
        // workout専用ディレクトリ
        workoutDirectory = documentsDirectory.appendingPathComponent("WorkoutRecords")
        
        // ディレクトリが存在しない場合は作成
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: workoutDirectory,
                                                  withIntermediateDirectories: true,
                                                  attributes: nil)
        } catch {
            print("ディレクトリ作成エラー: \(error)")
        }
    }
    
    // MARK: - ファイル名生成
    
    private func fileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return "\(formatter.string(from: date)).json"
    }
    
    private func fileURL(for date: Date) -> URL {
        return workoutDirectory.appendingPathComponent(fileName(for: date))
    }
    
    // MARK: - 保存
    
    func save(_ record: WorkoutDayRecord) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(record)
        let url = fileURL(for: record.dateObject ?? Date())
        
        try data.write(to: url)
    }
    
    // MARK: - 読み込み
    
    func load(for date: Date) -> WorkoutDayRecord? {
        let url = fileURL(for: date)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(WorkoutDayRecord.self, from: data)
        } catch {
            print("読み込みエラー: \(error)")
            return nil
        }
    }
    
    // MARK: - 日付の区切り時間を考慮した「今日」の取得
    
    func getTodayDate(cutoffHour: Int = 0) -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // 現在の時刻を取得
        let hour = calendar.component(.hour, from: now)
        
        // 区切り時間前なら前日として扱う
        if hour < cutoffHour {
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }
        
        return now
    }
    
    // MARK: - 月間データの取得
    
    func loadMonth(year: Int, month: Int) -> [WorkoutDayRecord] {
        var records: [WorkoutDayRecord] = []
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startDate = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startDate) else {
            return records
        }
        
        for day in range {
            components.day = day
            if let date = calendar.date(from: components),
               let record = load(for: date) {
                records.append(record)
            }
        }
        
        return records
    }
    
    // MARK: - 削除
    
    func delete(for date: Date) throws {
        let url = fileURL(for: date)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}