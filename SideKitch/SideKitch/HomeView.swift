//
//  HomeView.swift
//  SideKitch
//
//  Created by Annabelle Jayadinata on 04/02/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var isAddRecipePresented = false
    @State private var navigateToShoppingList = false
    @State private var navigateToRecipeParser = false
    @State private var showRecipeInputSheet = false
    @State private var showGenerateRecipeSheet = false
    @State private var selectedIngredients: Set<String> = []
    @State private var generatedRecipe: Recipe?
    @State private var isLoadingRecipe = false
    @State private var errorMessage: String?
    @State private var newRecipe = Recipe()

    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var pantry: PantryModel
    @Query var allRecipes: [Recipe]

    func saveRecipeToCookbook(_ recipe: Recipe) {
        withAnimation {
            modelContext.insert(recipe)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Top bar
                HStack {
                    Button(action: {}) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    
                    Spacer()

                    // "Add Recipe" button with dropdown menu
                    Menu {
                        Button(action: {
                            newRecipe = Recipe()
                            showRecipeInputSheet = true
                        }) {
                            Label("Input Recipe", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            navigateToRecipeParser = true
                        }) {
                            Label("Recipe from Link", systemImage: "link")
                        }
                        
                        Button(action: {
                            showGenerateRecipeSheet = true
                        }) {
                            Label("Generate Recipe", systemImage: "wand.and.stars")
                        }
                    } label: {
                        HStack {
                            Text("Add Recipe")
                            Image(systemName: "plus.circle")
                        }
                    }
                }
                .padding()

                Text("Cookbook")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // Display saved recipes
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(allRecipes) { recipe in
                            NavigationLink(destination: FullRecipeView(recipe: recipe)) {
                                RecipeCardView(recipe: recipe)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            .background(
                NavigationLink(
                    destination: RecipeParserView(),
                    isActive: $navigateToRecipeParser
                ) { EmptyView() }
            )
            .sheet(isPresented: $showRecipeInputSheet) {
                RecipeInputView(recipe: newRecipe)
            }

            .sheet(isPresented: $showGenerateRecipeSheet, onDismiss: {
                if let recipe = generatedRecipe {
                    saveRecipeToCookbook(recipe)
                }
            }) {
                GenerateRecipeView(
                    selectedIngredients: $selectedIngredients,
                    generatedRecipe: $generatedRecipe,
                    isLoadingRecipe: $isLoadingRecipe,
                    errorMessage: $errorMessage
                )
            }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

