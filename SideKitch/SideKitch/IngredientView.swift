//
//  IngredientView.swift
//  SideKitch
//
//  Created by Ben Ruland on 2/23/25.
//
import SwiftUI

struct IngredientView: View {
    let ingredient: Ingredient
    @State var displayUnit:String
    
    let units = ["lb", "oz", "tbsp", "ct"]
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Text("\(ingredient.name)")
                    .frame(width: geometry.size.width * 0.45, alignment: .leading)
                    .font(.system(size: geometry.size.width * 0.05))
                
                    
                // TODO add a method here for updating quantity, binding required by TextField doesnt quite work out bc we dont have a mutable object
                Text("\(ingredient.quantity, specifier: "%.2f")")
                    .font(.system(size: geometry.size.width * 0.05))
                    .frame(width: geometry.size.width * 0.2, alignment: .trailing)
                
                Spacer()
                
                Menu {
                    ForEach(units, id: \.self) { unit in
                        Button(unit) {
                            displayUnit = unit
                            // TODO call a unit conversion library here
                        }
                    }
                } label: {
                    HStack {
                        Text(displayUnit)
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
}
