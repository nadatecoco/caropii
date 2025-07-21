import SwiftUI

struct HomeView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // アプリタイトル
            VStack(spacing: 10) {
                Text("カロッピー")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("PFC 管理アプリ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // メインボタン
            VStack(spacing: 20) {
                NavigationLink(destination: SaveViewDebug()
                    .environmentObject(foodStore)
                    .environmentObject(foodEntryStore)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("今日の記録をする")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                NavigationLink(destination: FoodDatabaseView()
                    .environmentObject(foodStore)) {
                    HStack {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.title2)
                        Text("食材データを管理")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("ホーム")
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        HomeView()
            .environmentObject(FoodStore())
            .environmentObject(FoodEntryStore())
    }
}