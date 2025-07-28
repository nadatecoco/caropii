import SwiftUI
import HealthKit

struct HomeView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // アプリタイトル
            VStack(spacing: 10) {
                Text("カロッピー")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("PFC 管理アプリ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // メインボタン
            VStack(spacing: 20) {
                NavigationLink(destination: SaveViewDebug()
                    .environmentObject(foodStore)
                    .environmentObject(foodEntryStore)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("今日の記録をする")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                NavigationLink(destination: DataManagementView()
                    .environmentObject(foodStore)) {
                    HStack {
                        Image(systemName: "folder.circle.fill")
                            .font(.title2)
                        Text("データを管理")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // 睡眠データテスト用ボタン
                Button(action: {
                    requestSleepData()
                }) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .font(.title2)
                        Text("睡眠データ取得テスト")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // 筋トレ記録ボタン
                Button(action: {
                    // TODO: 筋トレ記録画面に遷移
                }) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .font(.title2)
                        Text("筋トレ記録")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("ホーム")
        .navigationBarHidden(true)
    }
    
    // 睡眠データ取得テスト関数
    private func requestSleepData() {
        print("🛌 睡眠データ取得を開始します...")
        
        // 睡眠分析のタイプを定義
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ 睡眠分析タイプの取得に失敗しました")
            return
        }
        
        // HealthKitの利用可能性をチェック
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKitが利用できません")
            return
        }
        
        // 権限をリクエスト
        healthStore.requestAuthorization(toShare: nil, read: [sleepType]) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit権限が許可されました")
                    self.fetchSleepData()
                } else {
                    print("❌ HealthKit権限が拒否されました: \(error?.localizedDescription ?? "不明なエラー")")
                }
            }
        }
    }
    
    // 実際の睡眠データを取得
    private func fetchSleepData() {
        print("📊 睡眠データの取得を開始...")
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        // 過去7日間のデータを取得
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: nil) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 睡眠データ取得エラー: \(error.localizedDescription)")
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    print("❌ 睡眠データの変換に失敗しました")
                    return
                }
                
                print("✅ 睡眠データを \(sleepSamples.count) 件取得しました")
                
                // 取得したデータの詳細を出力
                for sample in sleepSamples {
                    let startTime = sample.startDate
                    let endTime = sample.endDate
                    let duration = endTime.timeIntervalSince(startTime) / 3600 // 時間単位
                    let sleepValue = sample.value
                    
                    print("🌙 睡眠記録:")
                    print("  開始時刻: \(startTime)")
                    print("  終了時刻: \(endTime)")
                    print("  継続時間: \(String(format: "%.1f", duration))時間")
                    print("  睡眠値: \(sleepValue)")
                    print("  ソース: \(sample.sourceRevision.source.name)")
                    print("---")
                }
            }
        }
        
        healthStore.execute(query)
    }
}

#Preview {
    NavigationView {
        HomeView()
            .environmentObject(FoodStore())
            .environmentObject(FoodEntryStore())
    }
}