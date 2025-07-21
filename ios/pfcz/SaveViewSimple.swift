import SwiftUI

struct SaveViewSimple: View {
    var body: some View {
        VStack {
            Text("保存画面テスト")
                .font(.title)
            Text("この画面が表示されれば基本的なナビゲーションは動作しています")
                .padding()
        }
        .navigationTitle("テスト保存画面")
    }
}

#Preview {
    NavigationView {
        SaveViewSimple()
    }
}