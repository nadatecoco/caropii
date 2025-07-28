import SwiftUI

struct BodyMeasurementView: View {
    var body: some View {
        VStack {
            Text("体測定記録画面")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("ここに体重・体脂肪率・筋肉量の入力欄が来ます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("体測定記録")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        BodyMeasurementView()
    }
}