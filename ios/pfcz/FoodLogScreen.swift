import SwiftUI

// Slice 5: 保存機能を追加
struct FoodLogScreen: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    // @Stateで削除可能なリストに変更
    @State private var foods = [
        ("卵", "1個", 76),  // カロリーを数値に変更
        ("白米", "150g", 252),
        ("鶏胸肉", "100g", 108)
    ]
    
    @State private var showingSaveAlert = false
    
    // 合計カロリーを計算
    var totalCalories: Int {
        foods.reduce(0) { $0 + $1.2 }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("食事記録")
                    .font(.title)
                    .padding(.horizontal)
                
                // Slice 4: 合計カロリー表示
                HStack {
                    Text("合計")
                        .font(.headline)
                    Spacer()
                    Text("\(totalCalories) kcal")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Slice 3: 卵を追加するボタン
                Button(action: {
                    // 卵を追加（固定値、数値型に修正）
                    foods.append(("卵", "1個", 76))
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("卵を追加")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // スワイプ削除可能なリスト
                List {
                    ForEach(Array(foods.enumerated()), id: \.offset) { index, food in
                        HStack {
                            Text(food.0)  // 食材名
                                .font(.body)
                            
                            Spacer()
                            
                            Text(food.1)  // 量
                                .foregroundColor(.secondary)
                            
                            Text("\(food.2) kcal")  // カロリー
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                // スワイプで削除
                                foods.remove(at: index)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
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
        }
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("\(foods.count)件の食事記録を保存しました")
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
}

#Preview {
    FoodLogScreen()
        .environmentObject(FoodStore())
        .environmentObject(FoodEntryStore())
}