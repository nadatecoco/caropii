import SwiftUI
import Charts

struct SleepDataView: View {
    @StateObject private var healthService = HealthKitService()
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack {
            mainContent
            errorView
        }
        .navigationTitle("睡眠データ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        Task {
                            await healthService.fetchSleepData()
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
                    await deleteAndRefetch()
                }
            }
        } message: {
            Text("ローカルの睡眠データとアンカーを削除して、ヘルスケアから再取得します。")
        }
        .task {
            await healthService.fetchSleepData()
        }
    }
    
    // MARK: - サブビュー
    @ViewBuilder
    private var mainContent: some View {
        if healthService.isLoading {
            loadingView
        } else if healthService.sleepRecords.isEmpty {
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
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 60))
                .foregroundColor(.indigo)
            Text("睡眠データがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("データを取得") {
                Task {
                    await healthService.fetchSleepData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var dataView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                todaySleepCard
                weeklyChartCard
                allRecordsCard
            }
            .padding()
        }
        .refreshable {
            await healthService.fetchSleepData()
        }
    }
    
    @ViewBuilder
    private var todaySleepCard: some View {
        if let todayRecords = getTodayRecords() {
            VStack(alignment: .leading, spacing: 10) {
                Text("昨夜の睡眠")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(todayRecords.totalSleep, specifier: "%.1f")")
                        .font(.system(size: 48, weight: .bold))
                    Text("時間")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                
                // 睡眠の内訳
                VStack(alignment: .leading, spacing: 8) {
                    if todayRecords.inBed > 0 {
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("ベッドにいた時間")
                            Spacer()
                            Text("\(todayRecords.inBed, specifier: "%.1f")時間")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                    
                    if todayRecords.rem > 0 {
                        HStack {
                            Image(systemName: "brain")
                                .foregroundColor(.purple)
                                .frame(width: 20)
                            Text("レム睡眠")
                            Spacer()
                            Text("\(todayRecords.rem, specifier: "%.1f")時間")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                    
                    if todayRecords.deep > 0 {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.indigo)
                                .frame(width: 20)
                            Text("深い睡眠")
                            Spacer()
                            Text("\(todayRecords.deep, specifier: "%.1f")時間")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                    
                    if todayRecords.core > 0 {
                        HStack {
                            Image(systemName: "moon")
                                .foregroundColor(.cyan)
                                .frame(width: 20)
                            Text("コア睡眠")
                            Spacer()
                            Text("\(todayRecords.core, specifier: "%.1f")時間")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.indigo.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var weeklyChartCard: some View {
        VStack(alignment: .leading) {
            Text("過去7日間の睡眠")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(getWeeklyData()) { dayData in
                BarMark(
                    x: .value("日付", dayData.date),
                    y: .value("睡眠時間", dayData.totalSleep)
                )
                .foregroundStyle(.indigo)
            }
            .frame(height: 200)
            .padding()
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var allRecordsCard: some View {
        VStack(alignment: .leading) {
            Text("全記録")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(healthService.sleepRecords.prefix(50)) { record in
                sleepRecordRow(for: record)
            }
        }
    }
    
    private func sleepRecordRow(for record: HealthDataRecord) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(record.type.displayName)
                    .font(.body)
                Text("\(record.value, specifier: "%.1f") \(record.unitString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(formatDate(record.startDate)) - \(formatTime(record.endDate ?? record.startDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(record.source)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
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
    
    // MARK: - ヘルパーメソッド
    private func getTodayRecords() -> (totalSleep: Double, inBed: Double, rem: Double, deep: Double, core: Double)? {
        let calendar = Calendar.current
        let today = Date()
        
        // 今日の睡眠記録を集計
        let todayRecords = healthService.sleepRecords.filter { record in
            calendar.isDate(record.endDate ?? record.startDate, inSameDayAs: today) ||
            calendar.isDate(record.endDate ?? record.startDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!)
        }
        
        guard !todayRecords.isEmpty else { return nil }
        
        var totalSleep: Double = 0
        var inBed: Double = 0
        var rem: Double = 0
        var deep: Double = 0
        var core: Double = 0
        
        for record in todayRecords {
            switch record.type {
            case .sleepAsleep:
                totalSleep += record.value
            case .sleepInBed:
                inBed += record.value
            case .sleepREM:
                rem += record.value
            case .sleepDeep:
                deep += record.value
            case .sleepCore:
                core += record.value
            default:
                break
            }
        }
        
        // 各睡眠段階も合計睡眠時間に含める
        totalSleep += rem + deep + core
        
        return (totalSleep, inBed, rem, deep, core)
    }
    
    private func getWeeklyData() -> [DailySleepData] {
        let calendar = Calendar.current
        var weeklyData: [DailySleepData] = []
        
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            let dayRecords = healthService.sleepRecords.filter { record in
                calendar.isDate(record.endDate ?? record.startDate, inSameDayAs: targetDate)
            }
            
            let totalSleep = dayRecords
                .filter { $0.type == .sleepAsleep || $0.type == .sleepREM || $0.type == .sleepDeep || $0.type == .sleepCore }
                .reduce(0) { $0 + $1.value }
            
            weeklyData.append(DailySleepData(date: targetDate, totalSleep: totalSleep))
        }
        
        return weeklyData.reversed()
    }
    
    private func deleteAndRefetch() async {
        // 全データ削除メソッドを呼び出す
        await healthService.deleteAllSleepData()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// グラフ用のデータ構造体
struct DailySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let totalSleep: Double
}