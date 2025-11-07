//
//  SideKitchApp.swift
//  SideKitch
//
//  Created by Annabelle Jayadinata on 27/01/25.
//

import SwiftUI

@main
struct SideKitchApp: App {
    @State private var showWelcome = true
    @StateObject private var globData = GlobData()
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showWelcome {
                    WelcomePage()
                        .transition(.opacity) // Smooth fade-out effect
                } else {
                    ContentView(){
                        Task{
                            do{
                                try await globData.saveWIP(wipList: globData.wipList)
                                try await globData.savePantry(pantry: globData.pantry)
                            }catch{
                                fatalError(error.localizedDescription)
                            }
                        }
                        
                    }
                        .transition(.opacity) // Smooth fade-in effect
                        .modelContainer(for: [Recipe.self, GroceryListModel.self])
                        .task{
                            do {
                                try await globData.load()
                            }catch{
                                fatalError(error.localizedDescription)
                            }
                        }
                        .environmentObject(globData.wipList)
                        .environmentObject(globData.pantry)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showWelcome)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        showWelcome = false
                    }
                }
            }
        }
    }
}

struct WelcomePage: View {
    var body: some View {
        VStack {
            ZStack {
                
                Image("WelcomeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
            }
            
            Text("SideKitch")
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontWidth(.condensed)
                .padding(.top)
            
            Text("Become a Dine-amic Duo.")
                .italic()
                .font(.title2)
                .fontWidth(.condensed)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()

    }
}

struct SideKitchApp_Previews: PreviewProvider {
    static var previews: some View {
        WelcomePage()
    }
}
