//
//  RecipeCardView.swift
//  SideKitch
//
//  Created by Ben Ruland on 2/12/25.
//

import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    var body: some View {
        VStack(alignment: .leading){
            Text(recipe.title)
                .font(.headline)
                .padding(.leading,10)
                .padding(.top,5)
            
            Spacer()
            HStack{
                Label((recipe.totalTime ?? "unknown"), systemImage: "clock")
                    .padding(.leading,20)
                Spacer()
                Label(("\(recipe.ingredients.count)"), systemImage: "carrot")
                Spacer()
                Label("\(recipe.servings ?? "unknown")", systemImage: "person.3")
                    .padding(.trailing, 20)

            }
            .font(.footnote)
            .padding(.bottom,5)
            
        }
    }
}

struct RecipeCardViewPreviews: PreviewProvider{
    static var recipe = Recipe(title: "Ben's Best Recipe")
    static var previews: some View{
        RecipeCardView(recipe: recipe)
            .background(Color.white)
            .previewLayout(.fixed(width:400, height: 60))

    }
}

