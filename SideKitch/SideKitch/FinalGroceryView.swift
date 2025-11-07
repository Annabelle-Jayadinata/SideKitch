//
//  FinalGroceryView.swift
//  SideKitch
//
//  Created by Caleb Matthews on 2/4/25.
//

import SwiftUI


// View for each item on the list
struct GroceryListItemView: View {
    @State private var isExpanded = false
    
    @Binding var groceryList: GroceryListModel
    @EnvironmentObject var pantry: PantryModel
    var ingredient: Ingredient
    let units = ["lb", "oz", "tbsp", "ct"]
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Button(action: {
                    moveIngredient(ingredient)
                }) {
                    Image(systemName: groceryList.ingredients_acquired.contains(where: { $0.id == ingredient.id }) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.blue)
                }

                Text(ingredient.name)
                    .frame(width: geometry.size.width * 0.45, alignment: .leading)
                    .font(.system(size: geometry.size.width * 0.05))
                
                Text("\(ingredient.quantity, specifier: "%.2f")")
                    .font(.system(size: geometry.size.width * 0.05))
                    .frame(width: geometry.size.width * 0.2, alignment: .trailing)
                
                
                Menu {
                    ForEach(units, id: \.self) { unit in
                        Button(unit) {
                            ingredient.unit = unit
                        }
                    }
                } label: {
                    HStack {
                        Text(ingredient.unit)
                            .font(.body)
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.black)
                    }
                }
                .frame(width: geometry.size.width * 0.25, alignment: .trailing)
                .font(.system(size: geometry.size.width * 0.05))

            }
            .frame(height: geometry.size.height)

        }
        
    }
    private func moveIngredient(_ ingredient: Ingredient) {
        // UNCHECK ITEM
        if groceryList.ingredients_acquired.contains(where: { $0.id == ingredient.id }) {
            if let index = groceryList.ingredients_acquired.firstIndex(where: { $0.id == ingredient.id }) {
                groceryList.ingredients_acquired.remove(at: index)
                groceryList.ingredients_missing.append(ingredient)
                pantry.deduct_ingr(ing : ingredient, quantity: ingredient.quantity , unit : ingredient.unit)
            }
            
        // CHECK ITEM
        } else {
            if let index = groceryList.ingredients_missing.firstIndex(where: { $0.id == ingredient.id }) {
                let acquiredIngredient = groceryList.ingredients_missing.remove(at: index)
                groceryList.ingredients_acquired.append(acquiredIngredient)
                pantry.add_ingr(ing: acquiredIngredient, quantity: acquiredIngredient.quantity, unit: acquiredIngredient.unit)
            }
        }
    }
}



struct FinalGroceryView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false
    @State private var currentView = "shoppingView"
    @State var groceryList:GroceryListModel
    
    var body: some View {
        NavigationView {
            VStack {
                // TOP BAR
                HStack {
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    Spacer()
                    
                    Button(action: {
                        showAlert = true
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete")
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Ready to close out your shopping list?"),
                            message: Text("Once you complete this list, it cannot be undone."),
                            primaryButton: .destructive(Text("Yes")) {
                                modelContext.delete(groceryList)
                                
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Failed to delete grocery list: \(error)")
                                }
                                presentationMode.wrappedValue.dismiss()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .padding(5)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .background(.accent)
                    .cornerRadius(5)
                
                    
                }
                .padding(.horizontal)
                
                Text(groceryList.name)
                    .font(.title)
                    .bold()
                
                Text(
                    DateFormatter.localizedString(from: groceryList.creation_date, dateStyle: .medium, timeStyle: .short)
                )
                .font(.body)

                
                List {
                    // CURRENTLY SORTED ALPHABETICALLY. CHECKED ITEMS GO DOWN
//                    let sortedIngredientsMissing = groceryList.ingredients_missing.sorted { $0.name < $1.name }
//                    let sortedIngredientsAcquired = groceryList.ingredients_acquired.sorted { $0.name < $1.name }
//
//                    ForEach(sortedIngredientsMissing + sortedIngredientsAcquired, id: \.id) { ingredient in
//                        GroceryListItemView(groceryList: $groceryList, ingredient: ingredient)
//                    }
                    
                    // SORTED ALPHABETICALLY, NO REORDERING OF LIST ITEMS UPON CHECK
                    ForEach((groceryList.ingredients_missing + groceryList.ingredients_acquired).sorted {$0.name < $1.name }, id: \.id) { ingredient in
                        GroceryListItemView(groceryList: $groceryList, ingredient: ingredient)
                    }
                }
                .listStyle(PlainListStyle()) // new list style??? do we like this more???

            }
            .navigationBarBackButtonHidden(true)
        }
    }
}



    
struct FinalGroceryView_Previews: PreviewProvider {
    static var previews: some View {
        let grocList = GroceryListModel(
            name: "testList",
            ingredients:     [
                Ingredient(unit: "lb", quantity: 20, descriptors: ["fresh"], name: "Flour", origText: "200 grams of flour"),
                Ingredient(unit: "tbsp", quantity: 2, descriptors: ["heaping"], name: "Sugar", origText: "2 tablespoons of sugar"),
                Ingredient(unit: "oz", quantity: 150, descriptors: ["cold"], name: "Water", origText: "150 ml of water"),
                Ingredient(unit: "cups", quantity: 1, descriptors: ["unsweetened"], name: "Unsweetened Cocoa Powder Extreme Yumminess ", origText: "1 cup of cocoa powder"),
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
        
        FinalGroceryView( groceryList: grocList)
            .environmentObject(mockPantry)
    }
}
