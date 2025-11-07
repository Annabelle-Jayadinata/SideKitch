//
//  PantryModel.swift
//  SideKitch
//
//  Created by Ben Ruland on 2/23/25.
//

import Foundation

class PantryModel: Codable , ObservableObject {
   
    @Published private(set) var ingr:[Ingredient] // read-only
    
    private var i_ingr : [String : Ingredient] = [:]
    
    init(ingr: [Ingredient] = []) {
        self.ingr = ingr
    }
    
    func add_ingr(ing : Ingredient, quantity: Float, unit : String){
       // w/o unit converter for now we just ignore unit, hope for best!
        if let strd_ing = i_ingr[ing.name] {
            strd_ing.quantity += quantity
        } else {
            i_ingr[ing.name] = Ingredient(unit: unit, quantity: quantity, name: ing.name)
        }
        regenIngr()
    }
    
    func deduct_ingr(ing : Ingredient, quantity: Float , unit : String){
       // w/o unit converter for now we just ignore unit, hope for best!
        if let strd_ing = i_ingr[ing.name] {
            strd_ing.quantity -= quantity
            if strd_ing.quantity <= 0 {
                i_ingr.removeValue(forKey: strd_ing.name)
            }
        }
        regenIngr()
    }
    
    func regenIngr(){
        ingr = Array(i_ingr.values)
    }
    
    func query(name : String)->Ingredient?{
        return i_ingr[name]
    }

    // ----- Ignore Below here, this is just to make it codable
    enum CodingKeys: CodingKey {
        case ingr
        case i_ingr
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ingr = try container.decode([Ingredient].self, forKey: .ingr)
        i_ingr = try container.decode([String:Ingredient].self, forKey: .i_ingr)

    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ingr , forKey: .ingr)
        try container.encode(i_ingr , forKey: .i_ingr)
    }
}
