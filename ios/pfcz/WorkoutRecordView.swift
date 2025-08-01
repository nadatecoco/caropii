import SwiftUI

// 筋トレ記録の各行データ
struct WorkoutSet: Identifiable {
    let id = UUID()
    var exerciseName: String = ""
    var weight: String = ""
    var side: String = "右"
    var reps: [String] = ["", "", ""] // 初期3セット
}

struct WorkoutRecordView: View {
    @State private var workoutSets: [WorkoutSet] = (0..<10).map { _ in WorkoutSet() }
    @State private var showingSaveAlert = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // スクロール可能なコンテンツエリア
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach($workoutSets) { $workoutSet in
                            WorkoutRowView(workoutSet: $workoutSet)
                        }
                        
                        // 種目追加ボタン
                        Button(action: addNewSet) {
                            Label("種目を追加", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 20)
                    }
                    .padding()
                    .padding(.bottom, 100) // 保存ボタン分のスペース
                }
                
                Spacer()
            }
            
            // 固定保存ボタン
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    Button(action: { showingSaveAlert = true }) {
                        Text("今日の記録として保存")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                .background(Color(UIColor.systemBackground))
            }
        }
        .navigationTitle("筋トレ記録")
        .navigationBarTitleDisplayMode(.inline)
        .alert("保存確認", isPresented: $showingSaveAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("保存") {
                saveWorkout()
            }
        } message: {
            Text("今日の筋トレ記録を保存しますか？")
        }
    }
    
    private func addNewSet() {
        workoutSets.append(WorkoutSet())
    }
    
    private func saveWorkout() {
        // TODO: 実際の保存処理
        print("筋トレ記録を保存しました")
    }
}

// 1行レイアウトの入力行コンポーネント
struct WorkoutRowView: View {
    @Binding var workoutSet: WorkoutSet
    
    let sideOptions = ["右", "左", ""]
    
    var body: some View {
        HStack(spacing: 8) {
            // 種目名入力
            TextField("種目名", text: $workoutSet.exerciseName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            
            // 重量入力
            HStack(spacing: 2) {
                TextField("50", text: $workoutSet.weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 50)
                Text("kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 左右選択
            Menu {
                ForEach(sideOptions, id: \.self) { option in
                    Button(option.isEmpty ? "なし" : option) {
                        workoutSet.side = option
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    Text(workoutSet.side.isEmpty ? "-" : workoutSet.side)
                        .font(.system(size: 14))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            
            // セット数（回数入力）- 横スクロール対応
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<workoutSet.reps.count, id: \.self) { index in
                        TextField("5", text: $workoutSet.reps[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 35)
                            .font(.system(size: 14))
                    }
                    
                    // プラスボタン（最大10セットまで）
                    if workoutSet.reps.count < 10 {
                        Button(action: { workoutSet.reps.append("") }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                        }
                    }
                }
            }
            .frame(maxWidth: 200) // 横スクロールエリアの最大幅を制限
        }
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        WorkoutRecordView()
    }
}