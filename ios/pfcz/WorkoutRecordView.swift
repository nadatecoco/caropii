import SwiftUI

struct WorkoutRecordView: View {
    var body: some View {
        VStack {
            Text("筋トレ記録画面")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("ここに筋トレ記録の入力欄が来ます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("筋トレ記録")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        WorkoutRecordView()
    }
}