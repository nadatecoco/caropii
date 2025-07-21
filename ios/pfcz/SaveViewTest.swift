import SwiftUI

struct SaveViewTest: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    var body: some View {
        VStack {
            Text("環境オブジェクトテスト")
                .font(.title)
            
            Text("今日のカロリー: \(foodEntryStore.todayTotalCalories, specifier: "%.0f")")
                .padding()
            
            Text("登録食材数: \(foodStore.foods.count)")
                .padding()
        }
        .navigationTitle("環境オブジェクトテスト")
    }
}

#Preview {
    NavigationView {
        SaveViewTest()
            .environmentObject(FoodStore())
            .environmentObject(FoodEntryStore())
    }
}