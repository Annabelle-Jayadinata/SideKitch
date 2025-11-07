# Anna Mattinger
# Done: get prep/cook time, not just total time
# Done: put "or to taste" in Quantity, not Item
# Done: refine Quantity parsing
# Done: separated OG Quantity field into Quantity and Unit
# Done: dealing with plural/singular/abbreviated unit names
# Done: convert fractions to floats and back for display
# Done: resolve 2 cans 16 oz so both are in Quantity? Or convert to 32 oz?
# Done: retain relevant paranthetical info
# Done: related to above, need a field for chill time/rest time!!! (French Silk Pie Bars)
# Done: [for now] instructions formatting
# Done: BACKUP PARSER FOR NON-RECIPE-SCRAPERS SITES WORKS YAAAAAAY
# Done: [store all times as minutes] convert minutes to hours/days as needed for display
# Done: add a field for recipe source (e.g., "Food Network", "AllRecipes")
# TODO: find a way to account for instructions like "refrigerate overnight" that aren't
    # listed as a chill/rest time to optimize meal-planning

import spacy
from spacy.matcher import Matcher
from recipe_scrapers import scrape_html
import requests
from bs4 import BeautifulSoup
from urllib.request import urlopen
import re
from fractions import Fraction

# Load spaCy's English NLP model
nlp = spacy.load("en_core_web_sm")
matcher = Matcher(nlp.vocab)

############################
# Ingredient Utilities
############################

# NOTE: Add to any collections as needed [as more cases discovered]

units = [
    "cup", "cups", "teaspoon", "teaspoons", "tbsp", "tablespoon", "tablespoons",
    "oz", "ounce", "ounces", "gram", "grams", "kg", "kilogram", "kilograms",
    "lb", "lbs", "pound", "pounds", "can", "cans", "pinch", "dash", "clove", "cloves",
    "slice", "slices", "to taste", "jar", "jars", "package", "packages"
]

# Pattern to match quantity + unit (if/when using spaCy)
quantity_unit_pattern = [
    [{"LIKE_NUM": True}, {"LOWER": {"IN": units}}],
    [{"LOWER": {"IN": ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]}}, {"LOWER": {"IN": units}}],
    [{"LIKE_NUM": True}, {"LOWER": "or"}, {"LOWER": "to"}, {"LOWER": "taste"}]
]
matcher.add("QUANTITY_UNIT", quantity_unit_pattern)

# Standardize synonymous expressions of units
UNIT_SYNONYMS = {
    "lb":    ["lb", "lbs", "pound", "pounds"],
    "oz":    ["oz", "ounce", "ounces"],
    "cup":   ["cup", "cups"],
    "tsp":   ["teaspoon", "teaspoons"],
    "tbsp":  ["tablespoon", "tablespoons", "tbsp"],
    "can":   ["can", "cans"],
    "jar":   ["jar", "jars"],
    "gram":  ["gram", "grams"],
    "kg":    ["kilogram", "kilograms", "kg"],
    "package": ["package", "packages"]
}

def canonical_unit(u: str):
    u_lower = u.lower().strip()
    for canon, synonyms in UNIT_SYNONYMS.items():
        if u_lower in synonyms:
            return canon
    return None

NUMBER_WORDS = {
    "one": "1",
    "two": "2",
    "three": "3",
    "four": "4",
    "five": "5",
    "six": "6",
    "seven": "7",
    "eight": "8",
    "nine": "9",
    "ten": "10",
    "eleven": "11",
    "twelve": "12",
}

# Parse fractions in ingredient strings to store as floats
def fraction_to_float(qty_str: str) -> float:
    """
    Convert a string like "1/2", "2 1/2", "½", or a plain integer "2" into a float via Fraction.
    """
    unicode_map = {
        "½": "1/2",
        "⅓": "1/3",
        "⅔": "2/3",
        "¼": "1/4",
        "¾": "3/4"
    }
    for uf, replacement in unicode_map.items():
        qty_str = qty_str.replace(uf, replacement)

    # If it's something like "2 1/2" -> match as a "mixed fraction"
    mf_match = re.match(r"^(\d+)\s+(\d+/\d+)$", qty_str)
    if mf_match:
        w = Fraction(int(mf_match.group(1)), 1)
        f = Fraction(mf_match.group(2))
        return float(w + f)

    try:
        return float(Fraction(qty_str))
    except ValueError:
        return 0.0

# Store quantities as floats, but display as fraction
def float_to_pretty_fraction(value: float) -> str:
    frac = Fraction(value).limit_denominator(8)
    whole = frac.numerator // frac.denominator
    remainder = frac.numerator % frac.denominator
    if remainder == 0:
        return str(whole)
    elif whole == 0:
        return f"{frac.numerator}/{frac.denominator}"
    else:
        return f"{whole} {remainder}/{frac.denominator}"

