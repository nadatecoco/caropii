import SwiftUI

// Slice 2: スワイプ削除機能を追加
struct FoodLogScreen: View {
    // @Stateで削除可能なリストに変更
    @State private var foods = [
        ("卵", "1個", "76kcal"),
        ("白米", "150g", "252kcal"),
        ("鶏胸肉", "100g", "108kcal")
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("食事記録")
                    .font(.title)
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
                            
                            Text(food.2)  // カロリー
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
            }
            .navigationTitle("今日の食事")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FoodLogScreen()
}