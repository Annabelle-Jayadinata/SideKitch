//
//  IngredientPantryView.swift
//  SideKitch
//
//  Created by Caleb Matthews on 2/21/25.
//

import SwiftUI

struct IngredientPantryView: View {
    let ingredient: Ingredient
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                // Ingredient name with bold text
                Text(ingredient.name)
                    .font(.headline)
                    .bold() // Bold the name
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity, alignment: .leading) // Left justify
                
                // Spacer between name and details
                Spacer()
                
                // Ingredient details (quantity)
                HStack {
//                    Label(String(ingredient.quantity) + " " + ingredient.unit, systemImage: "refrigerator.fill")
//                        .font(.footnote)
//                        .foregroundColor(.secondary)
                    Image(systemName: "number.circle.fill")
                    Text("Qty: " + String(ingredient.quantity) + " " + ingredient.unit)
                        .font(.footnote)
                }
                .padding(.bottom, 5)
                .foregroundColor(.secondary)

            }
            .padding()
            .cornerRadius(10) // number.circle.fill corners for the card
        }
        .frame(maxWidth: .infinity) // Ensure the card stretches across available space
    }
}

 struct IngredientPantryViewPreview: PreviewProvider{
     static var ingredient = Ingredient(unit: "Eggs", quantity: 1, descriptors: ["Round", "Pale"], name: "Egg.", origText: "1 dozen eggs")
    static var previews: some View{
        IngredientPantryView(ingredient: ingredient)
            .background(Color.white)
            .previewLayout(.fixed(width:400, height: 100))
    }
}

