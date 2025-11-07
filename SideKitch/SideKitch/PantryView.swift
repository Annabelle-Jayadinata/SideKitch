//
//  PantryView.swift
//  SideKitch
//
//  Created by Febie Lin on 2/5/25.
//

import SwiftUI

struct PantryView: View {
    // add pantry item
    @State private var showAddItemSheet = false
    @State private var ingredientName = ""
    @State private var ingredientQuantity: Float = 1.0
    @State private var ingredientUnit = "ct"
    
    
    // edit pantry item
    @State private var selectedIngredient: Ingredient? = nil
    @State private var showEditSheet = false
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity: Float = 99.0
    @State private var newIngredientUnit = "ct"
    
    @EnvironmentObject var pantry: PantryModel
    let units = ["lb", "oz", "tbsp", "ct"]

    var body: some View {

        NavigationView {
            VStack(spacing: 16) {
                
                
                HStack{
                    Button(action: {
                        showAddItemSheet = true

                    }) {
                        Image(systemName: "plus.circle")
                        Text("Add Item")
                    }
                    
                    Spacer()
                }
                .padding()
                
                Text("What's in the Pantry?")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView {
                    ForEach(pantry.ingr) { ingredient in // TODO - turn to pantry.ingr once we have an exposed ui to input pantry ingr - ben
                        IngredientPantryView(ingredient: ingredient)
                            .foregroundColor(.black)
                            .background(Color(UIColor.secondarySystemBackground)) // Card background
                            .cornerRadius(10) // Rounded corners
                            .shadow(radius: 2) // Add shadow for depth
                            .padding(.horizontal) // Horizontal padding
                            .onTapGesture {
                                selectedIngredient = ingredient
                                newIngredientName = ingredient.name
                                newIngredientQuantity = ingredient.quantity
                                newIngredientUnit = ingredient.unit
                                showEditSheet.toggle()
                            }
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showEditSheet) {
                
                VStack {
                    
                    Text("Edit Ingredient")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    HStack {
                        Text("Name: ")
                            .fontWeight(.bold)
                        
                        TextField("e.g. All-purpose flour", text: $newIngredientName)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("Quantity: ")
                            .fontWeight(.bold)
                        
                        TextField("e.g. 1", value: $newIngredientQuantity, format: .number)
                            .keyboardType(.decimalPad)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Picker("", selection: $newIngredientUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    Button(action: {
                        
                        if let ingredient = selectedIngredient {
                            
                            pantry.deduct_ingr(ing: ingredient, quantity: ingredient.quantity, unit: ingredient.unit)
                            
                            pantry.add_ingr(
                                ing: Ingredient(unit: newIngredientUnit, quantity: newIngredientQuantity, name: newIngredientName),
                                quantity: newIngredientQuantity,
                                unit: newIngredientUnit)
                            
                            newIngredientName = ""
                            newIngredientQuantity = 99.0
                            newIngredientUnit = "ct"
                            selectedIngredient = nil
                            
                        }
                        showEditSheet = false
                    
                    }) {
                        Text("Save Changes")
                            .foregroundColor(.white)
                            .padding()
                            .background(.accent)
                            .cornerRadius(10)
                    }
                }
                .presentationDetents([.medium])
                .cornerRadius(20)
                .padding()
            }
            .sheet(isPresented: $showAddItemSheet) { // FORM FOR ADDING ITEM
                VStack {
                    Text("Add Ingredient")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()

                        HStack {
                            Text("Name: ")
                                .fontWeight(.bold)
                            
                            TextField("e.g. All-purpose flour", text: $ingredientName)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()

                        HStack {
                            Text("Quantity: ")
                                .fontWeight(.bold)
                            
                            TextField("e.g. 1", value: $ingredientQuantity, format: .number)
                                .keyboardType(.decimalPad)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Picker("", selection: $ingredientUnit) {
                                ForEach(units, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        
                    Button(action: {
                        showAddItemSheet = false
                        
                        // update pantry with the new item
                        pantry.add_ingr(
                            ing: Ingredient(unit: ingredientUnit, quantity: ingredientQuantity, descriptors: [], name: ingredientName, origText: ingredientName),
                            quantity: ingredientQuantity,
                            unit: ingredientUnit
                        )
                        
                        // reset
                        ingredientName = ""
                        ingredientQuantity = 1.0
                        ingredientUnit = "ct"
                    }) {
                        Text("Save Ingredient")
                            .foregroundColor(.white)
                            .padding()
                            .background(.accent)
                            .cornerRadius(10)
                    }
                }
                .presentationDetents([.medium])
                .cornerRadius(20)
                .padding()
            }
            
            Spacer()
        }
    }
}

struct PantryView_Previews: PreviewProvider {
    static var previews: some View {
        
        let mockPantry = PantryModel.init(
            ingr: [
                Ingredient(unit: "ct", quantity: 3, descriptors: ["Fresh"], name: "Eggs", origText: "3 eggs"),
                Ingredient(unit: "ct", quantity: 0, descriptors: ["Ripe"], name: "Tomatoes", origText: "No tomatoes"),
                Ingredient(unit: "oz", quantity: 7, descriptors: ["All-purpose"], name: "Flour", origText: "7 cups of flour"),
                Ingredient(unit: "lb", quantity: 2, descriptors: ["Whole"], name: "Milk", origText: "2 lbs of milk"),
                Ingredient(unit: "ct", quantity: 10, descriptors: ["Cheddar"], name: "Cheese", origText: "10 slices of cheese")
            ]
        )
        
        PantryView()
            .environmentObject(mockPantry)
    }
}


