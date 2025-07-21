//
//  pfczApp.swift
//  pfcz
//
//  Created by なたてここ on 2025/07/08.
//

import SwiftUI

@main
struct pfczApp: App {
    @StateObject private var foodStore = FoodStore()
    @StateObject private var foodEntryStore = FoodEntryStore()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeView()
                    .environmentObject(foodStore)
                    .environmentObject(foodEntryStore)
            }
        }
    }
}
