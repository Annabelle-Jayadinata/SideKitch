//
//  globalData.swift
//  SideKitch
//
//  Created by Ben Ruland on 2/22/25.
//

import SwiftUI

@MainActor
class GlobData: ObservableObject {
    @Published var wipList : WIPGroceryListModel = WIPGroceryListModel()
    @Published var pantry : PantryModel = PantryModel()
    
    private var files = ["wipList.json", "pantry.json"]
   // "wipList.json"
    private static func fileURL(modelName : String) throws -> URL{
        try FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: true)
                .appendingPathComponent(modelName)

    }
    
    func load() async throws {
        let wipTask = Task<WIPGroceryListModel, Error> {
            let fileURL = try Self.fileURL(modelName:"wipList.json")
               guard let data = try? Data(contentsOf: fileURL) else {
                   print("failed the load")
                   return WIPGroceryListModel()
               }
            let wipGrocList = try JSONDecoder().decode(WIPGroceryListModel.self, from: data)
            return wipGrocList
           }
        let wipList = try await wipTask.value
        self.wipList = wipList
        
        
        let pantryTask = Task<PantryModel, Error> {
            let fileURL = try Self.fileURL(modelName:"pantry.json")
               guard let data = try? Data(contentsOf: fileURL) else {
                   print("failed the load")
                   return PantryModel()
               }
            let pantry = try JSONDecoder().decode(PantryModel.self, from: data)
            return pantry
           }
        let pantry = try await pantryTask.value
        self.pantry = pantry

        
       }
    
    
    
    
    func saveWIP(wipList: WIPGroceryListModel) async throws {
        let task = Task {
            let data = try JSONEncoder().encode( wipList)
            let outfile = try Self.fileURL(modelName:"wipList.json")
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
    
    func savePantry(pantry : PantryModel) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(pantry)
            let outfile = try Self.fileURL(modelName: "pantry.json")
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}
