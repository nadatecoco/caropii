import SwiftUI
import Charts

struct BodyMassView: View {
    @StateObject private var healthService = HealthKitService()
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack {
            mainContent
            errorView
        }
        .navigationTitle("体重データ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        Task {
                            await healthService.fetchBodyMass()
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
                    await healthService.deleteAllLocalData()
                }
            }
        } message: {
            Text("ローカルの全データとアンカーを削除して、ヘルスケアから再取得します。")
        }
        .task {
            await healthService.fetchBodyMass()
        }
    }
    
    // MARK: - サブビュー
    @ViewBuilder
    private var mainContent: some View {
        if healthService.isLoading {
            loadingView
        } else if healthService.bodyMassRecords.isEmpty {
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
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("体重データがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("データを取得") {
                Task {
                    await healthService.fetchBodyMass()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var dataView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                latestWeightCard
                weeklyChartCard
                allRecordsCard
            }
            .padding()
        }
        .refreshable {
            await healthService.fetchBodyMass()
        }
    }
    
    @ViewBuilder
    private var latestWeightCard: some View {
        if let latestRecord = healthService.bodyMassRecords.first {
            VStack(alignment: .leading, spacing: 10) {
                Text("最新の体重")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(latestRecord.value, specifier: "%.1f")")
                        .font(.system(size: 48, weight: .bold))
                    Text(latestRecord.unitString)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                
                Text(formatDate(latestRecord.startDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var weeklyChartCard: some View {
        VStack(alignment: .leading) {
            Text("過去7日間")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(recentRecords()) { record in
                LineMark(
                    x: .value("日付", record.startDate),
                    y: .value("体重", record.value)
                )
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("日付", record.startDate),
                    y: .value("体重", record.value)
                )
                .foregroundStyle(.blue)
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
            
            ForEach(healthService.bodyMassRecords) { record in
                recordRow(for: record)
            }
        }
    }
    
    private func recordRow(for record: HealthDataRecord) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(record.value, specifier: "%.1f") \(record.unitString)")
                    .font(.body)
                Text(formatDate(record.startDate))
                    .font(.caption)
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
    
    // 最近7日間のデータ
    private func recentRecords() -> [HealthDataRecord] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return healthService.bodyMassRecords
            .filter { $0.startDate >= sevenDaysAgo }
            .sorted { $0.startDate < $1.startDate }
    }
    
    // 日付フォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}