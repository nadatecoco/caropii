import SwiftUI

// 記録済みの筋トレデータ
struct WorkoutRecord: Identifiable {
    let id = UUID()
    let exerciseName: String
    let weight: String
    let sets: [String]
}

struct WorkoutRecordView: View {
    @StateObject private var dataManager = WorkoutDataManager()
    
    var body: some View {
        VStack {
            if dataManager.todayRecords.isEmpty {
                // 記録がない場合
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "dumbbell")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("今日の記録はまだありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                // 記録一覧表示
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(dataManager.todayRecords) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(record.exerciseName)
                                    .font(.headline)
                                HStack {
                                    Text("\(record.weight)kg")
                                        .foregroundColor(.secondary)
                                    Text("×")
                                        .foregroundColor(.secondary)
                                    Text("\(record.sets.count)セット")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            
            // トレーニング追加ボタン
            NavigationLink(destination: ExerciseSelectionView().environmentObject(dataManager)) {
                Label("トレーニングを追加", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("筋トレ記録")
        .navigationBarTitleDisplayMode(.inline)
    }
    
}

#Preview {
    NavigationView {
        WorkoutRecordView()
    }
}