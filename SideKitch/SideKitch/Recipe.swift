//
//  RecipeParser.swift
//  SideKitch
//
//  Created by Annabelle Jayadinata on 29/01/25.
//
import Foundation
import SwiftSoup
import SwiftData

struct IngredientParse: Codable{
    var quantity:String
    var unit:String
    var item:String
}

struct RecipeParse: Codable {
    var ingredients:[IngredientParse]
    var instructions:String
    var total_time: String
    var prep_time: String
    var cook_time: String
    var title:String
    var servings: String?
}

class Ingredient: Identifiable , Hashable, Codable, ObservableObject {
    var id = UUID()
    var unit: String
    var quantity: Float
    var descriptors: [String]
    var name: String
    var origText: String
    
    static func qString(q : Float)-> String{
        let nf = NumberFormatter()
        nf.roundingMode = .down
        nf.maximumFractionDigits = 2
        return nf.string(for:q)!
    }
    
    init(unit: String, quantity: Float, descriptors: [String] = [], name: String, origText: String = "") {
        self.unit = unit
        self.quantity = quantity
        self.descriptors = descriptors
        self.name = name
        self.origText = origText
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
        }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    
    // probably some conversions are necessary
    func update_item(newName: String? = nil, newQuantity: Float? = nil, newUnit: String? = nil) {
        if let name = newName {
            self.name = name
        }
        
        if let quantity = newQuantity {
            self.quantity = quantity
        }
        
        if let unit = newUnit {
            self.unit = unit
        }
    }
}

