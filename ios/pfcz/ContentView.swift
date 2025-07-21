//
//  ContentView.swift
//  pfcz
//
//  Created by なたてここ on 2025/07/08.
//

import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var foodEntryStore: FoodEntryStore
    
    var body: some View {
        VStack(spacing: 20) {
            // 今日の合計表示
            VStack {
                Text("今日の合計")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Text("kcal: \(foodEntryStore.todayTotalCalories, specifier: "%.0f")")
                }
                .font(.headline)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            // P/F/C横棒グラフ
            Chart {
                BarMark(
                    x: .value("Amount", foodEntryStore.todayTotalProtein),
                    y: .value("Nutrient", "Protein")
                )
                .foregroundStyle(.red.opacity(0.8))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(foodEntryStore.todayTotalProtein, specifier: "%.1f")g")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                BarMark(
                    x: .value("Amount", foodEntryStore.todayTotalFat),
                    y: .value("Nutrient", "Fat")
                )
                .foregroundStyle(.orange.opacity(0.8))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(foodEntryStore.todayTotalFat, specifier: "%.1f")g")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                BarMark(
                    x: .value("Amount", foodEntryStore.todayTotalCarbs),
                    y: .value("Nutrient", "Carb")
                )
                .foregroundStyle(.green.opacity(0.8))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(foodEntryStore.todayTotalCarbs, specifier: "%.1f")g")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .frame(height: 150)
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.background(.clear)
            }
            
            // 食事記録リスト
            VStack(alignment: .leading) {
                Text("食事記録（タップで削除）")
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    ForEach(foodEntryStore.entries) { entry in
                        HStack {
                            Text("\(entry.food.name)　\(entry.food.calories, specifier: "%.0f") kcal")
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            foodEntryStore.remove(entry: entry)
                        }
                    }
                    .onDelete(perform: foodEntryStore.remove)
                }
            }
            
            // 食材選択（横スクロール）
            VStack(alignment: .leading) {
                Text("食材を選択")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(foodStore.foods) { food in
                            Button(action: {
                                foodEntryStore.add(food: food)
                            }) {
                                Text(food.name)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("PFC カウンター")
    }
}

#Preview {
    ContentView()
        .environmentObject(FoodStore())
        .environmentObject(FoodEntryStore())
}
