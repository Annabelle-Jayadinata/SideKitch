//
//  AddIngredientInput.swift
//  SideKitch
//
//  Created by Caleb Matthews on 2/24/25.
//
// TODO: GET WORKING
// Still, WIP, but running out of noggin juice, so hopefully will get this up tomorrow before the demo, but either way is pretty good!
/*
import SwiftUI

 class Ingredient: Identifiable , Hashable, Codable {
     var id = UUID()
     var unit: String
     var quantity: Int
     var descriptors: [String]
     var name: String
     var origText: String
     
     init(unit: String, quantity: Int, descriptors: [String] = [], name: String, origText: String = "") {
         self.unit = unit
         self.quantity = quantity
         self.descriptors = descriptors
         self.name = name
         self.origText = origText
     }
 
struct AddIngredientInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) var modelContext

    @State private var title: String
    @State private var unit: String
    @State private var quantity: Int
    @State private var descriptors: [String]
    @State private var name: String
    @State private var origText: String
    
    private var existingRecipe: Recipe?
    
    var onSave: (Recipe) -> Void
    
    /// Supports creating a new recipe or editing an existing one

    init(existingRecipe: Recipe? = nil, onSave: @escaping (Recipe) -> Void) {
        self.existingRecipe = existingRecipe
        
        self.title = State(initialValue: existingRecipe?.title ?? "")
        _ingredients = State(initialValue: existingRecipe?.ingredients ?? [""])
        _instructions = State(initialValue: existingRecipe?.instructions ?? [""])
        _prepTime = State(initialValue: existingRecipe?.prepTime ?? "")
        _cookTime = State(initialValue: existingRecipe?.cookTime ?? "")
        _totalTime = State(initialValue: existingRecipe?.totalTime ?? "")
        _servings = State(initialValue: existingRecipe?.servings ?? "")
        _imageUrl = State(initialValue: existingRecipe?.imageUrl ?? "")
        
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                // --- Recipe Title ---
                Section(header: Text("Recipe Title")) {
                    TextField("\"Grandma's Famous Jell-O\"", text: $title)
                }
                
                // --- Recipe Details ---
                Section(header: Text("Recipe Details")) {
                    TextField("Prep time in minutes", text: $prepTime)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Cook time in minutes", text: $cookTime)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Serves twelve", text: $servings)
                        .keyboardType(.numberPad)
                }
                
                // --- Ingredients Section ---
                Section(header: Text("Ingredients")) {
                    ForEach(ingredients.indices, id: \.self) { index in
                        TextField("Ingredient \(index + 1)", text: $ingredients[index])
                    }
                    Button(action: { ingredients.append("") }) {
                        Label("Add Ingredient", systemImage: "plus")
                    }
                }
                
                
                // --- Image URL Section (Optional) ---
                Section(header: Text("Insert Image (Optional)")) {
                    Menu("Add Image", systemImage: "plus") {
                        Button(action: {}) {
                            Label("Upload from Device", systemImage: "photo")
                        }
                        Button(action: {}) {
                            Label("Insert URL", systemImage: "link")
                        }
                    }
                }
            }
            .navigationTitle(existingRecipe == nil ? "Enter Recipe" : "Edit Recipe")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

                    //let filteredIngredients = ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    //let filteredInstructions = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                    //onSave(updatedRecipe)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

struct AddIngredientInputView_Previews: PreviewProvider {
    static var previews: some View {
        //AddIngredientInputView(onSave: { recipe in
            // Mock save action for preview})
    }
}
*/
