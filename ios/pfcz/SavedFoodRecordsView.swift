import SwiftUI

// 保存済み食事記録の日付一覧画面
struct SavedFoodRecordsView: View {
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    // 日付ごとにグループ化
    var groupedEntries: [(Date, [FoodEntry])] {
        let grouped = Dictionary(grouping: foodEntryStore.entries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        List {
            if groupedEntries.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("まだ記録がありません")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedEntries, id: \.0) { date, entries in
                    NavigationLink(destination: DailyFoodDetailView(date: date, entries: entries)
                        .environmentObject(foodEntryStore)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(date))
                                    .font(.headline)
                                Text("\(entries.count)件の記録")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(totalCalories(entries)) kcal")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Text("P:\(totalProtein(entries))g F:\(totalFat(entries))g C:\(totalCarbs(entries))g")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("保存済み記録")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 日付フォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if Calendar.current.isDateInToday(date) {
            return "今日"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨日"
        } else {
            formatter.dateFormat = "M月d日（E）"
            return formatter.string(from: date)
        }
    }
    
    // 合計計算
    private func totalCalories(_ entries: [FoodEntry]) -> Int {
        Int(entries.reduce(0) { $0 + $1.food.calories })
    }
    
    private func totalProtein(_ entries: [FoodEntry]) -> Int {
        Int(entries.reduce(0) { $0 + $1.food.protein })
    }
    
    private func totalFat(_ entries: [FoodEntry]) -> Int {
        Int(entries.reduce(0) { $0 + $1.food.fat })
    }
    
    private func totalCarbs(_ entries: [FoodEntry]) -> Int {
        Int(entries.reduce(0) { $0 + $1.food.carbs })
    }
}

#Preview {
    NavigationView {
        SavedFoodRecordsView()
            .environmentObject(FoodEntryStore())
    }
}