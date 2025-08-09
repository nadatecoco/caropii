import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var scannedCode: String?
    @State private var isScanning = true
    @State private var isSearching = false
    @State private var productInfo: ProductInfo?
    @State private var errorMessage: String?
    @State private var showManualInput = false
    @State private var actualWeight: String = "100"  // 実際の重量（グラム）
    @State private var baseWeight: Double = 100      // 基準重量（通常100g）
    
    // 商品情報
    struct ProductInfo {
        let janCode: String
        let name: String
        let maker: String?
        let calories: Double?
        let protein: Double?
        let fat: Double?
        let carbs: Double?
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if isScanning && scannedCode == nil {
                    // バーコードスキャナー
                    BarcodeScannerRepresentable(
                        scannedCode: $scannedCode,
                        isScanning: $isScanning
                    )
                    .ignoresSafeArea()
                    
                    // スキャンガイド
                    VStack {
                        Text("バーコードを枠内に合わせてください")
                            .font(.headline)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 100)
                        
                        Spacer()
                        
                        // スキャン枠
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.yellow, lineWidth: 3)
                            .frame(width: 280, height: 180)
                        
                        Spacer()
                    }
                } else if isSearching {
                    // 検索中
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("商品情報を検索中...")
                            .font(.headline)
                        Text("JANコード: \(scannedCode ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if let product = productInfo {
                    // 商品情報表示
                    productInfoView(product: product)
                } else if let code = scannedCode {
                    // 商品が見つからなかった
                    notFoundView(code: code)
                }
            }
            .navigationTitle("バーコードスキャン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                if scannedCode != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("再スキャン") {
                            resetScanner()
                        }
                    }
                }
            }
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            if let code = newValue {
                searchProduct(with: code)
            }
        }
    }
    
    // MARK: - 商品情報表示
    @ViewBuilder
    private func productInfoView(product: ProductInfo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 商品名
                VStack(alignment: .leading, spacing: 8) {
                    Text("商品情報")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(product.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let maker = product.maker {
                        Text(maker)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("JANコード: \(product.janCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 重量調整
                VStack(alignment: .leading, spacing: 12) {
                    Text("重量調整")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("実際の重量:")
                            .foregroundColor(.secondary)
                        
                        TextField("100", text: $actualWeight)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        
                        Text("g")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("(\(Int(baseWeight))gあたりの栄養成分)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // 栄養成分（調整後）
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("栄養成分")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let weight = Double(actualWeight), weight != baseWeight {
                            Text("× \(weight / baseWeight, specifier: "%.1f")倍")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    VStack(spacing: 10) {
                        nutritionRow(
                            label: "エネルギー",
                            value: calculateAdjustedValue(product.calories),
                            unit: "kcal"
                        )
                        nutritionRow(
                            label: "たんぱく質",
                            value: calculateAdjustedValue(product.protein),
                            unit: "g"
                        )
                        nutritionRow(
                            label: "脂質",
                            value: calculateAdjustedValue(product.fat),
                            unit: "g"
                        )
                        nutritionRow(
                            label: "炭水化物",
                            value: calculateAdjustedValue(product.carbs),
                            unit: "g"
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 追加ボタン
                Button(action: {
                    addToFoodEntry(product: product)
                }) {
                    Text("食事記録に追加")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top)
            }
            .padding()
        }
    }
    
    // 重量に応じて栄養価を調整
    private func calculateAdjustedValue(_ baseValue: Double?) -> Double? {
        guard let value = baseValue,
              let weight = Double(actualWeight) else { return baseValue }
        
        // 基準重量に対する比率で計算
        return value * (weight / baseWeight)
    }
    
    // MARK: - 商品が見つからない場合
    @ViewBuilder
    private func notFoundView(code: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("商品が見つかりませんでした")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("JANコード: \(code)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    resetScanner()
                }) {
                    Label("もう一度スキャン", systemImage: "barcode.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showManualInput = true
                }) {
                    Label("手動で入力", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding()
        .sheet(isPresented: $showManualInput) {
            // 手動入力画面（既存のOCRビューを流用）
            NutritionOCRView()
                .environmentObject(foodStore)
                .environmentObject(foodEntryStore)
        }
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
    
    // MARK: - 商品検索
    private func searchProduct(with janCode: String) {
        isSearching = true
        errorMessage = nil
        
        // Open Food Facts APIを使用
        searchFromOpenFoodFacts(barcode: janCode)
    }
    
    // Open Food Facts APIから検索
    private func searchFromOpenFoodFacts(barcode: String) {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.isSearching = false
                self.errorMessage = "無効なバーコードです"
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isSearching = false
                
                if let error = error {
                    self.errorMessage = "ネットワークエラー: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "データが取得できませんでした"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = json["status"] as? Int,
                       status == 1,
                       let product = json["product"] as? [String: Any] {
                        
                        // 商品名
                        let productName = product["product_name"] as? String
                            ?? product["product_name_ja"] as? String
                            ?? "不明な商品"
                        
                        // メーカー名
                        let brands = product["brands"] as? String
                        
                        // 栄養成分（100gあたり）
                        let nutriments = product["nutriments"] as? [String: Any] ?? [:]
                        
                        // エネルギー（kcal）
                        let energy = nutriments["energy-kcal_100g"] as? Double
                            ?? nutriments["energy_100g"] as? Double
                        
                        // たんぱく質（g）
                        let proteins = nutriments["proteins_100g"] as? Double
                        
                        // 脂質（g）
                        let fat = nutriments["fat_100g"] as? Double
                        
                        // 炭水化物（g）
                        let carbs = nutriments["carbohydrates_100g"] as? Double
                        
                        self.productInfo = ProductInfo(
                            janCode: barcode,
                            name: productName,
                            maker: brands,
                            calories: energy,
                            protein: proteins,
                            fat: fat,
                            carbs: carbs
                        )
                        
                        print("✅ Open Food Factsから商品情報取得: \(productName)")
                        
                    } else {
                        // 商品が見つからない場合はローカルデータベースを検索
                        self.searchFromLocalDatabase(barcode: barcode)
                    }
                } catch {
                    self.errorMessage = "データの解析に失敗しました"
                }
            }
        }.resume()
    }
    
    // ローカルのダミーデータベースから検索（フォールバック）
    private func searchFromLocalDatabase(barcode: String) {
        // 日本の一般的な商品のダミーデータ
        let localDatabase: [String: ProductInfo] = [
            "4901777018174": ProductInfo(janCode: "4901777018174", name: "ザバス ホエイプロテイン100 ココア味", maker: "明治", calories: 83, protein: 15, fat: 1.3, carbs: 2.7),
            "4902705001114": ProductInfo(janCode: "4902705001114", name: "サラダチキン プレーン", maker: "セブンプレミアム", calories: 114, protein: 23.8, fat: 1.2, carbs: 0),
            "4901360315628": ProductInfo(janCode: "4901360315628", name: "inバー プロテイン ベイクドチョコ", maker: "森永製菓", calories: 209, protein: 15.9, fat: 11.1, carbs: 12.2)
        ]
        
        if let product = localDatabase[barcode] {
            productInfo = product
            print("✅ ローカルデータベースから商品情報取得: \(product.name)")
        } else if barcode.hasPrefix("49") {
            // 49で始まる日本の商品コードの場合、汎用データを返す
            productInfo = ProductInfo(
                janCode: barcode,
                name: "商品名を手動で入力してください",
                maker: nil,
                calories: nil,
                protein: nil,
                fat: nil,
                carbs: nil
            )
            errorMessage = "商品情報が見つかりませんでした。手動で栄養成分を入力してください。"
        } else {
            productInfo = nil
            errorMessage = "商品が見つかりませんでした"
        }
    }
    
    // MARK: - 食事記録に追加
    private func addToFoodEntry(product: ProductInfo) {
        // 重量調整後の値を計算
        let adjustedCalories = calculateAdjustedValue(product.calories) ?? 0
        let adjustedProtein = calculateAdjustedValue(product.protein) ?? 0
        let adjustedFat = calculateAdjustedValue(product.fat) ?? 0
        let adjustedCarbs = calculateAdjustedValue(product.carbs) ?? 0
        
        // 実際の重量を商品名に含める
        let weight = Double(actualWeight) ?? baseWeight
        let productName = weight != baseWeight ? 
            "\(product.name) (\(Int(weight))g)" : product.name
        
        let newFood = Food(
            id: UUID(),
            name: productName,
            protein: adjustedProtein,
            fat: adjustedFat,
            carbs: adjustedCarbs,
            calories: adjustedCalories
        )
        
        foodEntryStore.add(food: newFood)
        foodStore.addFood(newFood)
        
        print("✅ バーコード商品を追加: \(productName)")
        print("  カロリー: \(adjustedCalories) kcal (×\(weight/baseWeight))")
        print("  たんぱく質: \(adjustedProtein) g")
        print("  脂質: \(adjustedFat) g")
        print("  炭水化物: \(adjustedCarbs) g")
        
        dismiss()
    }
    
    // MARK: - スキャナーリセット
    private func resetScanner() {
        scannedCode = nil
        productInfo = nil
        errorMessage = nil
        isScanning = true
        isSearching = false
        actualWeight = "100"  // 重量もリセット
        baseWeight = 100
    }
}

// MARK: - バーコードスキャナー
struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool
    
    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let viewController = BarcodeScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BarcodeScannerDelegate {
        let parent: BarcodeScannerRepresentable
        
        init(_ parent: BarcodeScannerRepresentable) {
            self.parent = parent
        }
        
        func didScanCode(_ code: String) {
            parent.scannedCode = code
            parent.isScanning = false
        }
    }
}

// MARK: - バーコードスキャナーViewController
protocol BarcodeScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class BarcodeScannerViewController: UIViewController {
    weak var delegate: BarcodeScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("カメラが利用できません")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("カメラ入力エラー: \(error)")
            return
        }
        
        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            print("カメラ入力を追加できません")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            // JANコード（EAN-13, EAN-8）とQRコードに対応
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .qr]
        } else {
            print("メタデータ出力を追加できません")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
    }
    
    func startScanning() {
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        stopScanning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // 振動フィードバック
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            delegate?.didScanCode(stringValue)
        }
    }
}

#Preview {
    BarcodeScannerView()
        .environmentObject(FoodStore())
        .environmentObject(FoodEntryStore())
}