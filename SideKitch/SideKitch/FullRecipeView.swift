//
//  FullRecipeView.swift
//  SideKitch
//
//  Created by Ben Ruland on 2/12/25.
//

import SwiftUI
import CoreHaptics

struct FullRecipeView: View {
    @Bindable var recipe: Recipe
    @State private var showEditSheet = false // Toggle for edit sheet
    @State private var isClicked = false
    @State private var trigger: Int = 0
    @State private var recipePinned = false
    @State private var hapticEngine: CHHapticEngine?
    @EnvironmentObject private var pantry:PantryModel
    @EnvironmentObject private var wipList:WIPGroceryListModel
    @State private var scaleFactor: Double = 1.0
    @State private var customScaleFactor: String = ""
    @State private var useCustomScale = false

    
    let fillDuration: Double = 2.0 // Duration for the full fill

    
    var body: some View {
    
        
        HStack {
            Button(action: {
                recipePinned = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    recipePinned = false
                }
//                wipList.recipes[recipe.title] += 1
                
                
                // populate wipList with ingredients
                WIPGroceryListModel.add_recipe(grocList: wipList, recipe: recipe, pantry: pantry)
            }) {
                HStack {
                    if recipePinned {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Recipe pinned")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "pin.fill")
                        Text("Pin Recipe to List")
                    }
                }
            }
            
            Spacer()

            HStack {
                Image(systemName: "pin.fill")
                Text("\(wipList.recipes[recipe.title] ?? 0)")
                
            }
            
        }
        .foregroundStyle(.accent)
        .padding()
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // --- Title Section ---
                Text(recipe.title)
                    .onAppear {
                        prepareHaptics()
                    }
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                    .padding(.horizontal)
                
