import SwiftUI

struct BodyMeasurementView: View {
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var bodyFat: String = ""
    @State private var muscleWeight: String = ""
    @State private var boneWeight: String = ""
    @State private var visceralFatLevel: String = ""
    @State private var basalMetabolism: String = ""
    @State private var bodyAge: String = ""
    @State private var bodyWaterRate: String = ""
    
    @State private var showConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本項目入力欄
                VStack(spacing: 15) {
                    Text("体測定データを入力")
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    // 身長
                    HStack {
                        Text("身長")
                            .frame(width: 80, alignment: .leading)
                        TextField("170.0", text: $height)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                    
                    // 体重
                    HStack {
                        Text("体重")
                            .frame(width: 80, alignment: .leading)
                        TextField("65.0", text: $weight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    
                    // 体脂肪率
                    HStack {
                        Text("体脂肪率")
                            .frame(width: 80, alignment: .leading)
                        TextField("15.0", text: $bodyFat)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    
                    // 筋肉量
                    HStack {
                        Text("筋肉量")
                            .frame(width: 80, alignment: .leading)
                        TextField("50.0", text: $muscleWeight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    
                    // 推定骨量
                    HStack {
                        Text("推定骨量")
                            .frame(width: 80, alignment: .leading)
                        TextField("3.0", text: $boneWeight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    
                    // 内臓脂肪レベル
                    HStack {
                        Text("内臓脂肪")
                            .frame(width: 80, alignment: .leading)
                        TextField("5", text: $visceralFatLevel)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        Text("レベル")
                            .foregroundColor(.secondary)
                    }
                    
                    // 基礎代謝
                    HStack {
                        Text("基礎代謝")
                            .frame(width: 80, alignment: .leading)
                        TextField("1500", text: $basalMetabolism)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        Text("kcal")
                            .foregroundColor(.secondary)
                    }
                    
                    // 体内年齢
                    HStack {
                        Text("体内年齢")
                            .frame(width: 80, alignment: .leading)
                        TextField("25", text: $bodyAge)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        Text("歳")
                            .foregroundColor(.secondary)
                    }
                    
                    // 体水分率
                    HStack {
                        Text("体水分率")
                            .frame(width: 80, alignment: .leading)
                        TextField("60.0", text: $bodyWaterRate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 記録ボタン
                Button(action: {
                    showConfirmation = true
                }) {
                    Text("記録する")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("体測定記録")
        .navigationBarTitleDisplayMode(.inline)
        .alert("記録確認", isPresented: $showConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("記録する") {
                // TODO: 記録処理
            }
        } message: {
            Text("入力されていない項目がありますが、このまま記録しますか？")
        }
    }
}

#Preview {
    NavigationView {
        BodyMeasurementView()
    }
}