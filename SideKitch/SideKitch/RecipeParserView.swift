//
//  RecipeParserView.swift
//  SideKitch
//
//  Created by Febie Lin on 2/5/25.
//

import SwiftUI
import SwiftData

struct RecipeParserView: View {
    
    @State private var urlString: String = ""
   // @State private var recipe: Recipe? = nil
    @FocusState private var urlFocus: Bool
    @State private var curRecipe:Recipe? = nil
    @Environment(\.modelContext) private var context
    @State private var buttonPressed = false
    
    func parse(){
        // using the swift 4+ answer from here https://stackoverflow.com/questions/26364914/http-request-in-swift-with-post-method
        
        let parameters: [String:Any] = ["url":urlString]
        let url = URL(string: "https://parser2-92538018155.us-central1.run.app")!
        let session = URLSession.shared
        
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        do {
            // convert parameters to Data and assign dictionary to httpBody of request
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
          } catch let error {
            print(error.localizedDescription)
            return
          }
          
          // create dataTask using the session object to send data to the server
          let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
              print("Post Request Error: \(error.localizedDescription)")
              return
            }
            
            // ensure there is valid response code returned from this HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
              print("Invalid Response received from the server")
              return
            }
            
            // ensure there is data returned
            guard let responseData = data else {
              print("nil Data received from the server")
              return
            }
            
            do {
              // create json object from data or use JSONDecoder to convert to Model stuct
                let decoder = JSONDecoder()
                let jsonResponse = try decoder.decode(RecipeParse.self, from:responseData)
                if (jsonResponse != nil){ // TODO make this actually a check on the attempt to init the recipe and the decoder
                    var newRecipe = Recipe(parsed:jsonResponse)
                    curRecipe = newRecipe
                    context.insert(newRecipe)
                    do {
                        try context.save()
                        buttonPressed = false
                    } catch {
                        print("couldn't save the new recipe")
                    }
                // handle json response
              } else {
                print("data maybe corrupted or in wrong format")
                throw URLError(.badServerResponse)
              }
            } catch let error {
              print(error.localizedDescription)
            }
          }
          // perform the task
          task.resume()
    }

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // --- URL Input Field ---
                    TextField("anyrecipe.com", text: $urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .focused($urlFocus)
                    
                    // --- Fetch Button ---
                    Button(action: {
                        if !buttonPressed{
                            buttonPressed = true
                            parse()
                        }else{
                            print("button already pressed!")
                        }
                    }) {
                        Text("Get My Recipe")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .disabled(urlString.isEmpty)  // Disable if field is empty
                    // --- Show the Recipe if Fetched ---
                    if let curRecipe{
                        
                        // --- Title Section ---
                        Text(curRecipe.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 8)
                        
                        // --- Image Section (if available) ---
                        if let urlString = curRecipe.imageUrl,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                        }
                        
                        // --- RECIPE DETAILS SECTION ---
                        // (Prep Time, Cook Time, Total Time, Servings)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Recipe Details")
                                    .font(.headline)
                                
                                Spacer()
                            }
                            
                            // Show each detail only if it exists and is non-empty
                            if let prep = curRecipe.prepTime, !prep.isEmpty {
                                Text("Prep Time: \(prep)")
                            }
                            if let cook = curRecipe.cookTime, !cook.isEmpty {
                                Text("Cook Time: \(cook)")
                            }
                            if let total = curRecipe.totalTime, !total.isEmpty {
                                Text("Total Time: \(total)")
                            }
                            if let serves = curRecipe.servings, !serves.isEmpty {
                                Text("Servings: \(serves)")
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        // --- Ingredients Section ---
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Ingredients")
                                    .font(.headline)
                                
                                Spacer()
                            }
                            
                            ForEach(curRecipe.ingredients, id: \.self) { ingredient in
                                HStack{
                                    Text("• \(ingredient.name)")
                                        .font(.system(size: 14))
                                    Spacer()
                                    Text("\(ingredient.quantity , specifier: "%.2f")  \(ingredient.unit)")
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        // --- Instructions Section ---
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Instructions")
                                    .font(.headline)
                                
                                Spacer()
                            }
                            
                            ForEach(curRecipe.instructions, id: \.self) { step in
                                Text("• \(step)")
                                    .font(.system(size: 14))
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                    } else if curRecipe == nil {
                        Text("Paste a link to any recipe!")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("")  // Remove the default title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Recipe from Website")
                        .font(.system(size: 30, weight: .bold))
                }
            }
        }
    }
}

#Preview {
    RecipeParserView()
}
