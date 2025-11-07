//
//  HomeViewMealSelector.swift
//  SideKitch
//
//  Created by Annabelle Jayadinata on 14/02/25.
//

import SwiftUI
import SwiftData

struct HomeViewMealSelector: View {
    let selectedMealType: String?
    let selectedDate: Date?
    var onRecipeSelected: (Recipe) -> Void
    
    @Environment(\.dismiss) var dismiss
    @Query var allRecipes: [Recipe]

    var body: some View {
        NavigationView {
            List(allRecipes) { recipe in
                Button(action: {
                    onRecipeSelected(recipe)
                    dismiss()
                }) {
                    HStack {
                        Text(recipe.title)
                        Spacer()
                        Text(selectedMealType ?? "")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Select Recipe")
        }
    }
}

#Preview {
    HomeViewMealSelector(selectedMealType: "Lunch", selectedDate: Date()) { _ in }
}
