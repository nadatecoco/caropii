import SwiftUI

// 特定の日付の食事記録詳細画面
struct DailyFoodDetailView: View {
    let date: Date
    let entries: [FoodEntry]
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    // 合計計算
    var totalCalories: Double {
        entries.reduce(0) { $0 + $1.food.calories }
    }
    
    var totalProtein: Double {
        entries.reduce(0) { $0 + $1.food.protein }
    }
    
    var totalFat: Double {
        entries.reduce(0) { $0 + $1.food.fat }
    }
    
    var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.food.carbs }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 合計表示
            VStack(spacing: 12) {
                HStack {
                    Text("合計")
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(Int(totalCalories)) kcal")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("P: \(Int(totalProtein))g F: \(Int(totalFat))g C: \(Int(totalCarbs))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                // 記録件数
                HStack {
                    Label("\(entries.count)件の記録", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            // 食事リスト
            List {
                ForEach(entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.food.name)
                                .font(.body)
                            Text(entry.date, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(entry.food.calories)) kcal")
                                .foregroundColor(.blue)
                            Text("P:\(Int(entry.food.protein)) F:\(Int(entry.food.fat)) C:\(Int(entry.food.carbs))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle(formatDate(date))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 日付フォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if Calendar.current.isDateInToday(date) {
            return "今日の記録"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨日の記録"
        } else {
            formatter.dateFormat = "M月d日（E）"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    NavigationView {
        DailyFoodDetailView(
            date: Date(),
            entries: []
        )
        .environmentObject(FoodEntryStore())
    }
}