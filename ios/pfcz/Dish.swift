import Foundation

// MARK: - 料理モデル
struct Dish: Identifiable, Codable {
    let id: UUID
    var name: String                // 料理名（例：カレー、炊き込みご飯）
    var totalWeight: Double         // 総重量（g）
    var remainingWeight: Double     // 残量（g）
    var ingredients: [Ingredient]   // 使用した材料と調味料（統合）
    var createdAt: Date             // 作成日時
    var isRecipe: Bool              // レシピとして保存するかのフラグ（将来用）
    
    init(id: UUID = UUID(), 
         name: String, 
         totalWeight: Double, 
         ingredients: [Ingredient] = [], 
         createdAt: Date = Date(),
         isRecipe: Bool = false) {
        self.id = id
        self.name = name
        self.totalWeight = totalWeight
        self.remainingWeight = totalWeight // 初期は全量が残っている
        self.ingredients = ingredients
        self.createdAt = createdAt
        self.isRecipe = isRecipe
    }
    
    // 料理を消費（部分的に食べる）
    mutating func consume(amount: Double) {
        remainingWeight = max(0, remainingWeight - amount)
    }
    
    // 消費率を計算（栄養計算用）
    func consumptionRate(for amount: Double) -> Double {
        guard totalWeight > 0 else { return 0 }
        return amount / totalWeight
    }
    
    // 栄養素を按分計算
    func calculateNutrition(for amount: Double) -> Nutrition {
        let rate = consumptionRate(for: amount)
        
        var totalNutrition = Nutrition()
        
        // 全材料（材料＋調味料）の栄養素を合計
        for ingredient in ingredients {
            if let nutrition = ingredient.nutrition {
                totalNutrition.calories += nutrition.calories * rate
                totalNutrition.protein += nutrition.protein * rate
                totalNutrition.fat += nutrition.fat * rate
                totalNutrition.carbs += nutrition.carbs * rate
            }
        }
        
        return totalNutrition
    }
    
    // 料理が空かどうか
    var isEmpty: Bool {
        remainingWeight <= 0
    }
}

// MARK: - 材料モデル（材料と調味料を統合）
struct Ingredient: Codable {
    let name: String
    let amount: Double?      // 使用量（オプション：調味料は目分量OK）
    let unit: String?        // 単位（オプション）
    let nutrition: Nutrition? // 基本栄養情報（オプション）
    let vitamins: VitaminProfile? // ビタミン情報（オプション）
    let minerals: MineralProfile? // ミネラル情報（オプション）
    let isFromPantry: Bool   // 在庫から使ったか（true:材料、false:調味料）
    
    init(name: String, 
         amount: Double? = nil, 
         unit: String? = nil, 
         nutrition: Nutrition? = nil,
         vitamins: VitaminProfile? = nil,
         minerals: MineralProfile? = nil,
         isFromPantry: Bool = true) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.nutrition = nutrition
        self.vitamins = vitamins
        self.minerals = minerals
        self.isFromPantry = isFromPantry
    }
}

// MARK: - 栄養素モデル（基本4項目）
struct Nutrition: Codable {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0
}

// MARK: - ビタミンプロファイル（別管理）
struct VitaminProfile: Codable {
    var vitaminA: Double? = nil    // ビタミンA (μg)
    var vitaminB1: Double? = nil   // ビタミンB1/チアミン (mg)
    var vitaminB2: Double? = nil   // ビタミンB2/リボフラビン (mg)
    var vitaminB6: Double? = nil   // ビタミンB6 (mg)
    var vitaminB12: Double? = nil  // ビタミンB12 (μg)
    var vitaminC: Double? = nil    // ビタミンC (mg)
    var vitaminD: Double? = nil    // ビタミンD (μg)
    var vitaminE: Double? = nil    // ビタミンE (mg)
    var vitaminK: Double? = nil    // ビタミンK (μg)
    var niacin: Double? = nil      // ナイアシン/B3 (mg)
    var folate: Double? = nil      // 葉酸 (μg)
    var pantothenicAcid: Double? = nil // パントテン酸/B5 (mg)
    var biotin: Double? = nil      // ビオチン (μg)
    // 後で追加しやすいように余裕を持たせた設計
}

// MARK: - ミネラルプロファイル（別管理）
struct MineralProfile: Codable {
    var sodium: Double? = nil      // ナトリウム (mg)
    var potassium: Double? = nil   // カリウム (mg)
    var calcium: Double? = nil     // カルシウム (mg)
    var magnesium: Double? = nil   // マグネシウム (mg)
    var phosphorus: Double? = nil  // リン (mg)
    var iron: Double? = nil        // 鉄 (mg)
    var zinc: Double? = nil        // 亜鉛 (mg)
    var copper: Double? = nil      // 銅 (mg)
    var manganese: Double? = nil   // マンガン (mg)
    var selenium: Double? = nil    // セレン (μg)
    var iodine: Double? = nil      // ヨウ素 (μg)
    // 後で追加しやすいように余裕を持たせた設計
}