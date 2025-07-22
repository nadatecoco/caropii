import SwiftUI

struct AnalysisResultView: View {
    let analysisText: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ヘッダー
                    VStack(spacing: 10) {
                        Text("AI 栄養分析結果")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("今日の食事について")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    
                    Divider()
                    
                    // 分析結果テキスト
                    VStack(alignment: .leading, spacing: 15) {
                        Text("分析結果")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(analysisText)
                            .font(.body)
                            .lineSpacing(5)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // 閉じるボタン
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("確認完了")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("AI分析")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AnalysisResultView(analysisText: """
今日の食事は、唐揚げのみ180kcalとカロリーが低く、ダイエット中の方には良いかもしれません。タンパク質20gと脂質10gの摂取は、筋肉維持やエネルギー源として一定の役割を果たしていると言えるでしょう。

しかし、改善点は大きく、栄養バランスが極端に偏っています。炭水化物が5gと非常に少ないため、エネルギー不足や集中力の低下につながる可能性があります。

今後の食事では、野菜や果物、穀物類を積極的に摂取しましょう。例えば、唐揚げと一緒にサラダを添えたり、ご飯やパンを少量食べることで、炭水化物とビタミン・ミネラルを補えます。
""")
}