//TODO - have an empty recipe - static initializer function
@Model class Recipe: ObservableObject, Codable {
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]
    var imageUrl: String?
    var prepTime: String?
    var cookTime: String?
    var totalTime: String?
    var servings: String?

    init(title: String = "", ingredients: [Ingredient] = [], instructions: [String] = [], imageUrl: String? = nil, prepTime: String? = nil, cookTime: String? = nil, totalTime: String? = nil, servings: String? = nil) {
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.imageUrl = imageUrl
        self.prepTime = prepTime
        self.cookTime = cookTime
        let t_prep = Int(prepTime ?? "") ?? 0
        let t_cook = Int(cookTime ?? "") ?? 0
        self.totalTime = String(t_prep + t_cook)
        self.servings = servings
    }
    
    init(parsed:RecipeParse){
        title = parsed.title
        cookTime = parsed.cook_time
        prepTime = parsed.prep_time
        totalTime = parsed.total_time
        var ingTemp:[Ingredient] = []
        for ing in parsed.ingredients{
            ingTemp.append(Ingredient(unit: ing.unit, quantity: Float(ing.quantity) ?? 0 , name : ing.item))
        }
        ingredients = ingTemp
        
        instructions = parsed.instructions.split(whereSeparator: \.isNewline).map {String($0)}
        
    }
    
    enum CodingKeys: String, CodingKey {
        case title, ingredients, instructions, imageUrl, prepTime, cookTime, totalTime, servings
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        self.instructions = try container.decode([String].self, forKey: .instructions)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.prepTime = try container.decodeIfPresent(String.self, forKey: .prepTime)
        self.cookTime = try container.decodeIfPresent(String.self, forKey: .cookTime)
        self.totalTime = try container.decodeIfPresent(String.self, forKey: .totalTime)
        self.servings = try container.decodeIfPresent(String.self, forKey: .servings)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(instructions, forKey: .instructions)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(prepTime, forKey: .prepTime)
        try container.encodeIfPresent(cookTime, forKey: .cookTime)
        try container.encodeIfPresent(totalTime, forKey: .totalTime)
        try container.encodeIfPresent(servings, forKey: .servings)
    }
    //var myRecipe:Recipe = Recipe()
   
    // TODO - un hard code
    // Probably best bet is to work over the text itself and not so much the divs, though divs might provide a shortcut
    // I.E can try searching for a div title that says recipe or ingredients and that can shortcut us there
    
    // otherwise we should probably do something like look for the greatest concentration of numbers and measure words to find the recipe location,
    // then try to find numbers or bullet points for instructions - instructions might be pretty hard tho TBD
    
    // TODO TODO
    // need to break out another parser to parse recipe ingredients, this one is going to be interesting.
    
    // TODO - set this up as a swift data thing and potentially pull the recipe type into the class?
     func htmlParse(htmlString: String){
        /*do {
            
            let document: Document = try SwiftSoup.parse(htmlString)
            // Title
            let titleElement = try document.select("h1.article-heading.text-headline-400").first()
            let title = try titleElement?.text() ?? "No Title"

            // Ingredients
            let liElements = try document.select("li.mm-recipes-structured-ingredients__list-item")
            var seen = Set<String>()
            var ingredients = [String]()
            
            for li in liElements {
                let fullLine = try li.text()
                if !seen.contains(fullLine) {
                    seen.insert(fullLine)
                    ingredients.append(fullLine)
                }
            }
            
            // TODO need further filtering of instructions- currently picking up photo captions

            // Instructions
            let instructionEls = try document.select("div.mm-recipes-steps__content ol li p")
            var instructions = [String]()
            for p in instructionEls {
                instructions.append(try p.text())
            }
            
            // Filter out unwanted lines
            //- dotdash seems to be whats coming up for photo captions on allrecipes - ben
            instructions = instructions.filter { step in
                !step.localizedCaseInsensitiveContains("allrecipes video") && !step.isEmpty && !step.localizedCaseInsensitiveContains("dotdash")
            }
            
            // Image URL
            // "class*=" means "class attribute contains this substring"
            let imageElement = try document.select("img[class*='primary-image__image']").first()
            let imageUrl = try imageElement?.attr("src")
            print("Extracted image URL:", imageUrl ?? "nil")

            let detailElements = try document.select("div.mm-recipes-details__item")
                
            // Temporary variables to hold each detail
            var prepTime: String?
            var cookTime: String?
            var totalTime: String?
            var servings: String?
            
            // Loop through each .mm-recipes-details__it
            for detail in detailElements {
                // Grab the label & value text
                let labelText = (try? detail.select("div.mm-recipes-details__label").text()) ?? ""
                let valueText = (try? detail.select("div.mm-recipes-details__value").text()) ?? ""

                // Based on the label, assign to the correct variable
                switch labelText {
                case "Prep Time:":
                    prepTime = valueText
                case "Cook Time:":
                    cookTime = valueText
                case "Total Time:":
                    totalTime = valueText
                case "Servings:":
                    servings = valueText
                // or sometimes Allrecipes has "Yield:" or "Makes:" for servings
                // case "Yield:", "Makes:":
                //    servings = valueText
                default:
                    break
                }
            }

            // TODO clean this up, got lazy about the object stuff
            // Create a Recipe object
            self.title = title
            self.ingredients = ingredients
            self.instructions = instructions
            self.imageUrl = imageUrl
            self.prepTime = prepTime
            self.cookTime = cookTime
            self.totalTime = totalTime
            self.servings = servings
            
            print("set recipes")
        } catch {
            print("Error parsing HTML: \(error)")
        }*/
    }
    
    // wrapper to fetch recipe, tried to decompose a bit more, still needing to pass the UI update closure but
    // I think we can remove that if we fully make this a class and bind the recipe as UI state, so that way it auto updates
    func getRecipeFromURL(urlString: String){
        // so we call fetch recipe and pass it a function that parses the url string it gives us, along with a UI completion for the parser to call when done
        fetchURL(urlString: urlString, parser: htmlParse)
        return
    }
    
    func fetchURL(urlString: String, parser: @escaping (String)->Void){
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        //var recipe: Recipe = Recipe()
        let group = DispatchGroup()
        
        // entering a dispatch group and calling the completion once the url sesh is done
        var htmlString = ""
        group.enter()
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer {group.leave()} // this should act as completion handler, always gets called at the end
            
            guard let data = data,
                  let potHTML = String(data: data, encoding: .utf8) else {
                print("No data or failed to decode data to String.")
                // TODO mark error in error state
                return
            }
            htmlString = potHTML
        }.resume()
        group.notify(queue: .main) {
            parser(htmlString)
            return
        }
    }
}