                // --- Image Section ---
                if let imageUrl = recipe.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView() // Show loading spinner
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 4)
                                .padding(.horizontal)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Spacer()
                    HStack {
                        Image(systemName: "timer")
                            .font(.system(size: 28))
                            .padding(.horizontal)
                        Text("\(calculateTotalTime(prepTime: recipe.prepTime, cookTime: recipe.cookTime)) mins")
                            .font(.system(size: 18))
                            .font(.headline)
                    }
                    .padding()

                    .foregroundStyle(.accent)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 28))
                            .padding(.horizontal)
                        Text(recipe.servings != nil ? "\(recipe.servings!) servings" : "N/A")
                            .font(.system(size: 18))
                            .font(.headline)

                    }
                    .padding()
                    .foregroundStyle(.accent)
                    
                    Spacer()
                }
                
                // --- Scale Recipe View ---
                Text("Scale Recipe")
                    .font(.headline)
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                VStack {
                    Picker("Scale Factor", selection: $scaleFactor) {
                        Text("1x").tag(1.0)
                        Text("2x").tag(2.0)
                        Text("3x").tag(3.0)
                        Text("Custom").tag(0.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: scaleFactor) { newValue in
                        useCustomScale = (newValue == 0.0)
                    }

                    if useCustomScale {
                        TextField("Enter custom scale", text: $customScaleFactor)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .onChange(of: customScaleFactor) { newValue in
                                scaleFactor = Double(newValue) ?? 1.0
                            }
                            .font(.system(size: 14))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)

                // --- Ingredients Section ---
                HStack {
                    Text("Ingredients")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .foregroundStyle(.accent)


                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recipe.ingredients, id: \.self) { ingredient in
                        HStack {
                            
                            Text("• \(ingredient.name)")
                                .font(.system(size: 14))
                            
                            Spacer()
                            
                            Text("\(ingredient.quantity * Float(scaleFactor), specifier: "%.2f") \(ingredient.unit)")
                                .font(.system(size: 14))

                        }
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accent, lineWidth: 2)
                )
                .padding(.horizontal)

                
                // --- Instructions Section ---
                HStack {
                    Text("Instructions")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .foregroundStyle(.accent)
                .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(recipe.instructions.enumerated()), id: \.element) { index, step in                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(.system(size: 14))
                                .frame(width: 30, alignment: .leading)

                            Text(step)
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true)  // Allow text to wrap
                        }
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accent, lineWidth: 2)
                )
                .padding(.horizontal)
                
                // ----------------------

                
                
                
                // Magic recipe cookey button!
                ZStack {
                    // Background bar with dynamic fill
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isClicked ? Color.clear : Color.accentColor)
                        .frame(width: 250, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )

                    Text("Someone Cooked Here.")
                        .foregroundColor(isClicked ? Color.accentColor : Color.white)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .padding(.top)
                .onTapGesture {
                    guard !isClicked else { return } // Prevent multiple clicks
                    isClicked = true
                    trigger += 1
                    longHaptic(duration: 1.0)
                    // TODO call a remove recipe function here
                }
                .confettiCannon(trigger: $trigger, num: 55, confettis: [ .text("🥕"),.text("🥑"),.text("🥦"),.text("🥬"),.text("🌽"),.text("🌶️"),.text("🧄"),.text("🧅"),.text("🥔"),.text("🧀"),.text("🥚"),.text("🫛"),.text("🥒")], confettiSize: 25, rainHeight: 700, openingAngle: Angle.degrees(60), closingAngle: Angle.degrees(120), radius: 400, repetitions: 1, repetitionInterval: 0.5, hapticFeedback: false)
            }
            .padding()
            .sheet(isPresented: $showEditSheet) {
                RecipeInputView(recipe: recipe) 
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Edit") { showEditSheet = true})
        .sheet(isPresented: $showEditSheet) {
            RecipeInputView(recipe: recipe)
        }
        
        Spacer()
    }
    func removeIngredientsFromPantry() {
        // TODO: @BEN, whatever backend things you like to remove the used ingredients!
        // TODO: - Ben needs to make recipes use ingredients .. which means he needs to get the parser hooked in, which means lots of things *sigh* -ben
        // :'( - Caleb
        /*for ingredient in recipe.ingredients {
            pantry.deduct_ingr(ing: ingredient, quantity: ingredient.quantity, unit: ingredient.unit)
         }*/
    }
    func longHaptic(duration: TimeInterval) {
         guard let engine = hapticEngine else { return }
         
         var events = [CHHapticEvent]()
         let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
         let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
         let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: duration)
         
         events.append(event)

         do {
             let pattern = try CHHapticPattern(events: events, parameters: [])
             let player = try engine.makePlayer(with: pattern)
             try player.start(atTime: CHHapticTimeImmediate)
         } catch {
             print("Haptic pattern failed: \(error.localizedDescription)")
         }
    }
    
    func prepareHaptics() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("Haptic engine started successfully")
        } catch {
            print("Failed to start haptic engine: \(error.localizedDescription)")
        }
    }

    // Function to update the recipe
    private func updateRecipe(with updatedRecipe: Recipe) {
        DispatchQueue.main.async {
            recipe.title = updatedRecipe.title
            recipe.ingredients = updatedRecipe.ingredients
            recipe.instructions = updatedRecipe.instructions
            recipe.prepTime = updatedRecipe.prepTime
            recipe.cookTime = updatedRecipe.cookTime
            recipe.totalTime = updatedRecipe.totalTime
            recipe.servings = updatedRecipe.servings
            recipe.imageUrl = updatedRecipe.imageUrl
        }
    }
    
    private func calculateTotalTime(prepTime: String?, cookTime: String?) -> String {
        let prep = Int(prepTime ?? "") ?? 0
        let cook = Int(cookTime ?? "") ?? 0
        return "\(prep + cook)"
    }

}

struct FullRecipeView_Previews: PreviewProvider {
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
        
        let sampleRecipe = Recipe(
            title: "Spaghetti Carbonara",
            ingredients: [
                Ingredient(unit: "g", quantity: 200, descriptors: [], name: "Spaghetti", origText: "200g Spaghetti"),
                Ingredient(unit: "", quantity: 2, descriptors: [], name: "Eggs", origText: "2 Eggs"),
                Ingredient(unit: "g", quantity: 50, descriptors: [], name: "Parmesan Cheese", origText: "50g Parmesan Cheese"),
                Ingredient(unit: "g", quantity: 100, descriptors: [], name: "Bacon", origText: "100g Bacon")
            ],
            instructions: [
                "Boil pasta until al dente.",
                "Fry bacon until crisp.",
                "Mix eggs and cheese in a bowl.",
                "Combine pasta, bacon, and egg mixture."
            ],
            imageUrl: nil,
            prepTime: "10 min",
            cookTime: "15 min",
            totalTime: "25 min",
            servings: "2"
        )

        FullRecipeView(recipe: sampleRecipe)
            .environmentObject(PantryModel())
            .environmentObject(mockWipList)

    }
}

