import SwiftUI

struct SaveView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    @Environment(\.dismiss) private var dismiss
    
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
            
            // P/F/C表示（テキスト形式）
            HStack(spacing: 20) {
                VStack {
                    Text("P")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text("\(foodEntryStore.todayTotalProtein, specifier: "%.1f")g")
                        .font(.headline)
                }
                
                VStack {
                    Text("F")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(foodEntryStore.todayTotalFat, specifier: "%.1f")g")
                        .font(.headline)
                }
                
                VStack {
                    Text("C")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(foodEntryStore.todayTotalCarbs, specifier: "%.1f")g")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
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
            
            Spacer()
        }
        .padding()
        .navigationTitle("食事記録")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SaveView()
            .environmentObject(FoodStore())
            .environmentObject(FoodEntryStore())
    }
}