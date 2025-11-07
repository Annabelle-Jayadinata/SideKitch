//
//  AllGroceryLists.swift
//  SideKitch
//
//  Created by Febie Lin on 2/23/25.
//

import SwiftUI
import SwiftData


struct AllGroceryLists: View {
    @EnvironmentObject var wipList:WIPGroceryListModel
    @Query var finalized_lists: [GroceryListModel]
    
    var body: some View {
        NavigationView {
            VStack {
                // top bar
                HStack {
                    Text("Grocery Lists")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding()
                
                Spacer()
                
                List {
                    Section(header: Text("In Progress").font(.headline).foregroundStyle(.tint)) {
                        if wipList.dont_have.isEmpty && wipList.have.isEmpty {
                            NavigationLink(destination: WIPGroceryList()) {
                                    Text("No list currently in progress.\nClick here to start a new grocery list!")
                                    .foregroundStyle(.secondary)
                                }
                        } else {
                            NavigationLink(destination: WIPGroceryList()) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text("List from")
                                            Text(
                                                DateFormatter.localizedString(from: wipList.creation_date, dateStyle: .short, timeStyle: .short)
                                            )
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.bottom)
                                        
                                        
                                        HStack {
                                            Text("Purchase: ")
                                                .fontWeight(.bold)
                                            Text(wipList.dont_have.map { $0.name }.joined(separator: ", "))
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        
                                        HStack {
                                            Text("Owned: ")
                                                .fontWeight(.bold)
                                            Text(wipList.have.map { $0.name }.joined(separator: ", "))
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Published").font(.headline).foregroundStyle(.tint)) {
                        if finalized_lists.isEmpty {
                            Text("No lists currently published.")
                                .foregroundStyle(.secondary)

                        } else {
                            ForEach(finalized_lists, id: \.self) { finalizedList in
                                NavigationLink(destination: FinalGroceryView(groceryList: finalizedList)) {
                                    VStack (alignment: .leading) {
                                        HStack {
                                            Text(finalizedList.name)
                                                .fontWeight(.bold)
                                            Text(
                                                DateFormatter.localizedString(from: finalizedList.creation_date, dateStyle: .short, timeStyle: .short)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()
            }

        }
        .navigationBarTitle("Finalized Lists", displayMode: .inline)
    }
}


struct AllGroceryLists_Previews: PreviewProvider {
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
        
        AllGroceryLists()
            .environmentObject(mockWipList)
    }
}

