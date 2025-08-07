import SwiftUI

struct ExerciseSelectionView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    // デフォルトの種目リスト
    let defaultExercises = [
        "ベンチプレス",
        "スクワット",
        "デッドリフト",
        "ショルダープレス",
        "ラットプルダウン",
        "レッグプレス",
        "ダンベルカール",
        "トライセプスエクステンション"
    ]
    
    var body: some View {
        List(defaultExercises, id: \.self) { exercise in
            NavigationLink(destination: ExerciseDetailView(exerciseName: exercise).environmentObject(dataManager)) {
                HStack {
                    Text(exercise)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("種目を選択")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        ExerciseSelectionView()
    }
}