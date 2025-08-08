import SwiftUI

struct WorkoutDataView: View {
    @StateObject private var healthService = HealthKitService()
    @State private var selectedTimeRange = 0 // 0: 今週, 1: 今月, 2: 全期間
    
    var body: some View {
        VStack {
            mainContent
            errorView
        }
        .navigationTitle("ワークアウト履歴")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await healthService.fetchWorkoutData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await healthService.fetchWorkoutData()
        }
    }
    
    // MARK: - サブビュー
    @ViewBuilder
    private var mainContent: some View {
        if healthService.isLoading {
            loadingView
        } else if healthService.workoutRecords.isEmpty {
            emptyView
        } else {
            dataView
        }
    }
    
    private var loadingView: some View {
        ProgressView("データを取得中...")
            .padding()
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text("ワークアウトデータがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("データを取得") {
                Task {
                    await healthService.fetchWorkoutData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var dataView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 期間セレクター
                Picker("期間", selection: $selectedTimeRange) {
                    Text("今週").tag(0)
                    Text("今月").tag(1)
                    Text("全期間").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // サマリカード
                summaryCard
                
                // ワークアウトリスト
                workoutList
            }
            .padding(.vertical)
        }
        .refreshable {
            await healthService.fetchWorkoutData()
        }
    }
    
    // MARK: - サマリカード
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("サマリ")
                .font(.headline)
            
            let filteredWorkouts = getFilteredWorkouts()
            let totalDuration = filteredWorkouts.reduce(0) { $0 + $1.duration }
            let totalCalories = filteredWorkouts.reduce(0) { $0 + ($1.totalCalories ?? 0) }
            let totalDistance = filteredWorkouts.reduce(0) { $0 + ($1.distance ?? 0) }
            
            VStack(spacing: 8) {
                HStack {
                    Label("合計時間", systemImage: "clock")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDuration(totalDuration))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("消費カロリー", systemImage: "flame.fill")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(totalCalories)) kcal")
                        .fontWeight(.semibold)
                }
                
                if totalDistance > 0 {
                    HStack {
                        Label("総距離", systemImage: "location")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f km", totalDistance / 1000))
                            .fontWeight(.semibold)
                    }
                }
                
                HStack {
                    Label("ワークアウト数", systemImage: "number")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(filteredWorkouts.count) 回")
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - ワークアウトリスト
    private var workoutList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("履歴")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(getFilteredWorkouts()) { workout in
                WorkoutRow(workout: workout)
                    .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private var errorView: some View {
        if let error = healthService.lastError {
            Text(error)
                .foregroundColor(.red)
                .font(.caption)
                .padding()
        }
    }
    
    // MARK: - ヘルパー関数
    private func getFilteredWorkouts() -> [WorkoutData] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case 0: // 今週
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return healthService.workoutRecords.filter { $0.startDate >= weekStart }
        case 1: // 今月
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return healthService.workoutRecords.filter { $0.startDate >= monthStart }
        case 2: // 全期間
            return healthService.workoutRecords
        default:
            return healthService.workoutRecords
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

// MARK: - ワークアウト行コンポーネント
struct WorkoutRow: View {
    let workout: WorkoutData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.workoutType)
                    .font(.headline)
                Spacer()
                Text(formatDate(workout.startDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                if workout.duration > 0 {
                    Label(formatDuration(workout.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let calories = workout.totalCalories, calories > 0 {
                    Label("\(Int(calories)) kcal", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let distance = workout.distance, distance > 0 {
                    Label(String(format: "%.2f km", distance / 1000), systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("ソース: \(workout.source)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

// WorkoutDataをIdentifiableに準拠させる
extension WorkoutData: Identifiable {}

#Preview {
    NavigationView {
        WorkoutDataView()
    }
}