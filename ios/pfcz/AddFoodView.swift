import SwiftUI

struct AddFoodView: View {
    @EnvironmentObject var foodStore: FoodStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var calories = ""
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("新しい食材を追加")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    // 食材名
                    VStack(alignment: .leading, spacing: 8) {
                        Text("食材名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("例: 鶏胸肉(100g)", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 栄養素入力
                    VStack(alignment: .leading, spacing: 12) {
                        Text("栄養成分")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            NutrientInputField(
                                label: "タンパク質",
                                value: $protein,
                                unit: "g",
                                color: .red
                            )
                            
                            NutrientInputField(
                                label: "脂質",
                                value: $fat,
                                unit: "g",
                                color: .orange
                            )
                        }
                        
                        HStack(spacing: 12) {
                            NutrientInputField(
                                label: "炭水化物",
                                value: $carbs,
                                unit: "g",
                                color: .green
                            )
                            
                            NutrientInputField(
                                label: "カロリー",
                                value: $calories,
                                unit: "kcal",
                                color: .purple
                            )
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // 保存ボタン
                Button(action: addFood) {
                    Text("食材を追加")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)
                .padding()
            }
            .navigationTitle("食材追加")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !protein.isEmpty && !fat.isEmpty && !carbs.isEmpty && !calories.isEmpty
    }
    
    private func addFood() {
        guard let proteinValue = Double(protein),
              let fatValue = Double(fat),
              let carbsValue = Double(carbs),
              let caloriesValue = Double(calories) else {
            alertMessage = "数値を正しく入力してください"
            showingAlert = true
            return
        }
        
        guard proteinValue >= 0 && fatValue >= 0 && carbsValue >= 0 && caloriesValue >= 0 else {
            alertMessage = "負の数は入力できません"
            showingAlert = true
            return
        }
        
        let newFood = Food(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            protein: proteinValue,
            fat: fatValue,
            carbs: carbsValue,
            calories: caloriesValue
        )
        
        foodStore.addFood(newFood)
        dismiss()
    }
}

struct NutrientInputField: View {
    let label: String
    @Binding var value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color.opacity(0.8))
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    AddFoodView()
        .environmentObject(FoodStore())
}