import SwiftUI

// Slice 6: お気に入り機能を追加
struct FoodLogScreen: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    @StateObject private var dishStore = DishStore()
    
    // @Stateで削除可能なリストに変更（Food型で栄養データも保持）
    @State private var foods: [(Food, String, Int)] = []  // (Food型, 量表示, 総カロリー)
    
    @State private var showingSaveAlert = false
    
    // Slice 10: インライン編集用の状態
    @State private var editingIndex: Int? = nil
    @State private var editingValue: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var previousEditingIndex: Int? = nil
    
    // Slice 14: 使用頻度管理
    @AppStorage("foodUsageCount") private var usageCountData: Data = Data()
    @State private var usageCount: [String: Int] = [:]
    @State private var sortedFavorites: [(Food, String, Int)] = []
    
    // 食材検索シート表示用
    @State private var showingSearchSheet = false
    @State private var addedItemsCount = 0
    
    // OCR/バーコード表示用
    @State private var showingBarcodeScan = false
    @State private var showingNutritionOCR = false
    
    // 料理作成画面表示用
    @State private var showingDishCreation = false
    
    // AI分析用
    @State private var isAnalyzing = false
    @State private var showingAnalysisResult = false
    @State private var showingEmptyAnalysisAlert = false
    @State private var analysisText: String = ""
    
    // Slice 13: お気に入り食材（6個に拡張）
    var defaultFavorites: [(Food, String, Int)] {
        var favorites: [(Food, String, Int)] = []
        
        // FoodStoreから個別に取得（見つからない食材はスキップ）
        if let egg = foodStore.foods.first(where: { $0.name == "卵" }) {
            favorites.append((egg, "1個", Int(egg.calories * 0.5)))  // 1個=50g
        }
        if let chickenBreast = foodStore.foods.first(where: { $0.name == "鶏胸肉" }) {
            favorites.append((chickenBreast, "100g", Int(chickenBreast.calories)))  // 100g
        }
        if let rice = foodStore.foods.first(where: { $0.name == "白米" }) {
            favorites.append((rice, "150g", Int(rice.calories * 1.5)))  // 150g
        }
        if let natto = foodStore.foods.first(where: { $0.name == "納豆" }) {
            favorites.append((natto, "1パック", Int(natto.calories * 0.5)))  // 1パック=50g
        }
        if let milk = foodStore.foods.first(where: { $0.name == "牛乳" }) {
            favorites.append((milk, "200ml", Int(milk.calories * 2.0)))  // 200ml
        }
        if let saladChicken = foodStore.foods.first(where: { $0.name == "サラダチキン" }) {
            favorites.append((saladChicken, "125g", Int(saladChicken.calories * 1.25)))  // 125g
        }
        
        return favorites
    }
    
    // Slice 14: お気に入りの参照（画面中は固定）
    var favorites: [(Food, String, Int)] {
        sortedFavorites.isEmpty ? defaultFavorites : sortedFavorites
    }
    
    // 合計カロリーを計算
    var totalCalories: Int {
        foods.reduce(0) { $0 + $1.2 }
    }
    
    // PFC計算（FoodStoreの正確なデータを使用）
    var totalProtein: Double {
        foods.reduce(0.0) { total, item in
            let multiplier = calculateMultiplier(food: item.0, quantity: item.1)
            return total + (item.0.protein * multiplier)
        }
    }
    
    var totalFat: Double {
        foods.reduce(0.0) { total, item in
            let multiplier = calculateMultiplier(food: item.0, quantity: item.1)
            return total + (item.0.fat * multiplier)
        }
    }
    
    var totalCarbs: Double {
        foods.reduce(0.0) { total, item in
            let multiplier = calculateMultiplier(food: item.0, quantity: item.1)
            return total + (item.0.carbs * multiplier)
        }
    }
    
    // 下部のお気に入りと保存ボタン
    @ViewBuilder
    private var bottomView: some View {
        VStack(spacing: 12) {
            // ボタンを横並びに配置
            HStack(spacing: 12) {
                // その他の食材を追加ボタン
                Button(action: {
                    showingSearchSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("食材を追加")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // 料理を作るボタン
                Button(action: {
                    showingDishCreation = true
                }) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20))
                        Text("料理を作る")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
            
            // 作った料理（お気に入りの代わり）
            VStack(alignment: .leading, spacing: 8) {
                Text("作った料理")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // 作った料理があれば表示、なければお気に入りを表示
                if !dishStore.availableDishes().isEmpty {
                    // 作った料理を横スクロールで表示
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(dishStore.availableDishes()) { dish in
                                Button(action: {
                                    // 料理を追加（次のスライスで実装）
                                    print("料理を選択: \(dish.name)")
                                }) {
                                    VStack(spacing: 4) {
                                        Text(dish.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(残り"\(Int(dish.remainingWeight))g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 100)
                                    .padding(.vertical, 12)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // お気に入りを表示
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(favorites, id: \.0.id) { favorite in
                            Button(action: {
                                addFavorite(favorite)
                            }) {
                                VStack(spacing: 4) {
                                    Text(favorite.0.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(favorite.1)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 保存とAI分析ボタン
            HStack(spacing: 12) {
                // 保存ボタン
                Button(action: {
                    saveCurrentFoods()
                }) {
                    Text("記録を保存")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // AI分析ボタン
                Button(action: {
                    if !isAnalyzing {  // 分析中でない場合のみ実行
                        analyzeWithAI()
                    }
                }) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "brain")
                        }
                        Text(isAnalyzing ? "分析中..." : "AI分析")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAnalyzing ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isAnalyzing)  // 分析中はボタンを無効化
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // 上部のヘッダービュー
    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("食事記録")
                .font(.title)
                .padding(.horizontal)
            
            // Slice 4: 合計カロリー表示（PFC付き）
            HStack {
                Text("合計")
                    .font(.headline)
                
                Spacer()
                
                // PFC数値を1行で表示（小数点1桁まで）
                HStack(spacing: 12) {
                    Text(String(format: "P:%.1f", totalProtein))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "F:%.1f", totalFat))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "C:%.1f", totalCarbs))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(totalCalories) kcal")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // 操作ヒント
            Text("タップで追加 ／ 左スワイプで減らす ／ 右スワイプで削除")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 上部固定エリア
                headerView
                
                // スワイプ削除可能なリスト（中央エリア）
                List {
                    ForEach(Array(foods.enumerated()), id: \.element.0.id) { index, food in
                        foodRow(index: index, food: food)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if editingIndex != nil && editingIndex != index {
                                finishEditing()
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                foods.remove(at: index)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                quickReduce(at: index)
                            } label: {
                                Label("減らす", systemImage: "minus.circle.fill")
                            }
                            .tint(.orange)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // 下部固定エリア（お気に入りと保存ボタン）
                bottomView
            }
            .navigationTitle("今日の食事")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Menu {
                    Button(action: {
                        showingBarcodeScan = true
                    }) {
                        Label("バーコードスキャン", systemImage: "barcode.viewfinder")
                    }
                    
                    Button(action: {
                        showingNutritionOCR = true
                    }) {
                        Label("栄養成分を撮影", systemImage: "camera.fill")
                    }
                } label: {
                    Image(systemName: "camera")
                        .font(.body)
                }
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if let index = editingIndex {
                    let food = foods[index]
                    if food.0.name == "卵" {
                        Button("-1") { adjustValue(-1) }
                        Button("+1") { adjustValue(1) }
                    } else {
                        Button("-50") { adjustValue(-50) }
                        Button("-10") { adjustValue(-10) }
                        Button("+10") { adjustValue(10) }
                        Button("+50") { adjustValue(50) }
                    }
                    
                    Spacer()
                    
                    Button("完了") {
                        finishEditing()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("\(foods.count)件の食事記録を保存しました")
        }
        .onAppear {
            loadUsageCount()
            sortFavoritesByUsage()
        }
        .sheet(isPresented: $showingSearchSheet) {
            // foodsを(String, String, Int)型に変換
            let simpleFoods = Binding<[(String, String, Int)]>(
                get: { foods.map { ($0.0.name, $0.1, $0.2) } },
                set: { _ in }  // 読み取り専用
            )
            
            SearchSheet(
                foodStore: foodStore,
                onAdd: { food, quantity in
                    addFoodFromSearch(food, quantity: quantity)
                },
                addedCount: $addedItemsCount,
                currentFoods: simpleFoods
            )
            .onDisappear {
                addedItemsCount = 0
            }
        }
        .sheet(isPresented: $showingBarcodeScan) {
            BarcodeScannerView()
                .environmentObject(foodStore)
                .environmentObject(foodEntryStore)
        }
        .sheet(isPresented: $showingNutritionOCR) {
            NutritionOCRView()
                .environmentObject(foodStore)
                .environmentObject(foodEntryStore)
        }
        .sheet(isPresented: $showingDishCreation) {
            DishCreationView()
                .environmentObject(foodStore)
        }
        .sheet(isPresented: $showingAnalysisResult) {
            AnalysisResultView(analysisText: analysisText)
        }
        .alert("分析対象がありません", isPresented: $showingEmptyAnalysisAlert) {
            Button("OK") { }
        } message: {
            Text("食材を選択してからAI分析を実行してください")
        }
    }
    
    // お気に入り追加処理
    private func addFavorite(_ favorite: (Food, String, Int)) {
        if let index = foods.firstIndex(where: { $0.0.name == favorite.0.name }) {
            let current = foods[index]
            let newFood: (Food, String, Int)
            
            if favorite.0.name == "卵" {
                let currentCount = Int(current.1.replacingOccurrences(of: "個", with: "")) ?? 1
                let newCount = currentCount + 1
                let newCalories = Int(favorite.0.calories * Double(newCount) * 0.5)  // 1個=50g
                newFood = (favorite.0, "\(newCount)個", newCalories)
            } else if favorite.0.name == "納豆" {
                let currentPacks = Int(current.1.replacingOccurrences(of: "パック", with: "")) ?? 1
                let newPacks = currentPacks + 1
                let newCalories = Int(favorite.0.calories * Double(newPacks) * 0.5)  // 1パック=50g
                newFood = (favorite.0, "\(newPacks)パック", newCalories)
            } else if favorite.0.name == "牛乳" {
                let currentMl = Int(current.1.replacingOccurrences(of: "ml", with: "")) ?? 0
                let additionalMl = Int(favorite.1.replacingOccurrences(of: "ml", with: "")) ?? 0
                let newMl = currentMl + additionalMl
                let newCalories = Int(favorite.0.calories * Double(newMl) / 100.0)  // ml→100mlあたり
                newFood = (favorite.0, "\(newMl)ml", newCalories)
            } else {
                let currentGram = Int(current.1.replacingOccurrences(of: "g", with: "")) ?? 0
                let additionalGram = Int(favorite.1.replacingOccurrences(of: "g", with: "")) ?? 0
                let newGram = currentGram + additionalGram
                let newCalories = Int(favorite.0.calories * Double(newGram) / 100.0)  // g→100gあたり
                newFood = (favorite.0, "\(newGram)g", newCalories)
            }
            
            foods[index] = newFood
        } else {
            // 新規追加時もFoodオブジェクトのカロリーを正しく計算
            let newCalories: Int
            if favorite.0.name == "卵" {
                newCalories = Int(favorite.0.calories * 0.5)  // 1個=50g
            } else if favorite.0.name == "納豆" {
                newCalories = Int(favorite.0.calories * 0.5)  // 1パック=50g
            } else if favorite.0.name == "牛乳" {
                let ml = Int(favorite.1.replacingOccurrences(of: "ml", with: "")) ?? 200
                newCalories = Int(favorite.0.calories * Double(ml) / 100.0)  // ml→100mlあたり
            } else {
                let gram = Int(favorite.1.replacingOccurrences(of: "g", with: "")) ?? 100
                newCalories = Int(favorite.0.calories * Double(gram) / 100.0)  // g→100gあたり
            }
            foods.append((favorite.0, favorite.1, newCalories))
        }
        
        usageCount[favorite.0.name] = (usageCount[favorite.0.name] ?? 0) + 1
        saveUsageCount()
    }
    
    // 左スワイプで減算
    private func quickReduce(at index: Int) {
        guard index < foods.count else { return }
        let current = foods[index]
        
        if current.0.name == "卵" {
            let currentCount = Int(current.1.replacingOccurrences(of: "個", with: "")) ?? 1
            if currentCount > 1 {
                let newCount = currentCount - 1
                let newCalories = Int(current.0.calories * Double(newCount) * 0.5)  // 1個=50g
                foods[index] = (current.0, "\(newCount)個", newCalories)
            } else {
                foods.remove(at: index)
            }
        } else if current.0.name == "納豆" {
            let currentPacks = Int(current.1.replacingOccurrences(of: "パック", with: "")) ?? 1
            if currentPacks > 1 {
                let newPacks = currentPacks - 1
                let newCalories = Int(current.0.calories * Double(newPacks) * 0.5)  // 1パック=50g
                foods[index] = (current.0, "\(newPacks)パック", newCalories)
            } else {
                foods.remove(at: index)
            }
        } else if current.0.name == "牛乳" {
            let currentMl = Int(current.1.replacingOccurrences(of: "ml", with: "")) ?? 0
            if currentMl > 200 {
                let newMl = currentMl - 200
                let newCalories = Int(current.0.calories * Double(newMl) / 100.0)  // ml→100mlあたり
                foods[index] = (current.0, "\(newMl)ml", newCalories)
            } else {
                foods.remove(at: index)
            }
        } else {
            let currentGram = Int(current.1.replacingOccurrences(of: "g", with: "")) ?? 0
            let decrementGram: Int
            
            switch current.0.name {
            case "鶏胸肉", "サラダチキン":
                decrementGram = 100
            default:
                decrementGram = 150
            }
            
            if currentGram > decrementGram {
                let newGram = currentGram - decrementGram
                let newCalories = Int(current.0.calories * Double(newGram) / 100.0)  // g→100gあたり
                foods[index] = (current.0, "\(newGram)g", newCalories)
            } else {
                foods.remove(at: index)
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // 保存処理
    private func saveCurrentFoods() {
        for food in foods {
            // 量に応じた倍率を計算
            let multiplier = calculateMultiplier(food: food.0, quantity: food.1)
            
            let newFood = Food(
                name: food.0.name + " " + food.1,  // 例: "卵 2個"
                protein: food.0.protein * multiplier,
                fat: food.0.fat * multiplier,
                carbs: food.0.carbs * multiplier,
                calories: Double(food.2)
            )
            foodEntryStore.add(food: newFood)
        }
        
        showingSaveAlert = true
        foods.removeAll()
    }
    
    // 編集開始
    private func startEditing(at index: Int) {
        guard index < foods.count else { return }
        
        if let prevIndex = editingIndex, prevIndex != index {
            finishEditing()
        }
        
        let food = foods[index]
        editingIndex = index
        previousEditingIndex = index
        
        if food.0.name == "卵" {
            editingValue = food.1.replacingOccurrences(of: "個", with: "")
        } else if food.0.name == "納豆" {
            editingValue = food.1.replacingOccurrences(of: "パック", with: "")
        } else if food.0.name == "牛乳" {
            editingValue = food.1.replacingOccurrences(of: "ml", with: "")
        } else {
            editingValue = food.1.replacingOccurrences(of: "g", with: "")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }
    
    // 編集完了
    private func finishEditing() {
        guard let index = editingIndex, index < foods.count else {
            editingIndex = nil
            isTextFieldFocused = false
            return
        }
        
        if let value = Int(editingValue), value > 0 {
            let food = foods[index]
            if food.0.name == "卵" {
                let validValue = min(value, 99)
                let newCalories = Int(food.0.calories * Double(validValue) * 0.5)  // 1個=50g
                foods[index] = (food.0, "\(validValue)個", newCalories)
            } else if food.0.name == "納豆" {
                let validValue = min(value, 10)
                let newCalories = Int(food.0.calories * Double(validValue) * 0.5)  // 1パック=50g
                foods[index] = (food.0, "\(validValue)パック", newCalories)
            } else if food.0.name == "牛乳" {
                let validValue = min(value, 2000)
                let newCalories = Int(food.0.calories * Double(validValue) / 100.0)  // ml→100mlあたり
                foods[index] = (food.0, "\(validValue)ml", newCalories)
            } else {
                let validValue = min(value, 9999)
                let caloriesPerGram: Double
                switch food.0.name {
                case "鶏胸肉", "サラダチキン":
                    caloriesPerGram = 1.08
                default:
                    caloriesPerGram = 1.68
                }
                foods[index] = (food.0, "\(validValue)g", Int(Double(validValue) * caloriesPerGram))
            }
        } else if editingValue.isEmpty || editingValue == "0" {
            let food = foods[index]
            if food.0.name == "卵" {
                editingValue = food.1.replacingOccurrences(of: "個", with: "")
            } else if food.0.name == "納豆" {
                editingValue = food.1.replacingOccurrences(of: "パック", with: "")
            } else if food.0.name == "牛乳" {
                editingValue = food.1.replacingOccurrences(of: "ml", with: "")
            } else {
                editingValue = food.1.replacingOccurrences(of: "g", with: "")
            }
        }
        
        editingIndex = nil
        isTextFieldFocused = false
        previousEditingIndex = nil
    }
    
    // 値の調整
    private func adjustValue(_ delta: Int) {
        guard let index = editingIndex, index < foods.count else { return }
        
        guard let current = Int(editingValue) else {
            editingValue = "0"
            return
        }
        
        let newValue = max(0, current + delta)
        editingValue = String(newValue)
    }
    
    // 量から倍率を計算（100gあたりの栄養価に対する倍率）
    private func calculateMultiplier(food: Food, quantity: String) -> Double {
        // 単位を除去して数値を取得
        let numericString = quantity.replacingOccurrences(of: "個", with: "")
            .replacingOccurrences(of: "パック", with: "")
            .replacingOccurrences(of: "ml", with: "")
            .replacingOccurrences(of: "g", with: "")
        
        guard let value = Double(numericString) else { return 1.0 }
        
        // 食材に応じた基準量に対する倍率を返す
        switch food.name {
        case "卵":
            return value * 0.5  // 1個 = 50g
        case "納豆":
            return value * 0.5  // 1パック = 50g  
        case "牛乳":
            return value / 100.0  // ml → 100mlあたり
        default:
            return value / 100.0  // g → 100gあたり
        }
    }
    
    // 食材に応じた単位を返す
    private func unitForFood(_ foodName: String) -> String {
        switch foodName {
        case "卵":
            return "個"
        case "納豆":
            return "パック"
        case "牛乳":
            return "ml"
        default:
            return "g"
        }
    }
    
    // 行のビューを分離
    @ViewBuilder
    private func foodRow(index: Int, food: (Food, String, Int)) -> some View {
        HStack {
            Text(food.0.name)
                .font(.body)
            
            // クイック調整ボタン
            if editingIndex != index {
                HStack(spacing: 8) {
                    Button(action: {
                        quickAdjust(at: index, isIncrease: false)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        quickAdjust(at: index, isIncrease: true)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
            
            // 量表示とインライン編集
            if editingIndex != index {
                Button(action: {
                    startEditing(at: index)
                }) {
                    Text(food.1)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                        .frame(minWidth: 50)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                HStack(spacing: 4) {
                    TextField("0", text: $editingValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .focused($isTextFieldFocused)
                        .onChange(of: editingValue) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                editingValue = filtered
                            }
                        }
                        .onSubmit {
                            finishEditing()
                        }
                    
                    Text(unitForFood(food.0.name))
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(food.2) kcal")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
    
    // クイック調整メソッド
    private func quickAdjust(at index: Int, isIncrease: Bool) {
        guard index < foods.count else { return }
        
        let current = foods[index]
        
        let numericString = current.1.replacingOccurrences(of: "個", with: "")
            .replacingOccurrences(of: "パック", with: "")
            .replacingOccurrences(of: "ml", with: "")
            .replacingOccurrences(of: "g", with: "")
        
        let currentValue = Int(numericString) ?? 0
        
        let delta: Int
        if currentValue < 10 {
            delta = 1
        } else if currentValue < 100 {
            delta = 10
        } else {
            delta = 50
        }
        
        let newValue = isIncrease ? currentValue + delta : max(1, currentValue - delta)
        
        var newAmount: String
        var newCalories: Int
        
        if current.0.name == "卵" {
            newAmount = "\(newValue)個"
            newCalories = Int(current.0.calories * Double(newValue) * 0.5)  // 1個=50g
        } else if current.0.name == "納豆" {
            newAmount = "\(newValue)パック"
            newCalories = Int(current.0.calories * Double(newValue) * 0.5)  // 1パック=50g
        } else if current.0.name == "牛乳" {
            newAmount = "\(newValue)ml"
            newCalories = Int(current.0.calories * Double(newValue) / 100.0)  // ml→100mlあたり
        } else {
            newAmount = "\(newValue)g"
            newCalories = Int(current.0.calories * Double(newValue) / 100.0)  // g→100gあたり
        }
        
        foods[index] = (current.0, newAmount, newCalories)
    }
    
    // 使用頻度の保存と読み込み
    private func saveUsageCount() {
        if let data = try? JSONEncoder().encode(usageCount) {
            usageCountData = data
        }
    }
    
    private func loadUsageCount() {
        if let decoded = try? JSONDecoder().decode([String: Int].self, from: usageCountData) {
            usageCount = decoded
        }
    }
    
    // 画面表示時にソート
    private func sortFavoritesByUsage() {
        sortedFavorites = defaultFavorites.sorted { first, second in
            let firstCount = usageCount[first.0.name] ?? 0
            let secondCount = usageCount[second.0.name] ?? 0
            return firstCount > secondCount
        }
    }
    
    // 検索から食材追加
    private func addFoodFromSearch(_ food: Food, quantity: Int) {
        let multiplier = Double(quantity) / 100.0  // 100gあたりの倍率
        let totalCalories = Int(food.calories * multiplier)
        let foodTuple = (food, "\(quantity)g", totalCalories)
        
        if let index = foods.firstIndex(where: { $0.0.name == food.name }) {
            // 既存の食材に加算
            let current = foods[index]
            let currentValue = Int(current.1.replacingOccurrences(of: "g", with: "")
                .replacingOccurrences(of: "個", with: "")
                .replacingOccurrences(of: "ml", with: "")
                .replacingOccurrences(of: "パック", with: "")) ?? 0
            let newValue = currentValue + quantity
            let newCalories = Int(food.calories * Double(newValue) / 100.0)
            foods[index] = (food, "\(newValue)g", newCalories)
        } else {
            // 新規追加
            foods.append(foodTuple)
        }
        
        addedItemsCount += 1
    }
    
    // AI分析実行
    private func analyzeWithAI() {
        // 食材がない場合はアラート表示
        if foods.isEmpty {
            showingEmptyAnalysisAlert = true
            return
        }
        
        isAnalyzing = true
        
        // 現在の食材リストからFoodEntryを作成
        var foodsToAnalyze: [Food] = []
        for food in foods {
            let multiplier = calculateMultiplier(food: food.0, quantity: food.1)
            let analyzableFood = Food(
                name: food.0.name + " " + food.1,
                protein: food.0.protein * multiplier,
                fat: food.0.fat * multiplier,
                carbs: food.0.carbs * multiplier,
                calories: Double(food.2)
            )
            foodsToAnalyze.append(analyzableFood)
        }
        
        // Railsサーバーに新しいデータを送信
        let group = DispatchGroup()
        var hasError = false
        
        for food in foodsToAnalyze {
            group.enter()
            APIService.shared.sendFoodEntry(food: food) { result in
                if case .failure = result {
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
                        self.analysisText = analysis
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
    FoodLogScreen()
        .environmentObject(FoodStore())
        .environmentObject(FoodEntryStore())
}
