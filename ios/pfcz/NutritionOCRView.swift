import SwiftUI
import Vision
import VisionKit

struct NutritionOCRView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var recognizedNutrition: RecognizedNutrition?
    @State private var errorMessage: String?
    @State private var productName: String = ""
    
    // 認識結果を保持する構造体
    struct RecognizedNutrition {
        var calories: Double?
        var protein: Double?
        var fat: Double?
        var carbs: Double?
        var productName: String?
    }
    
    // 手動編集用の値
    @State private var manualCalories: String = ""
    @State private var manualProtein: String = ""
    @State private var manualFat: String = ""
    @State private var manualCarbs: String = ""
    @State private var isManualEditMode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    // 画像プレビュー
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding()
                    
                    if isProcessing {
                        ProgressView("解析中...")
                            .padding()
                    } else if let nutrition = recognizedNutrition {
                        // 認識結果表示
                        recognitionResultView(nutrition: nutrition)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                } else {
                    // 画像選択ボタン
                    VStack(spacing: 30) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("栄養成分表示を撮影")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                showingCamera = true
                            }) {
                                Label("カメラで撮影", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Label("写真を選択", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("栄養成分を読み取り")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                if selectedImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("再撮影") {
                            selectedImage = nil
                            recognizedNutrition = nil
                            errorMessage = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera) {
                // 画像選択後、自動でOCR処理を開始
                if selectedImage != nil {
                    processImage()
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary) {
                // 画像選択後、自動でOCR処理を開始
                if selectedImage != nil {
                    processImage()
                }
            }
        }
    }
    
    // 認識結果表示ビュー
    @ViewBuilder
    private func recognitionResultView(nutrition: RecognizedNutrition) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("認識結果")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isManualEditMode.toggle()
                    if isManualEditMode {
                        // 編集モードに入る時、現在の値を文字列に変換
                        manualCalories = nutrition.calories != nil ? String(format: "%.0f", nutrition.calories!) : ""
                        manualProtein = nutrition.protein != nil ? String(format: "%.1f", nutrition.protein!) : ""
                        manualFat = nutrition.fat != nil ? String(format: "%.1f", nutrition.fat!) : ""
                        manualCarbs = nutrition.carbs != nil ? String(format: "%.1f", nutrition.carbs!) : ""
                    }
                }) {
                    Text(isManualEditMode ? "完了" : "手動編集")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isManualEditMode ? Color.green : Color.gray.opacity(0.2))
                        .foregroundColor(isManualEditMode ? .white : .primary)
                        .cornerRadius(8)
                }
            }
            
            // 商品名入力フィールド
            HStack {
                Text("商品名:")
                    .foregroundColor(.secondary)
                TextField("商品名を入力", text: $productName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(spacing: 10) {
                if isManualEditMode {
                    // 手動編集モード
                    nutritionEditRow(label: "エネルギー", value: $manualCalories, unit: "kcal")
                    nutritionEditRow(label: "たんぱく質", value: $manualProtein, unit: "g")
                    nutritionEditRow(label: "脂質", value: $manualFat, unit: "g")
                    nutritionEditRow(label: "炭水化物", value: $manualCarbs, unit: "g")
                } else {
                    // 表示モード
                    nutritionRow(label: "エネルギー", value: nutrition.calories, unit: "kcal")
                    nutritionRow(label: "たんぱく質", value: nutrition.protein, unit: "g")
                    nutritionRow(label: "脂質", value: nutrition.fat, unit: "g")
                    nutritionRow(label: "炭水化物", value: nutrition.carbs, unit: "g")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
            }
            
            Button(action: {
                saveToFoodEntry()
            }) {
                Text("食事記録に追加")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
            .disabled(productName.isEmpty)
        }
        .padding()
    }
    
    private func nutritionRow(label: String, value: Double?, unit: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            if let value = value {
                Text("\(value, specifier: "%.1f") \(unit)")
                    .fontWeight(.medium)
            } else {
                Text("--")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // 編集可能な栄養成分行
    private func nutritionEditRow(label: String, value: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 100)
            
            Text(unit)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - OCR処理
    private func processImage() {
        guard let image = selectedImage,
              let cgImage = image.cgImage else { return }
        
        isProcessing = true
        errorMessage = nil
        
        // Vision リクエストの作成
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "テキスト認識エラー: \(error.localizedDescription)"
                    self.isProcessing = false
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.errorMessage = "テキストが認識できませんでした"
                    self.isProcessing = false
                }
                return
            }
            
            // 認識したテキストを処理
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // 栄養成分を抽出
            DispatchQueue.main.async {
                self.extractNutritionInfo(from: recognizedStrings)
                self.isProcessing = false
            }
        }
        
        // 日本語認識を有効化
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.recognitionLevel = .accurate
        
        // リクエストを実行
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "画像処理エラー: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - 栄養成分抽出
    private func extractNutritionInfo(from texts: [String]) {
        var nutrition = RecognizedNutrition()
        
        // デバッグ用：認識したテキストを出力
        print("認識したテキスト:")
        texts.forEach { print($0) }
        
        // 各テキスト行を解析
        for text in texts {
            // エネルギー/カロリー/熱量など
            if let calories = extractValue(from: text, patterns: [
                "エネルギー[\\s:：]*([0-9.]+)\\s*kcal",
                "カロリー[\\s:：]*([0-9.]+)\\s*kcal",
                "熱量[\\s:：]*([0-9.]+)\\s*kcal",
                "energy[\\s:：]*([0-9.]+)\\s*kcal",
                "([0-9.]+)\\s*kcal",
                "エネルギー量[\\s:：]*([0-9.]+)",
                "([0-9.]+)\\s*キロカロリー"
            ]) {
                nutrition.calories = calories
            }
            
            // たんぱく質/タンパク質/プロテイン
            if let protein = extractValue(from: text, patterns: [
                "たんぱく質[\\s:：]*([0-9.]+)\\s*g",
                "タンパク質[\\s:：]*([0-9.]+)\\s*g",
                "蛋白質[\\s:：]*([0-9.]+)\\s*g",
                "プロテイン[\\s:：]*([0-9.]+)\\s*g",
                "protein[\\s:：]*([0-9.]+)\\s*g",
                "たん白質[\\s:：]*([0-9.]+)"
            ]) {
                nutrition.protein = protein
            }
            
            // 脂質/脂肪
            if let fat = extractValue(from: text, patterns: [
                "脂質[\\s:：]*([0-9.]+)\\s*g",
                "脂肪[\\s:：]*([0-9.]+)\\s*g",
                "fat[\\s:：]*([0-9.]+)\\s*g",
                "脂肪分[\\s:：]*([0-9.]+)",
                "lipid[\\s:：]*([0-9.]+)"
            ]) {
                nutrition.fat = fat
            }
            
            // 炭水化物/糖質
            if let carbs = extractValue(from: text, patterns: [
                "炭水化物[\\s:：]*([0-9.]+)\\s*g",
                "糖質[\\s:：]*([0-9.]+)\\s*g",
                "carb[\\s:：]*([0-9.]+)\\s*g",
                "carbohydrate[\\s:：]*([0-9.]+)",
                "糖類[\\s:：]*([0-9.]+)"
            ]) {
                nutrition.carbs = carbs
            }
        }
        
        // 認識結果を更新
        if nutrition.calories != nil || nutrition.protein != nil || 
           nutrition.fat != nil || nutrition.carbs != nil {
            recognizedNutrition = nutrition
            
            // 部分的に認識できなかった項目がある場合の警告
            var missingItems: [String] = []
            if nutrition.calories == nil { missingItems.append("カロリー") }
            if nutrition.protein == nil { missingItems.append("たんぱく質") }
            if nutrition.fat == nil { missingItems.append("脂質") }
            if nutrition.carbs == nil { missingItems.append("炭水化物") }
            
            if !missingItems.isEmpty {
                errorMessage = "⚠️ \(missingItems.joined(separator: "、"))が認識できませんでした。\n「手動編集」で入力してください。"
            }
        } else {
            // 全く認識できなかった場合は、空の結果を作成して手動入力を促す
            recognizedNutrition = RecognizedNutrition()
            errorMessage = "❌ 栄養成分を認識できませんでした。\n「手動編集」で値を入力してください。"
            isManualEditMode = true // 自動で編集モードにする
        }
    }
    
    // 正規表現で数値を抽出
    private func extractValue(from text: String, patterns: [String]) -> Double? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if let valueRange = Range(match.range(at: 1), in: text) {
                        let valueString = String(text[valueRange])
                        return Double(valueString)
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - 食事記録に保存
    private func saveToFoodEntry() {
        guard let nutrition = recognizedNutrition else { return }
        
        // 手動編集モードの場合は編集値を使用
        let finalCalories: Double
        let finalProtein: Double
        let finalFat: Double
        let finalCarbs: Double
        
        if isManualEditMode {
            finalCalories = Double(manualCalories) ?? 0
            finalProtein = Double(manualProtein) ?? 0
            finalFat = Double(manualFat) ?? 0
            finalCarbs = Double(manualCarbs) ?? 0
        } else {
            finalCalories = nutrition.calories ?? 0
            finalProtein = nutrition.protein ?? 0
            finalFat = nutrition.fat ?? 0
            finalCarbs = nutrition.carbs ?? 0
        }
        
        // Foodオブジェクトを作成
        let newFood = Food(
            id: UUID(),
            name: productName.isEmpty ? "OCR読取食品" : productName,
            protein: finalProtein,
            fat: finalFat,
            carbs: finalCarbs,
            calories: finalCalories
        )
        
        // FoodEntryStoreに追加
        foodEntryStore.add(food: newFood)
        
        // FoodStoreにも追加
        foodStore.addFood(newFood)
        
        print("✅ 食事記録に追加:")
        print("商品名: \(productName)")
        print("カロリー: \(finalCalories) kcal")
        print("たんぱく質: \(finalProtein) g")
        print("脂質: \(finalFat) g")
        print("炭水化物: \(finalCarbs) g")
        
        dismiss()
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    var onDismiss: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
            parent.onDismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NutritionOCRView()
}