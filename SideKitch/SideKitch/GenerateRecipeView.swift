//
//  GenerateRecipeView.swift
//  SideKitch
//
//  Created by Annabelle Jayadinata on 03/03/25.
//

import SwiftUI

struct GenerateRecipeView: View {
    @EnvironmentObject var pantry: PantryModel
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Binding var selectedIngredients: Set<String>
    @Binding var generatedRecipe: Recipe?
    @Binding var isLoadingRecipe: Bool
    @Binding var errorMessage: String?
    
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select Ingredients")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                List(pantry.ingr, id: \.name) { ingredient in
                    HStack {
                        Text("\(ingredient.name) (\(Ingredient.qString(q: ingredient.quantity)) \(ingredient.unit))")
                            .fontWeight(selectedIngredients.contains(ingredient.name) ? .bold : .regular)

                        Spacer()

                        Image(systemName: selectedIngredients.contains(ingredient.name) ? "checkmark.square.fill" : "square")
                            .onTapGesture {
                                if selectedIngredients.contains(ingredient.name) {
                                    selectedIngredients.remove(ingredient.name)
                                } else {
                                    selectedIngredients.insert(ingredient.name)
                                }
                            }
                    }
                }

                .listStyle(PlainListStyle())
                
                Button(action: generateRecipe) {
                    HStack {
                        if isLoadingRecipe {
                            ProgressView()
                        }
                        Text("Generate Recipe")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                }
                .disabled(isLoadingRecipe || selectedIngredients.isEmpty)
                .padding()
                
                if let errorMessage = errorMessage, showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Generate Recipe")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }
    
    func generateRecipe() {
        isLoadingRecipe = true
        errorMessage = nil
        showError = false

        let apiKey = "AIzaSyAquULZF2ZkmHCzCfMJhP0BhV_vGe_VyoM"
        let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let ingredientData = selectedIngredients.compactMap { ingredientName -> String? in
            if let pantryIngredient = pantry.ingr.first(where: { $0.name == ingredientName }) {
                return "{ \"quantity\": \"\(Ingredient.qString(q: pantryIngredient.quantity))\", \"unit\": \"\(pantryIngredient.unit)\", \"item\": \"\(pantryIngredient.name)\" }"
            }
            return nil
        }.joined(separator: ", ")

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [[
                    "text": """
                    Generate a recipe using ONLY these ingredients with their exact quantities:
                    [\(ingredientData)]
                    
                    Format the response as JSON:
                    {
                        "title": "Recipe Name",
                        "ingredients": [...], // This should match the pantry exactly.
                        "instructions": "Step-by-step instructions",
                        "prep_time": "X minutes",
                        "cook_time": "Y minutes",
                        "total_time": "Z minutes",
                        "servings": "Number of servings"
                    }
                    """
                ]]]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoadingRecipe = false

                if let error = error {
                    errorMessage = "Failed to fetch recipe: \(error.localizedDescription)"
                    showError = true
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received from server."
                    showError = true
                    return
                }

                do {
                    let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    print("Raw API Response: \(responseDict ?? [:])") // Debugging
                    
                    guard let candidates = responseDict?["candidates"] as? [[String: Any]],
                          let firstCandidate = candidates.first,
                          let content = firstCandidate["content"] as? [String: Any],
                          let parts = content["parts"] as? [[String: Any]],
                          let firstPart = parts.first,
                          var recipeText = firstPart["text"] as? String else {
                        errorMessage = "Invalid response from AI."
                        showError = true
                        return
                    }
                    
                    // Remove backticks from the JSON
                    recipeText = recipeText.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

                    // Parse JSON into RecipeParse
                    guard let jsonData = recipeText.data(using: .utf8),
                          let parsedRecipe = try? JSONDecoder().decode(RecipeParse.self, from: jsonData) else {
                        errorMessage = "Failed to parse structured recipe."
                        showError = true
                        return
                    }

                    let prepTime = extractTime(from: parsedRecipe.prep_time)
                    let cookTime = extractTime(from: parsedRecipe.cook_time)
                    let totalTime = String((Int(prepTime) ?? 0) + (Int(cookTime) ?? 0))
                    
                    // Fix instructions formatting
                    let cleanedInstructions = parsedRecipe.instructions.split(separator: "\n").map { step in
                        step.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                    }

                    let finalRecipe = Recipe(
                        title: parsedRecipe.title,
                        ingredients: parsedRecipe.ingredients.map { Ingredient(unit: $0.unit, quantity: Float($0.quantity) ?? 0, name: $0.item) },
                        instructions: cleanedInstructions,
                        prepTime: prepTime,
                        cookTime: cookTime,
                        totalTime: totalTime,
                        servings: parsedRecipe.servings
                    )

                    // Save to cookbook
                    withAnimation {
                        modelContext.insert(finalRecipe)
                    }

                    generatedRecipe = finalRecipe
                    dismiss()
                    
                } catch {
                    errorMessage = "Failed to parse recipe data."
                    showError = true
                }

            }
        }.resume()
    }
}

func extractTime(from text: String) -> String {
    let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                      .joined()
    return numbers.isEmpty ? "0" : numbers
}

struct GenerateRecipeView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateRecipeView(
            selectedIngredients: .constant(Set(["Eggs", "Milk"])),
            generatedRecipe: .constant(nil),
            isLoadingRecipe: .constant(false),
            errorMessage: .constant(nil)
        ).environmentObject(PantryModel(ingr: [
            Ingredient(unit: "", quantity: 3, name: "Eggs"),
            Ingredient(unit: "", quantity: 1, name: "Milk")
        ]))
    }
}