###########################################
# Ingredient Parsing (uses the above functions/collections)
###########################################

def parse_ingredient(ingredient):
    """Extracts quantity (float), unit (canonical), and item from an ingredient string."""
    original = ingredient.strip()
    quantity, unit, item = None, "count", original

    # 1) Replace spelled-out if at start
    tokens = original.split()
    if tokens:
        first_word = tokens[0].lower()
        if first_word in NUMBER_WORDS:
            tokens[0] = NUMBER_WORDS[first_word]
    ingredient = " ".join(tokens)

    # 2) Merge "2-1/2" -> "2 1/2"
    ingredient = re.sub(r'(\d+)\s*-\s*(\d+/\d+)', r'\1 \2', ingredient)

    # 3) Leading quantity
    quantity_match = re.match(r"^(\d+\s\d+/\d+|\d+/\d+|\d+\s½|\d+|½|⅓|⅔|¼|¾)", ingredient)
    if quantity_match:
        qty_str = quantity_match.group(1).strip()
        quantity = fraction_to_float(qty_str)
        remainder = ingredient[len(quantity_match.group(0)):].strip()
    else:
        remainder = ingredient

    # 4) If next word is a recognized unit
    words = remainder.split()
    if words:
        possible_unit = canonical_unit(words[0])
        if possible_unit:
            unit = possible_unit
            words.pop(0)
    item = " ".join(words).strip()

    # (Optional) further logic: parentheticals, multiple references, etc.

    return {
        "quantity": quantity,
        "unit": unit,
        "item": item
    }

def parse_ingredients_list(ingredients):
    """Parse a list of ingredient strings into structured data."""
    return [parse_ingredient(ing) for ing in ingredients]

###########################################
# Time-handling Functions (and Recipe Source field)
###########################################

# NOTE: one single field captures "chill time", "rest time", "freeze time";
# instructions context will tell user whether to rest in fridge, freezer, etc.
def parse_chill_times(instructions):
    """
    Parses instructions to find chill/rest/freeze times and returns the total time in minutes.
    """
    chill_time = 0
    time_patterns = [
        (r'\b(?:chill|rest|freeze)\b.*?(\d+)\s*(hours?|hrs?)', 60),
        (r'\b(?:chill|rest|freeze)\b.*?(\d+)\s*(minutes?|mins?)', 1)
    ]

    for instruction in instructions:
        for pattern, multiplier in time_patterns:
            match = re.search(pattern, instruction, re.IGNORECASE)
            if match:
                chill_time += int(match.group(1)) * multiplier

    return chill_time if chill_time > 0 else None

# NOTE: times are stored as minutes, but displayed to user as days/hours/mins
def format_time(minutes):
    """
    Converts minutes into hours or days when necessary for display.
    - < 60 minutes -> display in minutes.
    - ≥ 60 minutes -> convert to hours.
    - ≥ 24 hours -> convert to days.
    """
    if minutes is None:
        return "Unknown"

    if minutes >= 1440:  # 24 hours = 1440 minutes
        days = minutes // 1440
        remainder = minutes % 1440
        return f"{days} day{'s' if days > 1 else ''}" + (f" {remainder//60} hr" if remainder >= 60 else "")

    if minutes >= 60:
        hours = minutes // 60
        minutes = minutes % 60
        return f"{hours} hr{'s' if hours > 1 else ''}" + (f" {minutes} min" if minutes > 0 else "")

    return f"{minutes} min"

# NOTE: Extracts recipe source (i.e., what site it came from); do we want this field?
from urllib.parse import urlparse
def extract_recipe_source(url):
    """
    Extracts the website name from the recipe URL (e.g., 'foodnetwork.com' -> 'Food Network').
    """
    domain = urlparse(url).netloc
    domain = domain.replace("www.", "").split(".")[0]  # Remove subdomains and TLDs
    return domain.capitalize()  # Capitalize for readability

###########################################
# Primary Scraping Functions: recipe-scrapers version and fallback
###########################################

def scrape_recipe(url):
    """Attempt to scrape a recipe from a given URL."""
    try:
        # html = urlopen(url).read().decode("utf-8")
        # PREVENTING 403 ERRORS
        # NOTE: sites like Taste of Home block automated requests
        headers = {"User-Agent": "Mozilla/5.0"}
        html = requests.get(url, headers=headers).text

        scraper = scrape_html(html, org_url=url)

        return {
            "title": scraper.title(),
            "total_time": scraper.total_time(),
            "prep_time": scraper.prep_time(),
            "cook_time": scraper.cook_time(),
            "ingredients": scraper.ingredients(),
            "instructions": scraper.instructions(),
            "source": extract_recipe_source(url)
        }
    
