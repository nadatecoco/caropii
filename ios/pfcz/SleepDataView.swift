import SwiftUI
import HealthKit

struct SleepDataView: View {
    @State private var sleepRecords: [SleepDisplayRecord] = []
    @State private var isLoading = false
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            // ヘッダー部分
            VStack(spacing: 15) {
                Text("睡眠データ管理")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // データ取得ボタン
                Button(action: {
                    fetchSleepData()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isLoading ? "取得中..." : "睡眠データを取得")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            .padding()
            
            Divider()
            
            // データ一覧
            if sleepRecords.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("睡眠データがありません")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("上のボタンでデータを取得してください")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(sleepRecords, id: \.id) { record in
                        SleepRecordRow(record: record)
                    }
                }
            }
        }
        .navigationTitle("睡眠データ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 初回表示時にデータを取得
            fetchSleepData()
        }
    }
    
    // 睡眠データ取得
    private func fetchSleepData() {
        isLoading = true
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            isLoading = false
            return
        }
        
        // 過去30日間のデータを取得
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ 睡眠データ取得エラー: \(error.localizedDescription)")
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    print("❌ 睡眠データの変換に失敗しました")
                    return
                }
                
                // データを表示用に変換
                self.sleepRecords = sleepSamples.map { sample in
                    SleepDisplayRecord(
                        id: sample.uuid.uuidString,
                        startTime: sample.startDate,
                        endTime: sample.endDate,
                        sleepValue: sample.value,
                        dataSource: sample.sourceRevision.source.name,
                        duration: sample.endDate.timeIntervalSince(sample.startDate) / 3600
                    )
                }
                
                print("✅ 睡眠データを \(self.sleepRecords.count) 件取得しました")
            }
        }
        
        healthStore.execute(query)
    }
}

// 睡眠記録の表示用構造体
struct SleepDisplayRecord {
    let id: String
    let startTime: Date
    let endTime: Date
    let sleepValue: Int
    let dataSource: String
    let duration: Double
    
    var sleepStateName: String {
        switch sleepValue {
        case 0:
            return "ベッドにいる"
        case 1:
            return "睡眠中"
        case 2:
            return "深い睡眠"
        case 3:
            return "REM睡眠"
        default:
            return "不明"
        }
    }
    
    var formattedDuration: String {
        return String(format: "%.1f時間", duration)
    }
}

// 睡眠記録の行表示
struct SleepRecordRow: View {
    let record: SleepDisplayRecord
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日付とステータス
            HStack {
                Text(dateFormatter.string(from: record.startTime))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(record.sleepStateName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(record.sleepValue == 1 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // 時間情報
            HStack {
                Text("\(timeFormatter.string(from: record.startTime)) - \(timeFormatter.string(from: record.endTime))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(record.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // データソース
            Text("データソース: \(record.dataSource)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        SleepDataView()
    }
}