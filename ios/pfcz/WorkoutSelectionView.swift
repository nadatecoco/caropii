import SwiftUI

struct WorkoutSelectionView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // タイトル
            VStack(spacing: 10) {
                Text("記録を選択")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("どちらを記録しますか？")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 選択ボタン
            VStack(spacing: 20) {
                // 筋トレ記録ボタン
                Button(action: {
                    // TODO: 筋トレ記録画面に遷移
                }) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .font(.title2)
                        Text("筋トレ記録")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // 体測定記録ボタン
                Button(action: {
                    // TODO: 体測定記録画面に遷移
                }) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .font(.title2)
                        Text("体測定記録")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("記録選択")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        WorkoutSelectionView()
    }
}