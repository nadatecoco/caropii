//
//  ContentView.swift
//  pfcz
//
//  Created by なたてここ on 2025/07/08.
//

import SwiftUI
import Charts
import HealthKit

struct ContentView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack(spacing: 20) {
            // 今日の合計表示
            VStack {
                Text("今日の合計")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Text("kcal: \(foodEntryStore.todayTotalCalories, specifier: "%.0f")")
                }
                .font(.headline)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            // P/F/C横棒グラフ
            Chart {
                BarMark(
                    x: .value("Amount", foodEntryStore.todayTotalProtein),
                    y: .value("Nutrient", "Protein")
                )
                .foregroundStyle(.red.opacity(0.8))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(foodEntryStore.todayTotalProtein, specifier: "%.1f")g")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                BarMark(
                    x: .value("Amount", foodEntryStore.todayTotalFat),
                    y: .value("Nutrient", "Fat")
                )
                .foregroundStyle(.orange.opacity(0.8))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(foodEntryStore.todayTotalFat, specifier: "%.1f")g")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                BarMark(
                    x: .value("Amount", foodEntryStore.todayTotalCarbs),
                    y: .value("Nutrient", "Carb")
                )
                .foregroundStyle(.green.opacity(0.8))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(foodEntryStore.todayTotalCarbs, specifier: "%.1f")g")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .frame(height: 150)
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.background(.clear)
            }
            
            // 食事記録リスト
            VStack(alignment: .leading) {
                Text("食事記録（タップで削除）")
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    ForEach(foodEntryStore.entries) { entry in
                        HStack {
                            Text("\(entry.food.name)　\(entry.food.calories, specifier: "%.0f") kcal")
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            foodEntryStore.remove(entry: entry)
                        }
                    }
                    .onDelete(perform: foodEntryStore.remove)
                }
            }
            
            // 食材選択（横スクロール）
            VStack(alignment: .leading) {
                Text("食材を選択")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(foodStore.foods) { food in
                            Button(action: {
                                foodEntryStore.add(food: food)
                            }) {
                                Text(food.name)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 睡眠データテスト用ボタン
            Button("睡眠データ取得テスト") {
                requestSleepData()
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(10)
            
            
            Spacer()
        }
        .padding()
        .navigationTitle("PFC カウンター")
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
    ContentView()
        .environmentObject(FoodStore())
        .environmentObject(FoodEntryStore())
}
