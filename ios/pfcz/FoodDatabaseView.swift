import SwiftUI

struct FoodDatabaseView: View {
    @EnvironmentObject var foodStore: FoodStore
    @State private var expandedFoodId: UUID?
    
    var body: some View {
        VStack {
            List {
                ForEach(foodStore.foods) { food in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(food.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("\(food.calories, specifier: "%.0f") kcal")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if expandedFoodId == food.id {
                                        expandedFoodId = nil
                                    } else {
                                        expandedFoodId = food.id
                                    }
                                }
                            }) {
                                Image(systemName: expandedFoodId == food.id ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        
                        // 詳細情報（アニメーション付きで展開）
                        if expandedFoodId == food.id {
                            VStack(alignment: .leading, spacing: 6) {
                                Divider()
                                
                                HStack {
                                    NutrientInfoView(
                                        label: "タンパク質",
                                        value: food.protein,
                                        color: .red
                                    )
                                    Spacer()
                                    NutrientInfoView(
                                        label: "脂質",
                                        value: food.fat,
                                        color: .orange
                                    )
                                }
                                
                                HStack {
                                    NutrientInfoView(
                                        label: "炭水化物",
                                        value: food.carbs,
                                        color: .green
                                    )
                                    Spacer()
                                }
                            }
                            .padding(.top, 5)
                            .transition(.slide.combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: foodStore.removeFood)
            }
        }
        .navigationTitle("食材データベース")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NutrientInfoView: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(color.opacity(0.8))
                    .frame(width: 8, height: 8)
                
                Text("\(value, specifier: "%.1f")g")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    NavigationView {
        FoodDatabaseView()
            .environmentObject(FoodStore())
    }
}