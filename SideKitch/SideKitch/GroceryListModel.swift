//
//  GroceryListModel.swift
//  SideKitch
//
//  Created by Febie Lin on 2/23/25.
//

import Foundation
import SwiftData

@Model class GroceryListModel {
    var recipes: [String: Int]
    var creation_date: Date
    var name: String
    var ingredients_missing: [Ingredient]
    var ingredients_acquired: [Ingredient]

    init(name: String, recipes: [String:Int] = [:], ingredients: [Ingredient] ) {
        self.name = name
        self.recipes = recipes
        self.creation_date = Date()
        self.ingredients_missing = ingredients
        self.ingredients_acquired = []
    }
}
