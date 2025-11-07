//
//  WIPGroceryListModel.swift
//  SideKitch
//
//  Created by Ben Ruland on 2/21/25.
//

import Foundation

class WIPGroceryListModel: Codable , ObservableObject {
    var recipes: [String : Int]
    var creation_date: Date
    @Published private(set) var have: [Ingredient]
    @Published private(set) var dont_have: [Ingredient]
    
    
    private var i_have: [String:Ingredient] = [:]
    private var i_dont_have: [String:Ingredient] = [:]
    
    enum CodingKeys: CodingKey {
        case recipes
        case have
        case dont_have
        case i_have
        case i_dont_have
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recipes = try container.decode([String:Int].self, forKey: .recipes)
        creation_date = Date()
        have = try container.decode([Ingredient].self, forKey: .have)
        dont_have = try container.decode([Ingredient].self, forKey: .dont_have)
        i_have = try container.decode([String:Ingredient].self, forKey: .i_have)
        i_dont_have = try container.decode([String:Ingredient].self, forKey: .i_dont_have)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recipes, forKey: .recipes)
        try container.encode(have, forKey: .have)
        try container.encode(dont_have, forKey: .dont_have)
        try container.encode(i_have, forKey: .i_have)
        try container.encode(i_dont_have, forKey: .i_dont_have)
    }
    
    init(have: [Ingredient] = [], dont_have: [Ingredient] = [] ) {
        self.recipes = [:]
        self.creation_date = Date()
        self.have = have
        self.dont_have = dont_have
    }
    
    private func regen_have(){
        have = Array(i_have.values)
    }
    
    
    private func regen_dont_have(){
        dont_have = Array(i_dont_have.values)
    }
    
    private func regen_from_recipes(){
       //TODO need to make it a dict of recipes sigh
    }

    static func add_recipe(grocList:WIPGroceryListModel, recipe:Recipe, pantry:PantryModel){
        for ingr in recipe.ingredients{
            if let p_ingr = pantry.query(name: ingr.name) {
                var preExist:Float = 0
                if let e_ingr = grocList.i_have[ingr.name] {
                    // TODO NOTE WE NEED A UNIT CONVERTER HERE TO DO THIS RIGHT!!!
                    preExist = e_ingr.quantity
                }
                var total = preExist + ingr.quantity
                if (total > p_ingr.quantity){
                    print("putting \(ingr.name)into dont have 1st")
                    grocList.add_item_to_dont_have(ingredient: Ingredient(unit: ingr.unit, quantity: total - p_ingr.quantity , name: ingr.name))
                } else {
                    print("putting \(ingr.name)into have 1st")
                    grocList.add_item_to_have(ingredient: Ingredient(unit: ingr.unit, quantity: total, name: ingr.name))
                }
                
            } else {
                var preExist:Float = 0
                if let e_ingr = grocList.i_dont_have[ingr.name]{
                    preExist = e_ingr.quantity
                }
                print("putting \(ingr.name)into dont have 2nd")
                grocList.add_item_to_dont_have(ingredient: Ingredient(unit: ingr.unit, quantity: preExist + ingr.quantity, name: ingr.name))
            }
        }
        var sum:Int = 1
        if let existing = grocList.recipes[recipe.title]{
            sum += existing
        }
        grocList.recipes[recipe.title] = sum
        
    }
    func remove_item_from_have(ingredient: Ingredient) {
        have.removeAll { $0.id == ingredient.id }
    }
    
    func remove_item_from_dont_have(ingredient: Ingredient) {
        dont_have.removeAll { $0.id == ingredient.id }
    }
    
    func add_item_to_have(ingredient: Ingredient) {
        i_have[ingredient.name] = ingredient
        regen_have()
    }
    
    func add_item_to_dont_have(ingredient: Ingredient) {
        i_dont_have[ingredient.name] = ingredient
        regen_dont_have()
    }
    
    func remove_recipe(recipe:Recipe, num: Int = 1){
        // go check the recipes for this recipe by UUID, if its in there, sub the recipes by 1
        // if the entry is now 0 remove it from the dict
        
        // for each ingredient, run through and if its in have or dont_have subtract the quantity by the current amount,
        // do the calc then, if the cur amount is >= quantity in pantry. and do some casing to determine if we need to move it to the other side.
        // if quantity is 0 remove it altogether.
    }
    
    func display_recipes() -> [String : Int] {
        return self.recipes
    }
    
    func finalize(list_name: String) -> GroceryListModel {
        
        let final = GroceryListModel(name: list_name, recipes: self.recipes, ingredients: Array(self.i_dont_have.values))
        
        self.have = []
        self.recipes = [:]
        self.dont_have = []

        self.i_dont_have = [:]
        self.i_have = [:]
        return final
    }
}