# NOTE: Commented out error message [assumption: backup scraper is robust]
    except Exception as e:
        # print(f"recipe-scrapers error: {e}. Attempting manual scraping...")
        return scrape_recipe_fallback(url)
    
# recipe-scrapers works on 400 websites, so the backup scraper handles cases
# where a recipe website is not in recipe-scrapers' scope
def scrape_recipe_fallback(url):
    """Fallback scraper using BeautifulSoup for unsupported websites."""
    headers = {"User-Agent": "Mozilla/5.0"}
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, "html.parser")

    # Extract the title
    title = soup.find("h1")
    title = title.get_text(strip=True) if title else "Unknown Title"

    # Extract ingredients by searching for common recipe patterns.
    ingredients = []
    
    # Search for sections with "ingredient" in class or id
    possible_sections = soup.find_all(
        lambda tag: tag.name in ["ul", "ol", "div", "section"]
        and any(keyword in (tag.get("class") or []) + (tag.get("id", "").split()) for keyword in ["ingredient", "ingredients"])
    )

    for section in possible_sections:
        items = section.find_all("li") or section.find_all("p")
        for item in items:
            text = item.get_text(strip=True)

            # Filter out navigation, social media, and irrelevant content
            if any(bad in text.lower() for bad in ["log in", "join", "recipe box", "see all", "customer care", "newsletters", "my account"]):
                continue
            
            # Heuristic: Keep lines that look like ingredient quantities or food names
            if re.search(r"(\d+|\b(one|two|three|four|five|six|seven|eight|nine|ten)\b).{0,5}(cup|oz|tbsp|tsp|gram|ml|lb|can|slice|dash|pinch|clove|package|head|strip|chopped|shredded|minced)", text, re.IGNORECASE):
                ingredients.append(text)

    # Extract instructions (look for paragraphs and lists)
    instructions = []
    for ol in soup.find_all("ol"):
        for li in ol.find_all("li"):
            instructions.append(li.get_text(strip=True))

    if not instructions:  # Try <p> tags if <ol> fails
        for p in soup.find_all("p"):
            if "step" in p.get_text(strip=True).lower():  # Heuristic
                instructions.append(p.get_text(strip=True))

    # Extract cooking times (look for spans, divs, or metadata)
    times = {"prep_time": None, "cook_time": None, "total_time": None}
    time_keywords = ["prep", "cook", "total"]
    for tag in soup.find_all(["span", "div", "p"]):
        text = tag.get_text(strip=True).lower()
        for key in time_keywords:
            if key in text and re.search(r"\d+", text):
                time_value = re.findall(r"(\d+)\s*(minutes?|mins?|hours?|hrs?)", text)
                if time_value:
                    num, unit = time_value[0]
                    num = int(num)
                    if "hour" in unit or "hr" in unit:
                        num *= 60  # Convert hours to minutes
                    times[f"{key}_time"] = num

    return {
        "title": title,
        "prep_time": times["prep_time"],
        "cook_time": times["cook_time"],
        "total_time": times["total_time"],
        "ingredients": ingredients,
        "instructions": instructions,
        "source": extract_recipe_source(url)
    }

##############################################################
# Main: Scrapes/parses recipe and prints output
##############################################################

if __name__ == "__main__":
    url = input("Enter a recipe URL: ")
    recipe_data = scrape_recipe(url)

    # Convert instructions to a list if it's a single string
    instructions = recipe_data["instructions"]
    if isinstance(instructions, str):
        instructions = [instructions]

    # Detect any chill/rest/freeze times from instructions
    recipe_data["chill_time"] = parse_chill_times(instructions)

    print(f"\nRecipe Title: {recipe_data['title']}")
    
    # Only print times that exist
    if recipe_data["prep_time"]:
        print(f"Prep Time: {format_time(recipe_data['prep_time'])}")
    if recipe_data["cook_time"]:
        print(f"Cook Time: {format_time(recipe_data['cook_time'])}")
    if recipe_data["chill_time"]:
        print(f"Chill Time: {format_time(recipe_data['chill_time'])}")
    if recipe_data["total_time"]:
        print(f"Total Time: {format_time(recipe_data['total_time'])}")

    print("\nIngredients:")
    structured_ingredients = parse_ingredients_list(recipe_data["ingredients"])
    for ing in structured_ingredients:
        if ing['quantity'] is not None:
            qty_str = float_to_pretty_fraction(ing['quantity'])
        else:
            qty_str = None
        print(f" - Quantity: {qty_str}, Unit: {ing['unit']}, Item: {ing['item']}")

    print("\nInstructions:")
    for step in instructions:
        print(f" - {step}")
