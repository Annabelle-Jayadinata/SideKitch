//
//  WIPGroceryView.swift
//  SideKitch
//
//  Created by Febie Lin on 2/21/25.
//

import SwiftUI

struct IngredientSectionView: View {
    var title: String
    var ingredients: [Ingredient]
    var onDelete: (Ingredient) -> Void
    var onSwitch: (Ingredient) -> Void

    var body: some View {
        Section(header: Text(title).font(.headline).foregroundStyle(.tint)) {
            ForEach(ingredients, id: \.id) { ingredient in
                IngredientView(ingredient: ingredient, displayUnit: ingredient.unit)
                    .swipeActions(edge: .leading) {
                        Button(action: {
                            onSwitch(ingredient)
                        }) {
                            Label("Move", systemImage: "repeat")
                                .foregroundColor(.blue)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(action: {
                            onDelete(ingredient)
                        }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
            }
        }
    }
}



struct WIPGroceryList: View {
    @State private var finalizedList: GroceryListModel?
    @State private var isAddRecipePresented = false
    @State private var isListPublished = false
    @State private var navigateToCookbook = false
    
    @State private var listName: String = ""
    @State private var isNamePromptPresented = false
    
    @State private var isRecipeListPresented: Bool = false
    @State private var recipes_list: [String: Int] = [:]
    
    @Environment(\.modelContext) private var context

    let currentDate = Date()
   
    @EnvironmentObject var wipList: WIPGroceryListModel

    var body: some View {
        NavigationView {
            VStack {
                // TOP BAR
                HStack {
                    Button(action: {
                        isAddRecipePresented = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Pin New Recipe")
                        }
                    }
                    .sheet(isPresented: $isAddRecipePresented) {
                        HomeView()
                        .presentationDetents([.medium])
                    }

                    
                    Spacer()
                    
                    Button(action: {
                        isRecipeListPresented = true
                        recipes_list = wipList.display_recipes()
                    }) {
                        HStack {
                            Image(systemName: "pin.fill")
                            Text("Pinned Recipes")
                        }
                    }
                    .sheet(isPresented: $isRecipeListPresented) {
                        VStack {
                            Text("Pinned Recipes")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding()
                            
                            ForEach(Array(recipes_list), id: \.key) { (key, value) in
                                
                                HStack {
                                    Text(key)
                                    Spacer()
                                    Text("Count: \(value)")
                                }
                                
                            }
                            Spacer()
                            
                        }
                        .padding()
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .onDisappear {
                            isRecipeListPresented = false
                        }
                    }

                }
                .padding()
    
                Text("In Progress: Grocery List")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.secondary)
                    
                    Text(
                        DateFormatter.localizedString(from: currentDate, dateStyle: .medium, timeStyle: .short)
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)
                    
                    
                Button(action: {
                    isNamePromptPresented = true
                }) {
                    HStack {
                        Text("PUBLISH")
                            .fontWeight(.bold)
                    }
                }
                .padding(3)
                .padding(.horizontal, 5)
                .background(.accent)
                .cornerRadius(3)
                .foregroundStyle(.white)
                .sheet(isPresented: $isNamePromptPresented) {
                    VStack {
                        Text("Please name your list:")
                            .font(.headline)
                        
                        TextField("Enter list name", text: $listName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button("Done") {
                            isListPublished = true
                            isNamePromptPresented = false
                            finalizedList = wipList.finalize(list_name: listName)
                            context.insert(finalizedList!)
                            
                        }
                        .padding()
                        .disabled(listName.isEmpty)
                    }
                    .padding()
                    .presentationDetents([.fraction(0.25)])
                    .presentationDragIndicator(.visible)
                }

                
                List {
                    // NEED TO PURCHASE
                    IngredientSectionView(
                        title: "Need to Purchase",
                        ingredients: wipList.dont_have,
                        onDelete: { ingredient in
                            wipList.remove_item_from_dont_have(ingredient: ingredient)
                        },
                        onSwitch: { ingredient in
                            wipList.remove_item_from_dont_have(ingredient: ingredient)
                            wipList.add_item_to_have(ingredient: ingredient)
                        }
                    )
                    
                    // OWNED
                    IngredientSectionView(
                        title: "Owned",
                        ingredients: wipList.have,
                        onDelete: { ingredient in
                            wipList.remove_item_from_have(ingredient: ingredient)
                        },
                        onSwitch: { ingredient in
                            wipList.remove_item_from_have(ingredient: ingredient)
                            wipList.add_item_to_dont_have(ingredient: ingredient)
                        }
                    )
                }
            }
        }
    }
}

struct WIPGroceryList_Previews: PreviewProvider {
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
        
        WIPGroceryList()
            .environmentObject(mockWipList)
    }
}
