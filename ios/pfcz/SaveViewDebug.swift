import SwiftUI
import Charts

struct SaveViewDebug: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAnalyzing = false
    @State private var analysisResult: String?
    @State private var showingAnalysisResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 今日の合計表示のみ
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
            
            // AI分析ボタン
            VStack {
                Button(action: {
                    sendTodayDataAndAnalyze()
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                        Text("AI分析する")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(foodEntryStore.todayEntries.isEmpty)
                
                if isAnalyzing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("AI分析中...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 5)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("食事記録")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAnalysisResult) {
            if let result = analysisResult {
                AnalysisResultView(analysisText: result)
            }
        }
    }
    
    private func sendTodayDataAndAnalyze() {
        isAnalyzing = true
        
        let todayEntries = foodEntryStore.todayEntries
        let group = DispatchGroup()
        var hasError = false
        
        // 今日の食事データを全てRailsに送信
        for entry in todayEntries {
            group.enter()
            APIService.shared.sendFoodEntry(food: entry.food) { result in
                switch result {
                case .success:
                    break
                case .failure:
                    hasError = true
                }
                group.leave()
            }
        }
        
        // 全ての送信完了後にAI分析実行
        group.notify(queue: .main) {
            if !hasError {
                APIService.shared.getAIAnalysis { result in
                    isAnalyzing = false
                    switch result {
                    case .success(let analysis):
                        analysisResult = analysis
                        showingAnalysisResult = true
                    case .failure(let error):
                        print("AI分析エラー: \(error.localizedDescription)")
                    }
                }
            } else {
                isAnalyzing = false
                print("データ送信でエラーが発生しました")
            }
        }
    }
}

#Preview {
    NavigationView {
        SaveViewDebug()
            .environmentObject(FoodStore())
            .environmentObject(FoodEntryStore())
    }
}