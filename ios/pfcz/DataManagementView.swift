import SwiftUI

struct DataManagementView: View {
    @EnvironmentObject var foodStore: FoodStore
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // タイトル
            VStack(spacing: 10) {
                Text("データ管理")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("食材と睡眠データを管理")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 管理メニュー
            VStack(spacing: 20) {
                // 食材データ管理
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
                
                // 睡眠データ管理
                NavigationLink(destination: SleepDataView()) {
                    HStack {
                        Image(systemName: "moon.circle.fill")
                            .font(.title2)
                        Text("睡眠データの管理・履歴")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("データ管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        DataManagementView()
            .environmentObject(FoodStore())
    }
}