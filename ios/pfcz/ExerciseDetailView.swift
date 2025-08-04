import SwiftUI

struct ExerciseDetailView: View {
    let exerciseName: String
    
    @State private var weight: String = ""
    @State private var sets: [String] = ["", "", ""] // 初期3セット
    @State private var showingSaveAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // 重量入力
            VStack(alignment: .leading, spacing: 8) {
                Text("重量")
                    .font(.headline)
                HStack {
                    TextField("50", text: $weight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                    Text("kg")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // セット数入力
            VStack(alignment: .leading, spacing: 12) {
                Text("セット")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(0..<sets.count, id: \.self) { index in
                    HStack {
                        Text("\(index + 1)セット目")
                            .frame(width: 100, alignment: .leading)
                        TextField("10", text: $sets[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("回")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // セット追加ボタン
                if sets.count < 10 {
                    Button(action: addSet) {
                        Label("セットを追加", systemImage: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            
            Spacer()
            
            // 保存ボタン
            Button(action: { showingSaveAlert = true }) {
                Text("記録を保存")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("保存確認", isPresented: $showingSaveAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("保存") {
                saveExercise()
            }
        } message: {
            Text("\(exerciseName)の記録を保存しますか？")
        }
    }
    
    private func addSet() {
        if sets.count < 10 {
            sets.append("")
        }
    }
    
    private func saveExercise() {
        // TODO: 実際の保存処理とWorkoutRecordViewへのデータ渡し
        print("\(exerciseName): \(weight)kg, セット: \(sets)")
        dismiss()
    }
}

#Preview {
    NavigationView {
        ExerciseDetailView(exerciseName: "ベンチプレス")
    }
}