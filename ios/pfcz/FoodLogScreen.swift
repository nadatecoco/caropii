import SwiftUI

// Slice 6: お気に入り機能を追加
struct FoodLogScreen: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    // @Stateで削除可能なリストに変更
    @State private var foods: [(String, String, Int)] = []
    
    @State private var showingSaveAlert = false
    
    // Slice 10: インライン編集用の状態
    @State private var editingIndex: Int? = nil
    @State private var editingValue: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var previousEditingIndex: Int? = nil
    
    // Slice 14: 使用頻度管理
    @AppStorage("foodUsageCount") private var usageCountData: Data = Data()
    @State private var usageCount: [String: Int] = [:]
    @State private var sortedFavorites: [(String, String, Int)] = []
    
    // Slice 13: お気に入り食材（6個に拡張）
    let defaultFavorites = [
        ("卵", "1個", 76),
        ("鶏胸肉", "100g", 108),
        ("白米", "150g", 252),
        ("納豆", "1パック", 100),
        ("牛乳", "200ml", 134),
        ("サラダチキン", "125g", 135)
    ]
    
    // Slice 14: お気に入りの参照（画面中は固定）
    var favorites: [(String, String, Int)] {
        sortedFavorites.isEmpty ? defaultFavorites : sortedFavorites
    }
    
    // 合計カロリーを計算
    var totalCalories: Int {
        foods.reduce(0) { $0 + $1.2 }
    }
    
    // PFC計算（仮の値）
    var totalProtein: Int {
        // 簡易計算: カロリーの20%をタンパク質とする
        foods.reduce(0) { total, food in
            if food.0 == "卵" {
                return total + 6 * (Int(food.1.replacingOccurrences(of: "個", with: "")) ?? 0)
            } else if food.0 == "鶏胸肉" || food.0 == "サラダチキン" {
                return total + (Int(food.1.replacingOccurrences(of: "g", with: "")) ?? 0) / 4
            } else if food.0 == "納豆" {
                return total + 8 * (Int(food.1.replacingOccurrences(of: "パック", with: "")) ?? 0)
            }
            return total + 2
        }
    }
    
    var totalFat: Int {
        // 簡易計算
        foods.reduce(0) { total, food in
            if food.0 == "卵" {
                return total + 5 * (Int(food.1.replacingOccurrences(of: "個", with: "")) ?? 0)
            } else if food.0 == "牛乳" {
                return total + (Int(food.1.replacingOccurrences(of: "ml", with: "")) ?? 0) / 25
            }
            return total + 3
        }
    }
    
    var totalCarbs: Int {
        // 簡易計算
        foods.reduce(0) { total, food in
            if food.0 == "白米" {
                return total + (Int(food.1.replacingOccurrences(of: "g", with: "")) ?? 0) * 37 / 100
            } else if food.0 == "牛乳" {
                return total + (Int(food.1.replacingOccurrences(of: "ml", with: "")) ?? 0) / 20
            }
            return total + 5
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .leading, spacing: 16) {
                Text("食事記録")
                    .font(.title)
                    .padding(.horizontal)
                
                // Slice 4: 合計カロリー表示（PFC付き）
                HStack {
                    Text("合計")
                        .font(.headline)
                    
                    Spacer()
                    
                    // PFC数値を1行で表示
                    HStack(spacing: 12) {
                        Text("P:\(totalProtein)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("F:\(totalFat)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("C:\(totalCarbs)")
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
                
                // Slice 13: お気に入り（グリッド表示で6個）
                VStack(alignment: .leading, spacing: 8) {
                    Text("お気に入り")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(favorites, id: \.0) { favorite in
                            Button(action: {
                                // Slice 8: 既存があれば加算、なければ新規追加
                                if let index = foods.firstIndex(where: { $0.0 == favorite.0 }) {
                                    // 既存の食材を加算（個数を増やす）
                                    let current = foods[index]
                                    let newFood: (String, String, Int)
                                    
                                    if favorite.0 == "卵" {
                                        // 卵の場合：個数を増やす
                                        let currentCount = Int(current.1.replacingOccurrences(of: "個", with: "")) ?? 1
                                        newFood = (current.0, "\(currentCount + 1)個", current.2 + favorite.2)
                                    } else if favorite.0 == "納豆" {
                                        // 納豆の場合：パック数を増やす
                                        let currentPacks = Int(current.1.replacingOccurrences(of: "パック", with: "")) ?? 1
                                        newFood = (current.0, "\(currentPacks + 1)パック", current.2 + favorite.2)
                                    } else if favorite.0 == "牛乳" {
                                        // 牛乳の場合：mlを増やす
                                        let currentMl = Int(current.1.replacingOccurrences(of: "ml", with: "")) ?? 0
                                        let additionalMl = Int(favorite.1.replacingOccurrences(of: "ml", with: "")) ?? 0
                                        newFood = (current.0, "\(currentMl + additionalMl)ml", current.2 + favorite.2)
                                    } else {
                                        // グラムの場合：量を増やす
                                        let currentGram = Int(current.1.replacingOccurrences(of: "g", with: "")) ?? 0
                                        let additionalGram = Int(favorite.1.replacingOccurrences(of: "g", with: "")) ?? 0
                                        newFood = (current.0, "\(currentGram + additionalGram)g", current.2 + favorite.2)
                                    }
                                    
                                    foods[index] = newFood
                                } else {
                                    // 新規追加
                                    foods.append(favorite)
                                }
                                
                                // Slice 14: 使用回数をカウント
                                usageCount[favorite.0] = (usageCount[favorite.0] ?? 0) + 1
                                saveUsageCount()
                            }) {
                                VStack(spacing: 4) {
                                    Text(favorite.0)
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
                
                // 操作ヒント
                Text("タップで追加 ／ 左スワイプで減らす ／ 右スワイプで削除")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // スワイプ削除可能なリスト
                List {
                    ForEach(Array(foods.enumerated()), id: \.element.0) { index, food in
                        foodRow(index: index, food: food)
                        .contentShape(Rectangle())  // Slice 12: タップ領域を行全体に
                        .onTapGesture {
                            // Slice 12: 編集中でない部分をタップしたら編集終了
                            if editingIndex != nil && editingIndex != index {
                                finishEditing()
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                // 右スワイプで削除
                                foods.remove(at: index)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                        // Slice 9a: 左スワイプで減算（軽い操作で即反応）
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                let current = foods[index]
                                
                                if current.0 == "卵" {
                                    // 卵の場合：1個減らす
                                    let currentCount = Int(current.1.replacingOccurrences(of: "個", with: "")) ?? 1
                                    if currentCount > 1 {
                                        foods[index] = (current.0, "\(currentCount - 1)個", current.2 - 76)
                                    } else {
                                        // 1個の場合は削除
                                        foods.remove(at: index)
                                    }
                                } else {
                                    // グラムの場合：既定量を減らす
                                    let currentGram = Int(current.1.replacingOccurrences(of: "g", with: "")) ?? 0
                                    let decrementGram = current.0 == "鶏胸肉" ? 100 : 150  // 既定量
                                    let caloriesPerGram = current.0 == "鶏胸肉" ? 1.08 : 1.68  // カロリー/g
                                    
                                    if currentGram > decrementGram {
                                        let newGram = currentGram - decrementGram
                                        let newCalories = Int(Double(newGram) * caloriesPerGram)
                                        foods[index] = (current.0, "\(newGram)g", newCalories)
                                    } else {
                                        // 既定量以下の場合は削除
                                        foods.remove(at: index)
                                    }
                                }
                                
                                // ハプティックフィードバック
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            } label: {
                                Label("減らす", systemImage: "minus.circle.fill")
                            }
                            .tint(.orange)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // Slice 5: 保存ボタン
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
                .padding(.horizontal)
                }
                .navigationTitle("今日の食事")
                .navigationBarTitleDisplayMode(.inline)
                // Slice 11: キーボードツールバー（ここに移動）
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        if let index = editingIndex {
                            let food = foods[index]
                            // 単位に応じたボタン
                            if food.0 == "卵" {
                                Button("-1") {
                                    adjustValue(-1)
                                }
                                Button("+1") {
                                    adjustValue(1)
                                }
                            } else {
                                Button("-50") {
                                    adjustValue(-50)
                                }
                                Button("-10") {
                                    adjustValue(-10)
                                }
                                Button("+10") {
                                    adjustValue(10)
                                }
                                Button("+50") {
                                    adjustValue(50)
                                }
                            }
                            
                            Spacer()
                            
                            Button("完了") {
                                finishEditing()
                            }
                            .fontWeight(.semibold)
                        }
                    }
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
            // 画面表示時に一度だけソート
            sortFavoritesByUsage()
        }
    }
    
    // Slice 5: 保存処理
    private func saveCurrentFoods() {
        // 実際のFoodオブジェクトを作成して保存
        for food in foods {
            let newFood = Food(
                name: food.0,
                protein: 10.0,  // 仮の値
                fat: 5.0,       // 仮の値
                carbs: 20.0,    // 仮の値
                calories: Double(food.2)
            )
            foodEntryStore.add(food: newFood)
        }
        
        showingSaveAlert = true
        
        // 保存後にリストを空にする（正しい動作）
        foods.removeAll()
    }
    
    // Slice 10: 編集開始
    private func startEditing(at index: Int) {
        // インデックスが有効か確認
        guard index < foods.count else { return }
        
        // Slice 12: 前の編集を保存
        if let prevIndex = editingIndex, prevIndex != index {
            finishEditing()
        }
        
        let food = foods[index]
        editingIndex = index
        previousEditingIndex = index
        
        // 数値部分だけ抽出
        if food.0 == "卵" {
            editingValue = food.1.replacingOccurrences(of: "個", with: "")
        } else if food.0 == "納豆" {
            editingValue = food.1.replacingOccurrences(of: "パック", with: "")
        } else if food.0 == "牛乳" {
            editingValue = food.1.replacingOccurrences(of: "ml", with: "")
        } else {
            editingValue = food.1.replacingOccurrences(of: "g", with: "")
        }
        
        // Slice 12: 少し遅延してフォーカス（SwiftUIの描画完了を待つ）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }
    
    // Slice 10: 編集完了
    private func finishEditing() {
        guard let index = editingIndex, index < foods.count else {
            editingIndex = nil
            isTextFieldFocused = false
            return
        }
        
        // Slice 12: 値検証と更新
        if let value = Int(editingValue), value > 0 {
            let food = foods[index]
            if food.0 == "卵" {
                // 卵の場合：個数とカロリー更新（最大99個まで）
                let validValue = min(value, 99)
                foods[index] = (food.0, "\(validValue)個", validValue * 76)
            } else {
                // グラムの場合：重量とカロリー更新（最大9999gまで）
                let validValue = min(value, 9999)
                let caloriesPerGram = food.0 == "鶏胸肉" ? 1.08 : 1.68
                foods[index] = (food.0, "\(validValue)g", Int(Double(validValue) * caloriesPerGram))
            }
        } else if editingValue.isEmpty || editingValue == "0" {
            // Slice 12: 0または空の場合は元の値に戻す
            let food = foods[index]
            if food.0 == "卵" {
                editingValue = food.1.replacingOccurrences(of: "個", with: "")
            } else {
                editingValue = food.1.replacingOccurrences(of: "g", with: "")
            }
        }
        
        editingIndex = nil
        isTextFieldFocused = false
        previousEditingIndex = nil
    }
    
    // Slice 11: 値の調整
    private func adjustValue(_ delta: Int) {
        guard let index = editingIndex, index < foods.count else { return }
        
        guard let current = Int(editingValue) else {
            editingValue = "0"
            return
        }
        
        let newValue = max(0, current + delta)
        editingValue = String(newValue)
    }
    
    // Slice 13: 食材に応じた単位を返す
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
    
    // Slice 10: 行のビューを分離（コンパイラ負荷軽減）
    @ViewBuilder
    private func foodRow(index: Int, food: (String, String, Int)) -> some View {
        HStack {
            Text(food.0)  // 食材名
                .font(.body)
            
            // クイック調整ボタン（左側に配置）
            if editingIndex != index {
                HStack(spacing: 8) {
                    // 減らすボタン
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
                    
                    // 増やすボタン
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
                // 量表示（タップで編集）
                Button(action: {
                    startEditing(at: index)
                }) {
                    Text(food.1)  // 量
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                        .frame(minWidth: 50)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // 編集モード
                HStack(spacing: 4) {
                    TextField("0", text: $editingValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .focused($isTextFieldFocused)
                        .onChange(of: editingValue) { _, newValue in
                            // Slice 12: 数字のみ許可
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                editingValue = filtered
                            }
                        }
                        .onSubmit {
                            finishEditing()
                        }
                    
                    // Slice 13: 単位表示を拡充
                    Text(unitForFood(food.0))
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(food.2) kcal")  // カロリー
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
    
    // クイック調整メソッド（桁数に応じた自動調整）
    private func quickAdjust(at index: Int, isIncrease: Bool) {
        guard index < foods.count else { return }
        
        let current = foods[index]
        
        // 現在の数値を抽出
        let numericString = current.1.replacingOccurrences(of: "個", with: "")
            .replacingOccurrences(of: "パック", with: "")
            .replacingOccurrences(of: "ml", with: "")
            .replacingOccurrences(of: "g", with: "")
        
        let currentValue = Int(numericString) ?? 0
        
        // 桁数に応じた調整量を決定
        let delta: Int
        if currentValue < 10 {
            delta = 1  // 1桁: ±1
        } else if currentValue < 100 {
            delta = 10  // 2桁: ±10
        } else {
            delta = 50  // 3桁以上: ±50
        }
        
        // 新しい値を計算
        let newValue = isIncrease ? currentValue + delta : max(1, currentValue - delta)
        
        // 単位と新しい文字列を生成
        var newAmount: String
        var newCalories: Int
        
        if current.0 == "卵" {
            newAmount = "\(newValue)個"
            newCalories = newValue * 76
        } else if current.0 == "納豆" {
            newAmount = "\(newValue)パック"
            newCalories = newValue * 100
        } else if current.0 == "牛乳" {
            newAmount = "\(newValue)ml"
            newCalories = Int(Double(newValue) * 0.67)
        } else {
            newAmount = "\(newValue)g"
            let caloriesPerGram: Double = (current.0 == "鶏胸肉" || current.0 == "サラダチキン") ? 1.08 : 1.68
            newCalories = Int(Double(newValue) * caloriesPerGram)
        }
        
        foods[index] = (current.0, newAmount, newCalories)
    }
    
    // Slice 14: 使用頻度の保存と読み込み
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
    
    // Slice 14改: 画面表示時にソート
    private func sortFavoritesByUsage() {
        sortedFavorites = defaultFavorites.sorted { first, second in
            let firstCount = usageCount[first.0] ?? 0
            let secondCount = usageCount[second.0] ?? 0
            return firstCount > secondCount
        }
    }
}

#Preview {
    FoodLogScreen()
        .environmentObject(FoodStore())
        .environmentObject(FoodEntryStore())
}