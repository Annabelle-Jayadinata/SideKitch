//
//  RecipeInputView.swift
//  SideKitch
//
//  Created by Annabelle Jayadinata on 20/02/25.
//

import SwiftUI
import PhotosUI

struct RecipeInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) var modelContext

    @Bindable var recipe: Recipe
    @State private var editedRecipe: Recipe
    @State private var showDeleteAlert = false

    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _editedRecipe = State(initialValue: Recipe(
            title: recipe.title,
            ingredients: recipe.ingredients.map { Ingredient(unit: $0.unit, quantity: $0.quantity, name: $0.name, origText: $0.origText) },
            instructions: recipe.instructions,
            imageUrl: recipe.imageUrl,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            totalTime: recipe.totalTime,
            servings: recipe.servings
        ))
    }

    var body: some View {
        NavigationView {
            Form {
                // --- Recipe Title ---
                Section(header: Text("Recipe Title")) {
                    TextField("Enter recipe title", text: $editedRecipe.title)
                }

                // --- Recipe Details ---
                Section(header: Text("Recipe Details")) {
                    HStack {
                        Text("Prep Time")
                        TextField("e.g. 15", text: $editedRecipe.prepTime.unwrap(defaultValue: ""))
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Cook Time")
                        TextField("e.g. 40", text: $editedRecipe.cookTime.unwrap(defaultValue: ""))
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Total Time")
                        Text("\(calculateTotalTime(prepTime: editedRecipe.prepTime, cookTime: editedRecipe.cookTime))")
                    }
                    HStack {
                        Text("Servings")
                        TextField("e.g. 2", text: $editedRecipe.servings.unwrap(defaultValue: ""))
                            .keyboardType(.numberPad)
                    }
                }

                // --- Ingredients Section ---
                Section(header: Text("Ingredients")) {
                    ForEach($editedRecipe.ingredients.indices, id: \.self) { index in
                        HStack {
                            TextField("Ingredient", text: $editedRecipe.ingredients[index].name)
                                .onChange(of: editedRecipe.ingredients[index].name) { newValue in
                                    DispatchQueue.main.async {
                                        if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                            editedRecipe.ingredients[index].name = ""
                                        }
                                    }
                                }

                            TextField("Qty", value: $editedRecipe.ingredients[index].quantity, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)

                            Menu {
                                ForEach(["cup", "teaspoon", "tablespoon", "oz", "g", "kg", "lb", "ct", "None"], id: \.self) { unit in
                                    Button(unit) {
                                        if index < editedRecipe.ingredients.count {
                                            editedRecipe.ingredients[index].unit = unit
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(index < editedRecipe.ingredients.count ? editedRecipe.ingredients[index].unit : "")
                                    Image(systemName: "chevron.down").foregroundColor(.gray)
                                }
                            }

                            Button(action: {
                                if index < editedRecipe.ingredients.count { // Prevent index out of range
                                    editedRecipe.ingredients.remove(at: index)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill").foregroundColor(.red)
                            }
                        }
                    }

                    Button(action: {
                        DispatchQueue.main.async {
                            editedRecipe.ingredients.append(Ingredient(unit: "", quantity: 1.0, name: "", origText: ""))
                        }
                    }) {
                        Label("Add Ingredient", systemImage: "plus")
                    }
                }

                // --- Instructions Section ---
                Section(header: Text("Instructions")) {
                    ForEach(Array(editedRecipe.instructions.indices), id: \.self) { index in
                        if index < editedRecipe.instructions.count { // Prevent out-of-range errors
                            HStack {
                                TextEditor(text: Binding(
                                    get: { index < editedRecipe.instructions.count ? editedRecipe.instructions[index] : "" },
                                    set: { newValue in
                                        if index < editedRecipe.instructions.count {
                                            editedRecipe.instructions[index] = newValue
                                        }
                                    }
                                ))
                                .frame(minHeight: 50)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))

                                Button(action: {
                                    if index < editedRecipe.instructions.count {
                                        DispatchQueue.main.async {
                                            editedRecipe.instructions.remove(at: index)
                                        }
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    Button(action: {
                        DispatchQueue.main.async {
                            editedRecipe.instructions.append("")
                        }
                    }) {
                        Label("Add Step", systemImage: "plus")
                    }
                }
                
                // --- Image Section (Choose from Gallery) ---
                RecipeImagePickerView(
                    selectedImage: $selectedImage,
                    imageData: $imageData,
                    imageUrl: $editedRecipe.imageUrl
                )

                // --- Delete Recipe Button ---
                if recipe.id != nil {
                    Section {
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete Recipe", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .alert(isPresented: $showDeleteAlert) {
                            Alert(
                                title: Text("Are you sure?"),
                                message: Text("This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete")) {
                                    modelContext.delete(recipe)
                                    presentationMode.wrappedValue.dismiss()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    withAnimation {
                        recipe.title = editedRecipe.title
                        recipe.ingredients = editedRecipe.ingredients
                        recipe.instructions = editedRecipe.instructions
                        recipe.prepTime = editedRecipe.prepTime
                        recipe.cookTime = editedRecipe.cookTime
                        recipe.totalTime = editedRecipe.totalTime
                        recipe.servings = editedRecipe.servings
                        recipe.imageUrl = editedRecipe.imageUrl
                        
                        // Store image
                        if let imageData {
                            let imageName = UUID().uuidString + ".jpg"
                            let imageURL = saveImageToDocuments(data: imageData, name: imageName)
                            recipe.imageUrl = imageURL?.absoluteString
                        } else {
                            recipe.imageUrl = editedRecipe.imageUrl
                        }
                        
                        // Attempt to insert the recipe; SwiftData will ignore if it already exists
                        modelContext.insert(recipe)

                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // Save image to local directory
    private func saveImageToDocuments(data: Data, name: String) -> URL? {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(name)
        if let fileURL = fileURL {
            do {
                try data.write(to: fileURL)
                return fileURL
            } catch {
                print("Failed to save image:", error)
            }
        }
        return nil
    }

    private func calculateTotalTime(prepTime: String?, cookTime: String?) -> String {
        let prep = Int(prepTime ?? "") ?? 0
        let cook = Int(cookTime ?? "") ?? 0
        return "\(prep + cook)"
    }
}


extension Binding where Value == String? {
    func unwrap(defaultValue: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

struct RecipeInputView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRecipe = Recipe(
            title: "Spaghetti Carbonara",
            ingredients: [
                Ingredient(unit: "g", quantity: 200, name: "Spaghetti", origText: "200g Spaghetti"),
                Ingredient(unit: "", quantity: 2, name: "Eggs", origText: "2 Eggs"),
                Ingredient(unit: "g", quantity: 50, name: "Parmesan Cheese", origText: "50g Parmesan Cheese"),
                Ingredient(unit: "g", quantity: 100, name: "Bacon", origText: "100g Bacon")
            ],
            instructions: [
                "Boil pasta until al dente.",
                "Fry bacon until crisp.",
                "Mix eggs and cheese in a bowl.",
                "Combine pasta, bacon, and egg mixture."
            ],
            imageUrl: nil,
            prepTime: "10",
            cookTime: "15",
            totalTime: "25",
            servings: "2"
        )

        RecipeInputView(recipe: sampleRecipe)
    }
}


