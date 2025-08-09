import SwiftUI
import Charts

struct SaveViewDebug: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAnalyzing = false
    @State private var analysisResult: String?
    @State private var showingAnalysisResult = false
    @State private var showingOCRView = false
    @State private var showingBarcodeScanner = false
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var showingEmptySaveAlert = false
    @State private var showingEmptyAnalysisAlert = false
    
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
            
            // 入力ボタン群（上段）
            HStack(spacing: 8) {
                // バーコードスキャンボタン
                Button(action: {
                    showingBarcodeScanner = true
                }) {
                    VStack {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                        Text("バーコード")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // 写真読み取りボタン
                Button(action: {
                    showingOCRView = true
                }) {
                    VStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                        Text("写真読取")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            // アクションボタン群（下段）
            HStack(spacing: 8) {
                // 保存ボタン
                Button(action: {
                    if foodEntryStore.todayEntries.isEmpty {
                        showingEmptySaveAlert = true
                    } else {
                        saveTodayData()
                    }
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                        Text("記録を保存")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(foodEntryStore.todayEntries.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // AI分析ボタン
                Button(action: {
                    if foodEntryStore.todayEntries.isEmpty {
                        showingEmptyAnalysisAlert = true
                    } else {
                        sendTodayDataAndAnalyze()
                    }
                }) {
                    VStack {
                        if isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "brain")
                                .font(.title2)
                        }
                        Text(isAnalyzing ? "分析中..." : "AI分析")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(foodEntryStore.todayEntries.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
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
        .sheet(isPresented: $showingOCRView) {
            NutritionOCRView()
                .environmentObject(foodStore)
                .environmentObject(foodEntryStore)
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView()
                .environmentObject(foodStore)
                .environmentObject(foodEntryStore)
        }
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text(saveAlertMessage)
        }
        .alert("記録がありません", isPresented: $showingEmptySaveAlert) {
            Button("OK") { }
        } message: {
            Text("食材を選択してから保存してください")
        }
        .alert("分析対象がありません", isPresented: $showingEmptyAnalysisAlert) {
            Button("OK") { }
        } message: {
            Text("食材を選択してからAI分析を実行してください")
        }
    }
    
    private func saveTodayData() {
        let todayEntries = foodEntryStore.todayEntries
        guard !todayEntries.isEmpty else { return }
        
        // 今日の日付を取得
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        // 保存用データを作成
        var todayData: [[String: Any]] = []
        for entry in todayEntries {
            let foodData: [String: Any] = [
                "name": entry.food.name,
                "calories": entry.food.calories,
                "protein": entry.food.protein,
                "fat": entry.food.fat,
                "carbs": entry.food.carbs,
                "date": ISO8601DateFormatter().string(from: entry.date)
            ]
            todayData.append(foodData)
        }
        
        // 栄養成分の合計を計算
        let totalData: [String: Any] = [
            "date": dateString,
            "totalCalories": foodEntryStore.todayTotalCalories,
            "totalProtein": foodEntryStore.todayTotalProtein,
            "totalFat": foodEntryStore.todayTotalFat,
            "totalCarbs": foodEntryStore.todayTotalCarbs,
            "entries": todayData
        ]
        
        // UserDefaultsに日付をキーとして保存
        let userDefaults = UserDefaults.standard
        let key = "food_record_\(dateString)"
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: totalData)
            userDefaults.set(jsonData, forKey: key)
            
            // 保存済み日付リストを更新
            var savedDates = userDefaults.stringArray(forKey: "saved_food_dates") ?? []
            if !savedDates.contains(dateString) {
                savedDates.append(dateString)
                userDefaults.set(savedDates, forKey: "saved_food_dates")
            }
            
            // 成功メッセージを表示
            saveAlertMessage = "\(dateString)の食事記録を保存しました。\n合計: \(Int(foodEntryStore.todayTotalCalories))kcal"
            showingSaveAlert = true
            
            print("✅ 食事記録をローカルに保存: \(key)")
            print("  エントリー数: \(todayEntries.count)")
            print("  合計カロリー: \(foodEntryStore.todayTotalCalories)kcal")
            
        } catch {
            print("❌ 保存エラー: \(error.localizedDescription)")
            saveAlertMessage = "保存に失敗しました: \(error.localizedDescription)"
            showingSaveAlert = true
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
                case .failure(let error):
                    hasError = true
                    print("食事データ送信エラー: \(error.localizedDescription)")
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