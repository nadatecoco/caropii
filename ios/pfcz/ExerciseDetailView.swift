import SwiftUI

struct ExerciseDetailView: View {
    let exerciseName: String
    
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var sets: [SetData] = [
        SetData(),
        SetData(),
        SetData(),
        SetData()
    ] // 初期4セット
    @State private var isKg = true // true: kg, false: lbs
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 単位切り替えバー
            HStack {
                Spacer()
                HStack(spacing: 2) {
                    Button(action: { isKg = true }) {
                        Text("kg")
                            .font(.system(size: 14, weight: isKg ? .bold : .regular))
                            .foregroundColor(isKg ? .white : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isKg ? Color.blue : Color.clear)
                            .cornerRadius(4)
                    }
                    
                    Button(action: { isKg = false }) {
                        Text("lbs")
                            .font(.system(size: 14, weight: !isKg ? .bold : .regular))
                            .foregroundColor(!isKg ? .white : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(!isKg ? Color.blue : Color.clear)
                            .cornerRadius(4)
                    }
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
            }
            .padding()
            
            // セット一覧
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(sets.indices, id: \.self) { index in
                        SetRowView(
                            setNumber: index + 1,
                            setData: $sets[index],
                            isKg: isKg,
                            onReset: {
                                resetSet(at: index)
                            }
                        )
                        .onChange(of: sets[index]) {
                            autoSave()
                        }
                    }
                    
                    // セット追加ボタン
                    if sets.count < 10 {
                        Button(action: addSet) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("セットを追加")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addSet() {
        if sets.count < 10 {
            sets.append(SetData())
        }
    }
    
    private func resetSet(at index: Int) {
        sets[index].weight = ""
        sets[index].reps = ""
        sets[index].memo = ""
        sets[index].isCompleted = false
    }
    
    private func autoSave() {
        dataManager.updateRecord(exerciseName: exerciseName, sets: sets)
    }
}

// セット行ビュー
struct SetRowView: View {
    let setNumber: Int
    @Binding var setData: SetData
    let isKg: Bool
    let onReset: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // 行番号
                Text("\(setNumber)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 30)
                
                // 重さクリアボタン
                Button(action: { setData.weight = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                // 重さ入力
                HStack(spacing: 4) {
                    TextField("0", text: $setData.weight)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    
                    Text(isKg ? "kg" : "lbs")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                // 回数クリアボタン
                Button(action: { setData.reps = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                // 回数入力
                HStack(spacing: 4) {
                    TextField("0", text: $setData.reps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                    
                    Text("回")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 完了チェック
                Button(action: { 
                    setData.isCompleted.toggle()
                    if setData.isCompleted && (setData.weight.isEmpty || setData.reps.isEmpty) {
                        setData.isCompleted = false
                    }
                }) {
                    Image(systemName: setData.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(setData.isCompleted ? .green : .gray)
                        .frame(width: 30, height: 30)
                }
            }
            
            // メモ欄（番号の下は空白、入力欄と揃える）
            HStack(spacing: 8) {
                // 番号分のスペース
                Color.clear
                    .frame(width: 30)
                
                // メモクリアボタン
                Button(action: { setData.memo = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                // メモ入力
                TextField("メモ", text: $setData.memo)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 14))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(setData.isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    NavigationView {
        ExerciseDetailView(exerciseName: "ベンチプレス")
            .environmentObject(WorkoutDataManager())
    }
}