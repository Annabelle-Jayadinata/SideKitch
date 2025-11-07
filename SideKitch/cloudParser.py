

import functions_framework
import spacy
import json

from spacy.matcher import Matcher
from recipe_scrapers import scrape_html
import requests
from bs4 import BeautifulSoup
from urllib.request import urlopen
import re
import unicodedata2

#os.system("python -m spacy download en_core_web_sm")

# Load spaCy's English NLP model
import en_core_web_sm
nlp = en_core_web_sm.load()

matcher = Matcher(nlp.vocab)
# Define common units and measurement words
units = ["cup", "cups", "teaspoon", "teaspoons", "tbsp", "tablespoon", "tablespoons",
         "oz", "ounce", "ounces", "gram", "grams", "kg", "kilogram", "kilograms", "lb", "lbs", "pound", "pounds",
         "can", "cans", "pinch", "dash", "clove", "cloves", "slice", "slices", "to taste"]

# Pattern to match quantity + unit
quantity_unit_pattern = [
    [{"LIKE_NUM": True}, {"LOWER": {"IN": units}}],
    [{"LOWER": {"IN": ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]}}, {"LOWER": {"IN": units}}],
    [{"LIKE_NUM": True}, {"LOWER": "or"}, {"LOWER": "to"}, {"LOWER": "taste"}]
]

matcher.add("QUANTITY_UNIT", quantity_unit_pattern)



def parse_ingredient(ingredient):
    """Extracts quantity, unit, and item from an ingredient string."""
    quantity, unit, item = None, None, ingredient.strip()
    
    # Step 1: Extract leading quantity (whole, fraction, or mixed fraction)
    quantity_match = re.match(r"^(\d+\s\d+/\d+|\d+/\d+|\d+\s½|\d+|½|⅓|⅔|¼|¾)", ingredient)
    uni_fracs = {u'½' : .5,u'⅓' : .33 ,u'⅔' : .66 ,u'¼' : .25,u'¾' : .75}

    if quantity_match:
        tmp_quantity = quantity_match.group(1).strip()
        quantity = 0
        for item in tmp_quantity:
            print(item)
            try :
                quantity += unicodedata2.numeric(item)
            except:
                print(f"error [{quantity}] is not unicode")

        remaining_text = ingredient[len(quantity_match.group(0)):].strip()
    else:
        remaining_text = ingredient
    
    # Step 2: Extract unit if present
    words = remaining_text.split()
    if words and words[0] in units:
        unit = words.pop(0)
    
    item = " ".join(words).strip()
    
    return {"quantity": f"{quantity}", "unit": f"{unit}", "item": f"{item}"}

def parse_ingredients_list(ingredients):
    """Parse a list of ingredient strings into structured data."""
    return [parse_ingredient(ing) for ing in ingredients]

def scrape_recipe(url):
    """Attempt to scrape a recipe from a given URL."""
    try:
        html = urlopen(url).read().decode("utf-8")
        scraper = scrape_html(html, org_url=url)

        return {
            "title": f"{scraper.title()}",
            "total_time": f"{scraper.total_time()}",
            "prep_time": f"{scraper.prep_time()}",  # Extract prep time
            "cook_time": f"{scraper.cook_time()}",  # Extract cook time
            "ingredients": scraper.ingredients(),
            "instructions": scraper.instructions()
        }
    except Exception as e:
        print(f"recipe-scrapers error: {e}. Attempting manual scraping...")
        return scrape_recipe_fallback(url)

def scrape_recipe_fallback(url):
    """Fallback method to scrape recipe data using BeautifulSoup."""
    headers = {"User-Agent": "Mozilla/5.0"}  # Prevent blocking
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, "html.parser")

    title = soup.find("h1").text.strip() if soup.find("h1") else "Unknown Title"
    ingredients = [i.text.strip() for i in soup.find_all(class_="ingredient")]
    instructions = [i.text.strip() for i in soup.find_all(class_="instruction")]

    return {
        "title": title,
        "prep_time": None,
        "cook_time": None,
        "total_time": None,
        "ingredients": ingredients,
        "instructions": instructions
    }

def parse(url):
    url = url # input("Enter a recipe URL: ")
    recipe_data = scrape_recipe(url)
    
    print(f"\nRecipe Title: {recipe_data['title']}")
    print(f"Prep Time: {recipe_data['prep_time']} minutes")
    print(f"Cook Time: {recipe_data['cook_time']} minutes")
    print(f"Total Time: {recipe_data['total_time']} minutes")

    print("\nIngredients:")
    structured_ingredients = parse_ingredients_list(recipe_data["ingredients"])
    
    for ing in structured_ingredients:
        print(f" - Quantity: {ing['quantity']} Unit: {ing['unit']}, Item: {ing['item']}")
 
    print("\nInstructions:")
    instructions = recipe_data["instructions"]
    
    recipe_data["ingredients"] = structured_ingredients
    
    if isinstance(instructions, str):
        instructions = [instructions]
    for step in instructions:
        print(f" - {step}")
        
    return recipe_data


def hello_http(request):
    """HTTP Cloud Function.
    Args:
        request (flask.Request): The request object.
        <https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data>
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
        <https://flask.palletsprojects.com/en/1.1.x/api/#flask.make_response>.
    """
    request_json = request.get_json(silent=True)
    request_args = request.args

    if request_json is None:
        print("NOT recieving json from post req")
        return 404
    
    url = request_json['url']
    recipe_data = parse(url)

   # recipe_D = []
    #{"ingredients": recipe_data["ingredients"], "instructions" : "Hello World"}
    return json.dumps(recipe_data)



