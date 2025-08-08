import SwiftUI
import Charts

struct ActivityDataView: View {
    @StateObject private var healthService = HealthKitService()
    @State private var selectedTab = 0
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack {
            mainContent
            errorView
        }
        .navigationTitle("活動データ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        Task {
                            await healthService.fetchActivityData()
                        }
                    }) {
                        Label("データを更新", systemImage: "arrow.clockwise")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("全データを再取得", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("全データを再取得", isPresented: $showingDeleteConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("再取得", role: .destructive) {
                Task {
                    await healthService.deleteAllActivityData()
                }
            }
        } message: {
            Text("ローカルの活動データとアンカーを削除して、ヘルスケアから再取得します。")
        }
        .task {
            await healthService.fetchActivityData()
        }
    }
    
    // MARK: - サブビュー
    @ViewBuilder
    private var mainContent: some View {
        if healthService.isLoading {
            loadingView
        } else if healthService.activityRecords.isEmpty {
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
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("活動データがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("データを取得") {
                Task {
                    await healthService.fetchActivityData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var dataView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // セグメントコントロール
                Picker("データタイプ", selection: $selectedTab) {
                    Text("今日").tag(0)
                    Text("週間").tag(1)
                    Text("詳細").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // タブに応じた表示
                switch selectedTab {
                case 0:
                    todayActivityCards
                case 1:
                    weeklyChartsView
                case 2:
                    detailedRecordsView
                default:
                    EmptyView()
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await healthService.fetchActivityData()
        }
    }
    
    // MARK: - 今日の活動カード
    @ViewBuilder
    private var todayActivityCards: some View {
        VStack(spacing: 16) {
            // 歩数カード
            if let stepRecord = getTodayRecord(for: .stepCount) {
                ActivityCard(
                    icon: "figure.walk",
                    title: "歩数",
                    value: "\(Int(stepRecord.value))",
                    unit: stepRecord.unitString,
                    color: .blue
                )
            }
            
            // アクティブカロリーカード
            if let calorieRecord = getTodayRecord(for: .activeCalories) {
                ActivityCard(
                    icon: "flame.fill",
                    title: "アクティブカロリー",
                    value: "\(Int(calorieRecord.value))",
                    unit: calorieRecord.unitString,
                    color: .orange
                )
            }
            
            // 安静時心拍数カード
            if let heartRateRecord = getTodayRecord(for: .restingHeartRate) {
                ActivityCard(
                    icon: "heart.fill",
                    title: "安静時心拍数",
                    value: "\(Int(heartRateRecord.value))",
                    unit: heartRateRecord.unitString,
                    color: .red
                )
            }
            
            // HRVカード
            if let hrvRecord = getTodayRecord(for: .heartRateVariability) {
                ActivityCard(
                    icon: "waveform.path.ecg",
                    title: "心拍変動",
                    value: String(format: "%.1f", hrvRecord.value),
                    unit: hrvRecord.unitString,
                    color: .purple
                )
            }
            
            // エクササイズ時間カード
            if let exerciseRecord = getTodayRecord(for: .workoutDuration) {
                ActivityCard(
                    icon: "figure.run",
                    title: "エクササイズ時間",
                    value: "\(Int(exerciseRecord.value))",
                    unit: "分",
                    color: .green
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 週間グラフビュー
    private var weeklyChartsView: some View {
        VStack(spacing: 20) {
            // 歩数グラフ
            ChartCard(
                title: "歩数",
                records: getWeeklyRecords(for: .stepCount),
                color: .blue,
                valueFormatter: { Int($0) }
            )
            
            // カロリーグラフ
            ChartCard(
                title: "アクティブカロリー",
                records: getWeeklyRecords(for: .activeCalories),
                color: .orange,
                valueFormatter: { Int($0) }
            )
            
            // 心拍数グラフ
            ChartCard(
                title: "安静時心拍数",
                records: getWeeklyRecords(for: .restingHeartRate),
                color: .red,
                valueFormatter: { Int($0) }
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - 詳細記録ビュー
    private var detailedRecordsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("全記録")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(healthService.activityRecords.prefix(100)) { record in
                HStack {
                    VStack(alignment: .leading) {
                        Text(record.type.displayName)
                            .font(.body)
                        Text("\(formatValue(record.value, type: record.type)) \(record.unitString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(formatDate(record.startDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
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
    private func getTodayRecord(for type: HealthDataType) -> HealthDataRecord? {
        let calendar = Calendar.current
        let today = Date()
        
        return healthService.activityRecords
            .filter { $0.type == type }
            .first { record in
                calendar.isDate(record.startDate, inSameDayAs: today)
            }
    }
    
    private func getWeeklyRecords(for type: HealthDataType) -> [HealthDataRecord] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        return healthService.activityRecords
            .filter { $0.type == type && $0.startDate >= sevenDaysAgo }
            .sorted { $0.startDate < $1.startDate }
    }
    
    private func formatValue(_ value: Double, type: HealthDataType) -> String {
        switch type {
        case .stepCount, .activeCalories, .restingHeartRate, .workoutDuration:
            return "\(Int(value))"
        case .heartRateVariability:
            return String(format: "%.1f", value)
        default:
            return String(format: "%.2f", value)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - 活動カードコンポーネント
struct ActivityCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - グラフカードコンポーネント
struct ChartCard<T>: View where T: CustomStringConvertible {
    let title: String
    let records: [HealthDataRecord]
    let color: Color
    let valueFormatter: (Double) -> T
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            if !records.isEmpty {
                Chart(records) { record in
                    BarMark(
                        x: .value("日付", record.startDate),
                        y: .value(title, record.value)
                    )
                    .foregroundStyle(color)
                }
                .frame(height: 150)
                .padding()
            } else {
                Text("データがありません")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        ActivityDataView()
    }
}