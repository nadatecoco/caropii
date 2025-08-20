import SwiftUI

struct SettingsView: View {
    @AppStorage("weightRounding") var weightRounding = "10"
    var body: some View {
        Form {
            Section("表示設定") {
                Picker("重さの決め方", selection: $weightRounding) {
                    Text("1g単位").tag("1")
                    Text("10g単位").tag("10")
                    Text("100g単位").tag("100")
                }
            }
        }
    }
}
