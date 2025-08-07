import SwiftUI

struct ExerciseSelectionView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var exercises: [String] = []
    
    var body: some View {
        List(exercises, id: \.self) { exercise in
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
        .onAppear {
            loadExercises()
        }
    }
    
    private func loadExercises() {
        if let savedExercises = UserDefaults.standard.stringArray(forKey: "customExercises") {
            exercises = savedExercises
        } else {
            // デフォルト種目
            exercises = [
                "ベンチプレス",
                "スクワット",
                "デッドリフト",
                "ショルダープレス",
                "ラットプルダウン",
                "レッグプレス",
                "ダンベルカール",
                "トライセプスエクステンション"
            ]
        }
    }
}

#Preview {
    NavigationView {
        ExerciseSelectionView()
    }
}