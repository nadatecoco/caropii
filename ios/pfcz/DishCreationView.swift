import SwiftUI

struct DishCreationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var pantryStore = PantryStore()
    @StateObject private var dishStore = DishStore()
    
    // 選択された材料（左側に移動したもの）
    @State private var selectedItems: [PantryItem] = []
    
    // 選択された調味料（名前と量を管理）
    @State private var selectedSeasonings: [String: Int] = [:]  // 調味料名: 量（小さじ数 or ml）
    
    // 料理作成用
    @State private var showingDishNameAlert = false
    @State private var dishName = ""
    
    // 重さを自動計算
    var totalWeight: Int {
        var weight = 0
        for item in selectedItems {
            weight += item.quantity
        }
        // 調味料の重さも加算（水はml、その他は小さじ1=5gで計算）
        for (seasoning, amount) in selectedSeasonings {
            if seasoning == "水" {
                weight += amount  // 水はそのままml=g
            } else {
                weight += amount * 5  // 小さじ1 = 約5g
            }
        }
        return weight
    }
    
    // 料理を保存する関数
    private func saveDish() {
        // 材料をIngredient型に変換
        var ingredients: [Ingredient] = []
        
        // 在庫から選んだ材料を追加
        for item in selectedItems {
            let ingredient = Ingredient(
                name: item.name,
                amount: Double(item.quantity),
                unit: item.unit,
                nutrition: nil,  // 栄養情報は後で追加
                isFromPantry: true
            )
            ingredients.append(ingredient)
        }
        
        // 調味料を追加
        for (seasoning, amount) in selectedSeasonings {
            let ingredient = Ingredient(
                name: seasoning,
                amount: seasoning == "水" ? Double(amount) : Double(amount),
                unit: seasoning == "水" ? "ml" : "小さじ",
                nutrition: nil,
                isFromPantry: false
            )
            ingredients.append(ingredient)
        }
        
        // 料理を作成して保存
        dishStore.createDish(
            name: dishName,
            totalWeight: Double(totalWeight),
            ingredients: ingredients,
            pantryStore: pantryStore
        )
        
        print("料理「\(dishName)」（\(totalWeight)g）を保存しました")
    }
    
    // 調味料ボタンを追加する関数
    private func addSeasoning(_ seasoning: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let current = selectedSeasonings[seasoning] {
                // 既にある場合は増量
                if seasoning == "水" {
                    selectedSeasonings[seasoning] = current + 200  // 水は200ml単位
                } else {
                    selectedSeasonings[seasoning] = current + 1    // その他は小さじ1単位
                }
            } else {
                // 初回追加
                if seasoning == "水" {
                    selectedSeasonings[seasoning] = 200  // 水は200ml
                } else {
                    selectedSeasonings[seasoning] = 1    // その他は小さじ1
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 調味料ボタンエリア
                seasoningButtons
                
                Divider()
                
                // メインの左右分割エリア
                mainContent
            }
            .navigationTitle("料理を作る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作る") {
                        showingDishNameAlert = true
                    }
                    .fontWeight(.bold)
                    .disabled(selectedItems.isEmpty) // 材料がない時は無効
                }
            }
            .alert("料理名を入力", isPresented: $showingDishNameAlert) {
                TextField("料理名", text: $dishName)
                
                Button("キャンセル", role: .cancel) {
                    dishName = ""
                }
                
                Button("完成") {
                    // 料理を保存
                    saveDish()
                    dismiss()
                }
                .disabled(dishName.isEmpty)
            } message: {
                Text("総重量: \(totalWeight)g（自動計算）")
            }
        }
    }
    
    // メインコンテンツ（左右分割）
    private var mainContent: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左側：料理の鍋
                cookingPotView
                    .frame(width: geometry.size.width / 2)
                    .background(Color.orange.opacity(0.05))
                
                Divider()
                
                // 右側：冷蔵庫
                pantryView
                    .frame(width: geometry.size.width / 2)
                    .background(Color.blue.opacity(0.05))
            }
        }
    }
    
    // 左側：料理の鍋
    private var cookingPotView: some View {
        VStack {
            Text("🍳 料理")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 8) {
                    if selectedItems.isEmpty && selectedSeasonings.isEmpty {
                        Text("材料をタップして追加")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        // 材料を表示
                        ForEach(selectedItems) { item in
                            ingredientRow(item: item)
                        }
                        
                        // 調味料を表示
                        ForEach(Array(selectedSeasonings.keys), id: \.self) { seasoning in
                            seasoningRow(seasoning: seasoning)
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    // 材料の行
    private func ingredientRow(item: PantryItem) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedItems.removeAll { $0.id == item.id }
            }
        }) {
            HStack {
                Text(item.name)
                    .font(.body)
                Spacer()
                Text("\(item.quantity)\(item.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 調味料の行
    private func seasoningRow(seasoning: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                _ = selectedSeasonings.removeValue(forKey: seasoning)
            }
        }) {
            HStack {
                Text(seasoning)
                    .font(.body)
                Spacer()
                if seasoning == "水" {
                    Text("\(selectedSeasonings[seasoning] ?? 0)ml")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("小さじ\(selectedSeasonings[seasoning] ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 右側：冷蔵庫
    private var pantryView: some View {
        VStack {
            Text("📦 冷蔵庫")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(pantryStore.availableItems().filter { item in
                        !selectedItems.contains(where: { $0.id == item.id })
                    }) { item in
                        Button(action: {
                            if !selectedItems.contains(where: { $0.id == item.id }) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedItems.append(item)
                                }
                            }
                        }) {
                            HStack {
                                Text(item.name)
                                    .font(.body)
                                Spacer()
                                Text("\(item.quantity)\(item.unit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    // 調味料ボタンエリアを別ビューとして定義
    private var seasoningButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["水", "塩", "胡椒", "砂糖", "醤油", "みりん", "酒", "味噌", "油"], id: \.self) { seasoning in
                    Button(action: {
                        addSeasoning(seasoning)
                    }) {
                        Text(seasoning)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
        .background(Color.gray.opacity(0.05))
    }
}

struct DishCreationView_Previews: PreviewProvider {
    static var previews: some View {
        DishCreationView()
    }
}