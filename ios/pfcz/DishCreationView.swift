import SwiftUI

struct DishCreationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var pantryStore = PantryStore()
    
    // 選択された材料（左側に移動したもの）
    @State private var selectedItems: [PantryItem] = []
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // 左側：料理の鍋
                    VStack {
                        Text("🍳 料理")
                            .font(.headline)
                            .padding(.top)
                        
                        ScrollView {
                            VStack {
                                Text("材料をタップして追加")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(width: geometry.size.width / 2)
                    .background(Color.orange.opacity(0.05))
                    
                    Divider()
                    
                    // 右側：冷蔵庫
                    VStack {
                        Text("📦 冷蔵庫")
                            .font(.headline)
                            .padding(.top)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                // PantryStoreから在庫を表示
                                ForEach(pantryStore.availableItems()) { item in
                                    Button(action: {
                                        // タップで左に移動（次のスライスで実装）
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
                    .frame(width: geometry.size.width / 2)
                    .background(Color.blue.opacity(0.05))
                }
            }
            .navigationTitle("料理を作る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DishCreationView_Previews: PreviewProvider {
    static var previews: some View {
        DishCreationView()
    }
}