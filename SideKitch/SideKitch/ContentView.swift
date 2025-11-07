//
//  ContentView.swift
//  SideKitch
//
//  Created by Febie Lin on 02/05/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 1
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var wipList:WIPGroceryListModel
    
    let globDataSave: () -> Void
    var body: some View {
            
        TabView(selection: $selectedTab) {
            PantryView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Pantry")
                }
                .tag(0)
            
            AllGroceryLists()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Grocery Lists")
                }
                .tag(1)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)
            
            HomeView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Cookbook")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .onChange(of: scenePhase) { phase in // This saves on exit of app. so a crash or phone dying will probably loose data
            if phase == .inactive { globDataSave() }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockWipList = WIPGroceryListModel.init(
            have: [
                Ingredient(unit: "lb", quantity: 20, descriptors: ["fresh"], name: "Flour", origText: "200 grams of flour"),
                Ingredient(unit: "tbsp", quantity: 2, descriptors: ["heaping"], name: "Sugar", origText: "2 tablespoons of sugar"),
                Ingredient(unit: "oz", quantity: 150, descriptors: ["cold"], name: "Water", origText: "150 ml of water")
            ],
            dont_have: [
                Ingredient(unit: "oz", quantity: 150, descriptors: ["cold"], name: "Water", origText: "150 ml of water"),
                Ingredient(unit: "cups", quantity: 1, descriptors: ["unsweetened"], name: "Cocoa Powder", origText: "1 cup of cocoa powder"),
                Ingredient(unit: "tbsp", quantity: 1, descriptors: ["vanilla"], name: "Vanilla Extract", origText: "1 teaspoon of vanilla extract"),
                Ingredient(unit: "ct", quantity: 9, descriptors: ["brown"], name: "Banana", origText: "9 ripe brown bananas")
            ]
        )
        
        let mockPantry = PantryModel.init(
            ingr: [
                Ingredient(unit: "lb", quantity: 20, descriptors: ["fresh"], name: "Dirt", origText: "200 grams of flour"),
                Ingredient(unit: "tbsp", quantity: 2, descriptors: ["heaping"], name: "Soil", origText: "2 tablespoons of sugar"),
                Ingredient(unit: "oz", quantity: 150, descriptors: ["cold"], name: "Gravel", origText: "150 ml of water")
            ]
        )
        
        ContentView( globDataSave: {})
            .environmentObject(mockWipList)
            .environmentObject(mockPantry)
    }
}
