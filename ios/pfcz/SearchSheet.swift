import SwiftUI

struct SearchSheet: View {
    let foodStore: FoodStore
    let onAdd: (Food, Int) -> Void
    @Binding var addedCount: Int
    @Binding var currentFoods: [(String, String, Int)]
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var searchResults: [Food] = []
    @State private var recentFoods: [Food] = []
    @State private var lastAddedFood: String? = nil
    
    // 既定量テーブル（暫定）
    private let defaultQuantities: [String: Int] = [
        "卵": 1,  // 1個
        "白米": 150,
        "鶏胸肉": 100,
        "牛乳": 200,
        "納豆": 1,  // 1パック
        "サラダチキン": 125
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 現在の食材リスト（上部に表示）
                if !currentFoods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("現在の食材")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("合計: \(currentFoods.reduce(0) { $0 + $1.2 }) kcal")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(currentFoods.enumerated()), id: \.element.0) { _, food in
                                    HStack(spacing: 4) {
                                        Text(food.0)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                        Text(food.1)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        food.0 == lastAddedFood 
                                            ? Color.green.opacity(0.3)
                                            : Color.green.opacity(0.1)
                                    )
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                food.0 == lastAddedFood
                                                    ? Color.green.opacity(0.6)
                                                    : Color.green.opacity(0.3),
                                                lineWidth: food.0 == lastAddedFood ? 2 : 1
                                            )
                                    )
                                    .scaleEffect(food.0 == lastAddedFood ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: lastAddedFood)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 32)
                        
                        Divider()
                    }
                    .background(Color(UIColor.systemGray6))
                }
                
                // 検索結果または最近の食材
                List {
                    if searchText.isEmpty {
                        // 最近の食材（10件）
                        Section {
                            ForEach(recentFoods.prefix(10), id: \.name) { food in
                                foodRow(food: food)
                            }
                        } header: {
                            Text("最近使った食材")
                                .font(.caption)
                        }
                    } else {
                        // 検索結果
                        if searchResults.isEmpty {
                            // 検索結果0件
                            Section {
                                Text("見つかりません")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical)
                                
                                // 汎用食品の提案
                                ForEach(genericFoods, id: \.name) { food in
                                    foodRow(food: food)
                                }
                            } header: {
                                Text("よく使われる食材")
                                    .font(.caption)
                            }
                        } else {
                            // 検索結果あり（最大50件）
                            ForEach(searchResults.prefix(50), id: \.name) { food in
                                foodRow(food: food)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("食材を検索")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "食材名を入力")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: searchText) { _, newValue in
            // debounce 300ms
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if !Task.isCancelled {
                    performSearch(query: newValue)
                }
            }
        }
        .onAppear {
            loadRecentFoods()
        }
    }
    
    // 食材行のビュー
    @ViewBuilder
    private func foodRow(food: Food) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.body)
                Text("\(Int(food.calories)) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 追加ボタン
            Button(action: {
                let quantity = defaultQuantities[food.name] ?? 100
                onAdd(food, quantity)
                
                // 強めのハプティクスフィードバック
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                // 追加した食材をハイライト
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    lastAddedFood = food.name
                }
                
                // 0.8秒後にハイライトを解除
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        if lastAddedFood == food.name {
                            lastAddedFood = nil
                        }
                    }
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("\(food.name)を追加")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let quantity = defaultQuantities[food.name] ?? 100
            onAdd(food, quantity)
            
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // 追加した食材をハイライト
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                lastAddedFood = food.name
            }
            
            // 0.8秒後にハイライトを解除
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    if lastAddedFood == food.name {
                        lastAddedFood = nil
                    }
                }
            }
        }
    }
    
    // 検索実行
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let normalizedQuery = query.normalizedForSearch()
        
        // 簡易検索（FoodStoreの全食材から）
        let allFoods = foodStore.foods
        
        // スコアリング
        searchResults = allFoods.compactMap { food in
            let normalizedName = food.name.normalizedForSearch()
            
            // 完全一致
            if normalizedName == normalizedQuery {
                return (food, 100)
            }
            // 前方一致
            else if normalizedName.hasPrefix(normalizedQuery) {
                return (food, 80)
            }
            // 単語包含
            else if normalizedName.components(separatedBy: " ").contains(normalizedQuery) {
                return (food, 60)
            }
            // 部分一致
            else if normalizedName.contains(normalizedQuery) {
                return (food, 40)
            }
            
            return nil
        }
        .sorted { $0.1 > $1.1 }
        .prefix(50)
        .map { $0.0 }
    }
    
    // 最近の食材を取得
    private func loadRecentFoods() {
        // TODO: 実装（過去14日、使用回数順、当日除外）
        // 暫定でお気に入りを表示
        recentFoods = [
            Food(name: "卵", protein: 6.0, fat: 5.0, carbs: 0.5, calories: 76),
            Food(name: "鶏胸肉", protein: 27.0, fat: 1.9, carbs: 0, calories: 108),
            Food(name: "白米", protein: 2.5, fat: 0.3, carbs: 37.0, calories: 168),
            Food(name: "納豆", protein: 8.0, fat: 5.0, carbs: 6.0, calories: 100),
            Food(name: "牛乳", protein: 3.3, fat: 3.8, carbs: 4.8, calories: 67),
            Food(name: "サラダチキン", protein: 27.0, fat: 1.2, carbs: 0.3, calories: 108)
        ]
    }
    
    // 汎用食品
    private var genericFoods: [Food] {
        [
            Food(name: "白米", protein: 2.5, fat: 0.3, carbs: 37.0, calories: 168),
            Food(name: "鶏胸肉", protein: 27.0, fat: 1.9, carbs: 0, calories: 108),
            Food(name: "卵", protein: 6.0, fat: 5.0, carbs: 0.5, calories: 76),
            Food(name: "牛乳", protein: 3.3, fat: 3.8, carbs: 4.8, calories: 67)
        ]
    }
}

// String拡張: 日本語検索の正規化
extension String {
    func normalizedForSearch() -> String {
        var result = self
        
        // 全角→半角
        result = result.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? result
        
        // ひらがな→カタカナ
        result = result.applyingTransform(.hiraganaToKatakana, reverse: false) ?? result
        
        // 余分な空白を削除
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 記号を除去（基本的な記号のみ）
        let symbolsToRemove = ["・", "･", "。", "、", "（", "）", "(", ")", "「", "」", "！", "？"]
        for symbol in symbolsToRemove {
            result = result.replacingOccurrences(of: symbol, with: "")
        }
        
        return result.lowercased()
    }
}

#Preview {
    SearchSheet(
        foodStore: FoodStore(),
        onAdd: { _, _ in },
        addedCount: .constant(0),
        currentFoods: .constant([])
    )
}