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
    @State private var focusedField: FocusField? = nil
    @Environment(\.dismiss) var dismiss
    
    enum FocusField: Hashable {
        case weight(Int)
        case reps(Int)
    }
    
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
                            focusedField: $focusedField,
                            setIndex: index,
                            previousWeight: index > 0 ? sets[index - 1].weight : ""
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
    @Binding var focusedField: ExerciseDetailView.FocusField?
    let setIndex: Int
    let previousWeight: String
    
    @State private var sliderValue: Double = 0
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    
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
                        .focused($isWeightFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                if isWeightFocused {
                                    WeightPickerView(
                                        weight: $setData.weight,
                                        isKg: isKg,
                                        initialValue: sliderValue
                                    )
                                    
                                    Spacer()
                                    
                                    // 0.5刻みボタン
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            if let currentWeight = Double(setData.weight) {
                                                let newWeight = max(0, currentWeight - 0.5)
                                                setData.weight = String(format: "%.1f", newWeight).replacingOccurrences(of: ".0", with: "")
                                            } else {
                                                setData.weight = "0"
                                            }
                                        }) {
                                            Image(systemName: "chevron.left.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Button(action: {
                                            if let currentWeight = Double(setData.weight) {
                                                let newWeight = currentWeight + 0.5
                                                setData.weight = String(format: "%.1f", newWeight).replacingOccurrences(of: ".0", with: "")
                                            } else {
                                                setData.weight = "0.5"
                                            }
                                        }) {
                                            Image(systemName: "chevron.right.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .onAppear {
                            updateSliderValue()
                        }
                        .onChange(of: isWeightFocused) {
                            if isWeightFocused {
                                updateSliderValue()
                            }
                        }
                    
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
    
    private func updateSliderValue() {
        // 現在の重量値があればそれを使用
        if let currentWeight = Double(setData.weight), currentWeight > 0 {
            sliderValue = currentWeight
        } 
        // なければ前のセットの重量を使用
        else if let prevWeight = Double(previousWeight), prevWeight > 0 {
            sliderValue = prevWeight
        }
        // それもなければ初期値
        else {
            sliderValue = isKg ? 20 : 45
        }
    }
}

// 定規型ウェイトピッカー
struct WeightPickerView: View {
    @Binding var weight: String
    let isKg: Bool
    let initialValue: Double
    
    @State private var selectedValue: Double = 0
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    let step: Double = 0.5  // 0.5kg刻み
    let maxValue: Double = 500
    
    var body: some View {
        // 定規ピッカーのみ
        ZStack {
                // 中央の矢印インジケーター
                VStack(spacing: 0) {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 2, height: 20)
                }
                
                // スクロール可能な目盛り
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            // 左側の余白
                            Color.clear
                                .frame(width: UIScreen.main.bounds.width / 2 - 100)
                            
                            // 目盛り
                            ForEach(0...Int(maxValue / step), id: \.self) { index in
                                let value = Double(index) * step
                                VStack(spacing: 0) {
                                    // 目盛り線
                                    Rectangle()
                                        .fill(
                                            value.truncatingRemainder(dividingBy: 10) == 0 ? Color.primary :
                                            value.truncatingRemainder(dividingBy: 5) == 0 ? Color.gray :
                                            Color.gray.opacity(0.5)
                                        )
                                        .frame(
                                            width: 1,
                                            height: value.truncatingRemainder(dividingBy: 10) == 0 ? 20 :
                                                   value.truncatingRemainder(dividingBy: 5) == 0 ? 15 : 10
                                        )
                                    
                                    // 数値ラベル（5の倍数のみ表示）
                                    if value.truncatingRemainder(dividingBy: 5) == 0 {
                                        Text("\(Int(value))")
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                            .padding(.top, 2)
                                    }
                                }
                                .frame(width: 20)  // 目盛り間隔を広げる
                                .id(index)
                            }
                            
                            // 右側の余白
                            Color.clear
                                .frame(width: UIScreen.main.bounds.width / 2 - 100)
                        }
                    }
                    .frame(height: 32)  // 高さをコンパクトに
                    .onAppear {
                        self.scrollProxy = proxy
                        scrollToValue(initialValue, animated: false)
                    }
                    .onChange(of: weight) {
                        // 手入力された値にジャンプ
                        if let inputValue = Double(weight) {
                            selectedValue = inputValue
                            scrollToValue(inputValue, animated: true)
                        }
                    }
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                // ドラッグ中の値更新
                                let offset = -value.translation.width / 20  // 20は目盛り間隔
                                let steps = offset / step
                                let newValue = max(0, min(maxValue, initialValue + steps * step))
                                selectedValue = round(newValue / step) * step
                                weight = String(format: "%.1f", selectedValue).replacingOccurrences(of: ".0", with: "")
                            }
                            .onEnded { _ in
                                scrollToValue(selectedValue, animated: true)
                            }
                    )
                }
        }
        .frame(height: 32)
        .onAppear {
            selectedValue = initialValue
        }
    }
    
    private func scrollToValue(_ value: Double, animated: Bool) {
        guard let proxy = scrollProxy else { return }
        let index = Int(round(value / step))
        let clampedIndex = max(0, min(Int(maxValue / step), index))
        
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(clampedIndex, anchor: .center)
            }
        } else {
            proxy.scrollTo(clampedIndex, anchor: .center)
        }
    }
}

#Preview {
    NavigationView {
        ExerciseDetailView(exerciseName: "ベンチプレス")
            .environmentObject(WorkoutDataManager())
    }
}