#!/usr/bin/env python3
"""Add all major brand foods and more general foods - NO PORK."""

import json
import os

FOODS_PATH = os.path.join(os.path.dirname(__file__), "assets", "foods", "common_foods.json")

def make(name, serving, cal, pro, carb, fat, fiber=0, sodium=0, sugar=0, chol=0,
         iron=0, calcium=0, potassium=0, vitA=0, vitB12=0, vitC=0, vitD=0,
         zinc=0, mag=0, vitE=0, vitK=0, vitB6=0, folate=0, phos=0, sel=0, mang=0,
         category="Snacks"):
    return {
        "name": name, "servingSize": serving,
        "calories": cal, "protein": pro, "carbs": carb, "fat": fat,
        "fiber": fiber, "sodium": sodium, "sugar": sugar, "cholesterol": chol,
        "iron": iron, "calcium": calcium, "potassium": potassium,
        "vitaminA": vitA, "vitaminB12": vitB12, "vitaminC": vitC, "vitaminD": vitD,
        "zinc": zinc, "magnesium": mag, "vitaminE": vitE, "vitaminK": vitK,
        "vitaminB6": vitB6, "folate": folate, "phosphorus": phos,
        "selenium": sel, "manganese": mang, "category": category
    }

new_foods = []

# ============================================================
# BRITANNIA
# ============================================================
new_foods += [
    # Biscuits
    make("Britannia Marie Gold (5 biscuits)", "5 biscuits (35g)", 145, 2.5, 24, 4.2, 0.5, 160, 8, category="Snacks"),
    make("Britannia Marie Gold (1 pack)", "1 pack (73g)", 300, 5, 50, 8.8, 1, 340, 16, category="Snacks"),
    make("Britannia Good Day Butter (5 biscuits)", "5 biscuits (33g)", 155, 2, 22, 6.5, 0.5, 110, 7, category="Snacks"),
    make("Britannia Good Day Cashew (5 biscuits)", "5 biscuits (33g)", 160, 2.5, 21, 7, 0.5, 100, 6, category="Snacks"),
    make("Britannia Good Day Choco Chip (5 biscuits)", "5 biscuits (33g)", 158, 2, 22, 7, 0.5, 105, 8, category="Snacks"),
    make("Britannia 50-50 Maska Chaska (5 biscuits)", "5 biscuits (30g)", 135, 2, 20, 5.5, 0.5, 200, 2, category="Snacks"),
    make("Britannia 50-50 Sweet & Salty (5 biscuits)", "5 biscuits (30g)", 130, 2, 21, 4.5, 0.5, 190, 4, category="Snacks"),
    make("Britannia Tiger Krunch Biscuit (5 pcs)", "5 biscuits (30g)", 130, 2, 21, 4.5, 0.5, 120, 5, category="Snacks"),
    make("Britannia Bourbon Cream (4 biscuits)", "4 biscuits (40g)", 190, 2.5, 27, 8, 1, 130, 12, category="Snacks"),
    make("Britannia NutriChoice Digestive (4 biscuits)", "4 biscuits (33g)", 140, 3, 22, 5, 3, 180, 4, category="Healthy Snacks"),
    make("Britannia NutriChoice Oats (4 biscuits)", "4 biscuits (33g)", 135, 3, 22, 4.5, 3, 170, 3, category="Healthy Snacks"),
    make("Britannia NutriChoice Sugar Free (4 biscuits)", "4 biscuits (28g)", 115, 2.5, 20, 3, 2, 150, 0, category="Healthy Snacks"),
    make("Britannia Milk Bikis (5 biscuits)", "5 biscuits (33g)", 145, 2.5, 23, 5, 0.5, 100, 6, category="Snacks"),
    make("Britannia Jim Jam (4 biscuits)", "4 biscuits (40g)", 185, 2, 28, 7, 0.5, 100, 12, category="Snacks"),
    make("Britannia Pure Magic Chocolush (4 biscuits)", "4 biscuits (33g)", 165, 2, 22, 8, 1, 90, 10, category="Snacks"),
    make("Britannia Treat Croissant (Chocolate)", "1 piece (45g)", 195, 3, 24, 10, 1, 150, 9, category="Snacks"),
    # Bread
    make("Britannia White Bread (2 slices)", "2 slices (56g)", 140, 4.2, 26, 1.6, 1, 260, 2, category="Bakery & Breads"),
    make("Britannia Brown Bread (2 slices)", "2 slices (56g)", 130, 5, 24, 1.4, 3, 270, 2, iron=1.5, category="Bakery & Breads"),
    make("Britannia Multigrain Bread (2 slices)", "2 slices (56g)", 128, 5, 22, 2, 3.5, 250, 2, category="Bakery & Breads"),
    # Cheese
    make("Britannia Cheese Slices (1 slice)", "1 slice (20g)", 56, 3, 1, 4.5, 0, 200, 0.3, chol=14, calcium=130, category="Dairy"),
    make("Britannia Cheese Cube (1 cube)", "1 cube (20g)", 62, 3.5, 0.5, 5, 0, 180, 0.2, calcium=140, category="Dairy"),
    # Cake
    make("Britannia Fruit Cake (1 slice)", "1 slice (65g)", 240, 3, 38, 8, 1, 140, 18, category="Bakery & Breads"),
    make("Britannia Gobbles Choco Chill (1 pack)", "1 pack (35g)", 150, 2, 22, 6.5, 0.5, 110, 12, category="Snacks"),
]

# ============================================================
# ITC - Sunfeast, Bingo, Aashirvaad
# ============================================================
new_foods += [
    # Sunfeast Biscuits
    make("Sunfeast Dark Fantasy Choco Fills (3 biscuits)", "3 biscuits (30g)", 148, 2, 19, 7, 0.5, 80, 9, category="Snacks"),
    make("Sunfeast Dark Fantasy Choco Nut Fills (3 biscuits)", "3 biscuits (30g)", 152, 2.5, 18, 8, 1, 75, 8, category="Snacks"),
    make("Sunfeast Mom's Magic Butter (5 biscuits)", "5 biscuits (33g)", 155, 2, 22, 6.5, 0.5, 100, 6, category="Snacks"),
    make("Sunfeast Mom's Magic Cashew & Almond (5 pcs)", "5 biscuits (33g)", 158, 2.5, 21, 7, 0.5, 95, 6, category="Snacks"),
    make("Sunfeast Marie Light (5 biscuits)", "5 biscuits (33g)", 130, 2.5, 23, 3.5, 0.5, 150, 5, category="Snacks"),
    make("Sunfeast Farmlite Digestive (4 biscuits)", "4 biscuits (33g)", 140, 3, 22, 5, 3, 170, 4, category="Healthy Snacks"),
    make("Sunfeast Farmlite Oats & Raisins (4 biscuits)", "4 biscuits (33g)", 135, 2.5, 23, 4.5, 2.5, 160, 6, category="Healthy Snacks"),
    make("Sunfeast Bounce Cream Biscuit (4 biscuits)", "4 biscuits (40g)", 190, 2, 27, 8.5, 0.5, 110, 11, category="Snacks"),
    # Bingo Chips
    make("Bingo Mad Angles Masala (Small)", "1 pack (36g)", 175, 2, 22, 9, 1, 340, 1, category="Snacks"),
    make("Bingo Mad Angles Tomato (Small)", "1 pack (36g)", 175, 2, 22, 9, 1, 350, 2, category="Snacks"),
    make("Bingo Original Style Salted (Small)", "1 pack (26g)", 135, 1.5, 15, 8, 0.5, 200, 0, category="Snacks"),
    make("Bingo Tedhe Medhe Masala Tadka", "1 pack (35g)", 170, 2, 22, 8, 1, 360, 1, category="Snacks"),
    make("Bingo Hashtags (Tikka Surprise)", "1 pack (35g)", 172, 2, 23, 8.5, 1, 340, 1, category="Snacks"),
    # Yippee Noodles
    make("Sunfeast Yippee Magic Masala (1 pack)", "1 pack (70g)", 300, 6.5, 42, 12, 2, 880, 1, category="Snacks"),
    # Aashirvaad
    make("Aashirvaad Atta Noodles (1 pack)", "1 pack (70g)", 290, 7, 43, 10, 3, 850, 1, category="Snacks"),
    make("Aashirvaad Multigrain Atta (per roti)", "1 roti (35g)", 85, 3, 16, 1, 2, 100, 0, iron=1.5, category="Roti & Bread"),
]

# ============================================================
# NESTLE
# ============================================================
new_foods += [
    make("Nestle KitKat (2 finger)", "1 bar (18.5g)", 96, 1, 12, 5, 0.3, 18, 9.5, category="Snacks"),
    make("Nestle KitKat (4 finger)", "1 bar (37.3g)", 193, 2.4, 24.5, 10, 0.5, 36, 19, category="Snacks"),
    make("Nestle Munch (1 bar)", "1 bar (23g)", 126, 1.5, 15, 7, 0.3, 50, 10, category="Snacks"),
    make("Nestle Munch Max", "1 bar (42g)", 228, 2.5, 27, 12.5, 0.5, 90, 18, category="Snacks"),
    make("Nestle Milkybar (25g)", "1 bar (25g)", 140, 1.8, 15, 8, 0, 40, 14, calcium=50, category="Snacks"),
    make("Nestle Bar One", "1 bar (33g)", 162, 1.5, 22, 7.5, 0.3, 60, 18, category="Snacks"),
    make("Nestle Alpino (25g)", "1 bar (25g)", 140, 2, 15, 8, 0.5, 30, 12, category="Snacks"),
    make("Nescafe Classic Coffee (1 cup)", "1 cup (200ml) with milk & sugar", 65, 1.5, 10, 2, 0, 20, 8, category="Beverages"),
    make("Nescafe Classic Coffee (Black, no sugar)", "1 cup (200ml)", 4, 0.3, 0.5, 0, 0, 5, 0, category="Beverages"),
    make("Nescafe Cold Coffee (Can)", "1 can (180ml)", 145, 3, 22, 5, 0, 75, 20, category="Beverages"),
    make("Nestle Cerelac Stage 1 (Wheat)", "1 serving (25g)", 100, 2.5, 18, 1.5, 1, 20, 7, iron=5, calcium=100, vitD=3, zinc=1.5, category="Breakfast"),
    make("Nestle Cerelac Stage 2 (Wheat Rice)", "1 serving (25g)", 100, 2.5, 18, 1.5, 1, 20, 7, iron=5, calcium=100, category="Breakfast"),
    make("Nestle Everyday Dairy Whitener (1 tsp)", "1 tsp (5g)", 25, 1, 2.5, 1.3, 0, 15, 2, category="Extras"),
    make("Nestle a+ Slim Milk (200ml)", "1 glass (200ml)", 80, 6, 10, 1.5, 0, 90, 10, calcium=240, category="Dairy"),
    make("Nestle a+ Toned Milk (200ml)", "1 glass (200ml)", 110, 6, 10, 5, 0, 90, 10, calcium=240, category="Dairy"),
]

# ============================================================
# CADBURY / MONDELEZ
# ============================================================
new_foods += [
    make("Cadbury Dairy Milk (25g)", "1 bar (25g)", 137, 2, 14.5, 7.8, 0.3, 45, 13.5, category="Snacks"),
    make("Cadbury Dairy Milk (50g)", "1 bar (50g)", 274, 4, 29, 15.5, 0.5, 90, 27, category="Snacks"),
    make("Cadbury Dairy Milk Silk (60g)", "1 bar (60g)", 335, 4.5, 35, 20, 0.5, 100, 33, category="Snacks"),
    make("Cadbury Dairy Milk Silk Oreo", "1 bar (60g)", 320, 4, 38, 17, 1, 130, 30, category="Snacks"),
    make("Cadbury Dairy Milk Silk Bubbly", "1 bar (50g)", 280, 4, 29, 16.5, 0.5, 80, 28, category="Snacks"),
    make("Cadbury Dairy Milk Fruit & Nut (42g)", "1 bar (42g)", 210, 3.5, 24, 11, 1, 50, 21, category="Snacks"),
    make("Cadbury Dairy Milk Roast Almond (42g)", "1 bar (42g)", 220, 4, 22, 13, 1.5, 45, 19, category="Snacks"),
    make("Cadbury 5 Star (22g)", "1 bar (22g)", 102, 1, 15, 4.5, 0, 40, 12, category="Snacks"),
    make("Cadbury 5 Star (40g)", "1 bar (40g)", 186, 1.5, 27, 8, 0, 75, 22, category="Snacks"),
    make("Cadbury Perk (13g)", "1 bar (13g)", 68, 0.8, 8.5, 3.5, 0, 25, 7, category="Snacks"),
    make("Cadbury Gems (18g)", "1 pack (18g)", 82, 0.8, 12, 3.5, 0, 10, 11, category="Snacks"),
    make("Cadbury Bournville Dark Chocolate (33g)", "1 bar (33g)", 170, 2, 19, 10, 1.5, 5, 14, category="Snacks"),
    make("Cadbury Fuse (50g)", "1 bar (50g)", 250, 4, 30, 12, 1, 100, 22, category="Snacks"),
    make("Cadbury Oreo Biscuit (6 biscuits)", "6 biscuits (50g)", 235, 2.5, 36, 9, 1, 240, 18, category="Snacks"),
    make("Cadbury Oreo Chocolate Creme (6 biscuits)", "6 biscuits (50g)", 240, 2.5, 35, 10, 1, 230, 18, category="Snacks"),
    make("Cadbury Celebrations Pack (per piece avg)", "1 piece avg (15g)", 75, 1, 9.5, 3.8, 0.2, 20, 8, category="Snacks"),
]

# ============================================================
# FERRERO / MARS / OTHER CHOCOLATES
# ============================================================
new_foods += [
    make("Ferrero Rocher (1 piece)", "1 piece (12.5g)", 73, 0.9, 6.5, 5, 0.3, 12, 5, category="Snacks"),
    make("Ferrero Rocher (3 pieces)", "3 pieces (37.5g)", 220, 2.8, 19.5, 15, 1, 36, 15, category="Snacks"),
    make("Snickers (52g)", "1 bar (52g)", 245, 4.5, 32, 12, 1, 150, 26, category="Snacks"),
    make("Twix (50g)", "1 bar (50g)", 245, 2.5, 33, 12, 0.5, 100, 24, category="Snacks"),
    make("Bounty (57g)", "1 bar (57g)", 275, 2, 33, 15, 2, 55, 28, category="Snacks"),
    make("Mars Bar (51g)", "1 bar (51g)", 228, 2.5, 35, 9, 0.5, 90, 30, category="Snacks"),
    make("Toblerone (35g)", "1 piece (35g)", 185, 2.5, 20, 10.5, 0.5, 20, 18, category="Snacks"),
    make("Kinder Bueno (43g)", "1 bar (43g)", 240, 4, 23, 15, 1, 60, 18, category="Snacks"),
    make("Kinder Joy (20g)", "1 piece (20g)", 112, 1.5, 11, 7, 0, 30, 10, category="Snacks"),
    make("Lindt Excellence 70% Dark (40g)", "4 squares (40g)", 230, 3.5, 17, 17, 4, 5, 10, category="Snacks"),
]

# ============================================================
# BEVERAGES - Soft Drinks, Juices
# ============================================================
new_foods += [
    make("Pepsi (250ml)", "1 can (250ml)", 110, 0, 28, 0, 0, 25, 27, category="Beverages"),
    make("Pepsi (500ml)", "1 bottle (500ml)", 220, 0, 56, 0, 0, 50, 54, category="Beverages"),
    make("Fanta Orange (250ml)", "1 can (250ml)", 115, 0, 29, 0, 0, 20, 28, category="Beverages"),
    make("Fanta Orange (500ml)", "1 bottle (500ml)", 230, 0, 58, 0, 0, 40, 56, category="Beverages"),
    make("7UP (250ml)", "1 can (250ml)", 100, 0, 26, 0, 0, 30, 25, category="Beverages"),
    make("7UP (500ml)", "1 bottle (500ml)", 200, 0, 52, 0, 0, 60, 50, category="Beverages"),
    make("Mountain Dew (250ml)", "1 can (250ml)", 115, 0, 31, 0, 0, 35, 30, category="Beverages"),
    make("Mountain Dew (500ml)", "1 bottle (500ml)", 230, 0, 62, 0, 0, 70, 60, category="Beverages"),
    make("Monster Energy Drink (250ml)", "1 can (250ml)", 110, 0, 27, 0, 0, 180, 26, category="Beverages"),
    make("Monster Energy Drink (500ml)", "1 can (500ml)", 220, 0, 54, 0, 0, 360, 52, category="Beverages"),
    make("Sting Energy Drink (250ml)", "1 can (250ml)", 120, 0, 30, 0, 0, 130, 29, category="Beverages"),
    make("Coca Cola (500ml)", "1 bottle (500ml)", 210, 0, 53, 0, 0, 45, 53, category="Beverages"),
    make("Coca Cola Zero (500ml)", "1 bottle (500ml)", 0, 0, 0, 0, 0, 40, 0, category="Beverages"),
    make("Diet Coke (330ml)", "1 can (330ml)", 1, 0, 0, 0, 0, 40, 0, category="Beverages"),
    make("Pepsi Black / Zero (500ml)", "1 bottle (500ml)", 0, 0, 0, 0, 0, 45, 0, category="Beverages"),

    # Juices
    make("Tropicana Orange Juice (200ml)", "1 pack (200ml)", 88, 1.4, 20, 0, 0.4, 4, 18, vitC=40, category="Beverages"),
    make("Tropicana Apple Juice (200ml)", "1 pack (200ml)", 92, 0.2, 22, 0, 0.2, 6, 20, category="Beverages"),
    make("Tropicana Mixed Fruit (200ml)", "1 pack (200ml)", 90, 0.5, 21, 0, 0.3, 5, 19, vitC=20, category="Beverages"),
    make("Tropicana Mango Delight (200ml)", "1 pack (200ml)", 96, 0.3, 23, 0, 0.3, 10, 21, vitA=50, category="Beverages"),
    make("Real Fruit Juice - Mixed Fruit (200ml)", "1 pack (200ml)", 92, 0.5, 22, 0, 0.3, 8, 20, category="Beverages"),
    make("Real Fruit Juice - Mango (200ml)", "1 pack (200ml)", 100, 0.3, 24, 0, 0.3, 10, 22, category="Beverages"),
    make("Real Fruit Juice - Pomegranate (200ml)", "1 pack (200ml)", 88, 0.5, 21, 0, 0.2, 8, 19, category="Beverages"),
    make("Paper Boat Aam Panna (200ml)", "1 pack (200ml)", 80, 0, 20, 0, 0, 180, 18, vitC=10, category="Beverages"),
    make("Paper Boat Jaljeera (200ml)", "1 pack (200ml)", 35, 0, 8, 0, 0, 280, 5, category="Beverages"),
    make("Paper Boat Aamras (200ml)", "1 pack (200ml)", 120, 0.5, 29, 0, 0.5, 10, 26, category="Beverages"),
    make("Paper Boat Chilli Guava (200ml)", "1 pack (200ml)", 70, 0.5, 16, 0, 1, 150, 14, vitC=30, category="Beverages"),
    make("Raw Pressery Orange Juice (250ml)", "1 bottle (250ml)", 112, 1.5, 25, 0.5, 0.5, 5, 22, vitC=50, category="Beverages"),
    make("Raw Pressery Apple Juice (250ml)", "1 bottle (250ml)", 118, 0.5, 28, 0, 0.5, 5, 24, category="Beverages"),
]

# ============================================================
# HEALTH DRINKS & NUTRITION
# ============================================================
new_foods += [
    make("Boost Health Drink (with milk)", "2 tsp + 200ml milk", 175, 7.5, 26, 4.5, 0, 100, 20, iron=3, calcium=250, vitD=3, vitB12=0.5, category="Beverages"),
    make("Boost Health Drink (with water)", "2 tsp (20g)", 75, 1.5, 16, 0.5, 0, 30, 14, iron=3, category="Beverages"),
    make("Protinex Original (with milk)", "2 tbsp + 200ml milk", 195, 15, 22, 5, 1, 120, 14, iron=4, calcium=300, vitD=3, category="Protein"),
    make("Protinex Lite (with milk)", "2 tbsp + 200ml milk", 170, 12, 22, 4, 1, 110, 12, calcium=280, category="Protein"),
    make("Ensure (Vanilla, with water)", "2 scoops (53g)", 220, 9, 32, 6, 1.5, 190, 10, iron=3, calcium=200, vitD=5, vitC=20, zinc=2.5, category="Protein"),
    make("Ensure (Chocolate, with water)", "2 scoops (53g)", 220, 9, 33, 6, 1.5, 200, 11, iron=3, calcium=200, vitD=5, category="Protein"),
    make("Horlicks Protein Plus (with milk)", "2 tbsp + 200ml milk", 200, 16, 24, 5, 1, 130, 14, iron=4, calcium=350, vitD=5, vitB12=1, category="Protein"),
    make("Pediasure (Vanilla, with water)", "5 scoops + 190ml water", 225, 7, 25, 10, 1, 85, 8, iron=2.5, calcium=200, vitD=5, category="Beverages"),
]

# ============================================================
# KELLOGG'S & QUAKER - Breakfast Cereals
# ============================================================
new_foods += [
    make("Kellogg's Corn Flakes (1 bowl with milk)", "30g + 150ml milk", 195, 7, 32, 3.5, 0.5, 260, 14, iron=5, calcium=180, vitD=2.5, category="Breakfast"),
    make("Kellogg's Corn Flakes (dry, 30g)", "30g", 110, 2, 25, 0.2, 0.5, 200, 3, iron=5, category="Breakfast"),
    make("Kellogg's Chocos (1 bowl with milk)", "30g + 150ml milk", 210, 7, 35, 4, 1.5, 210, 20, iron=5, calcium=180, category="Breakfast"),
    make("Kellogg's Chocos (dry, 30g)", "30g", 120, 2, 25, 1.5, 1.5, 150, 12, iron=5, category="Breakfast"),
    make("Kellogg's Muesli Fruit & Nut (50g)", "50g", 190, 5, 33, 4.5, 4, 30, 12, iron=3, category="Breakfast"),
    make("Kellogg's Oats (1 bowl, cooked)", "40g dry + water", 148, 5, 26, 2.5, 4, 2, 0.5, iron=2, mag=40, category="Breakfast"),
    make("Kellogg's All Bran Wheat Flakes (30g)", "30g + 150ml milk", 185, 8, 31, 3, 4, 250, 12, iron=6, category="Breakfast"),
    make("Kellogg's Special K (30g with milk)", "30g + 150ml milk", 185, 8, 30, 3, 1, 220, 12, iron=6, category="Breakfast"),
    make("Quaker Oats (1 bowl, cooked)", "40g dry + water", 150, 5, 27, 2.5, 4, 0, 0.5, iron=2, mag=40, phos=130, category="Breakfast"),
    make("Quaker Oats Masala (1 pack)", "1 pack (40g)", 155, 4.5, 26, 3.5, 3, 380, 1, category="Breakfast"),
    make("Saffola Masala Oats (1 pack)", "1 pack (40g)", 155, 4, 25, 4, 3, 450, 1, category="Breakfast"),
    make("Saffola Masala Oats (Classic Masala)", "1 pack (38g)", 148, 4, 24, 3.5, 3, 430, 1, category="Breakfast"),
    make("Bagrry's Muesli (Fruit & Nut, 50g)", "50g", 195, 5.5, 32, 5, 4.5, 25, 10, iron=3, category="Breakfast"),
    make("Bagrry's Corn Flakes (30g with milk)", "30g + 150ml milk", 195, 7, 33, 3, 1, 240, 12, category="Breakfast"),
]

# ============================================================
# CHIPS & NAMKEEN - More Brands
# ============================================================
new_foods += [
    make("Lay's Classic Salted (52g)", "1 pack (52g)", 278, 3, 27, 18, 1.5, 280, 0.5, category="Snacks"),
    make("Lay's Magic Masala (52g)", "1 pack (52g)", 276, 3, 27, 17.5, 1.5, 320, 1, category="Snacks"),
    make("Lay's Chile Limon (52g)", "1 pack (52g)", 276, 3, 28, 17, 1.5, 310, 1, category="Snacks"),
    make("Uncle Chipps Spicy Treat", "1 pack (55g)", 290, 3, 28, 18.5, 1.5, 340, 1, category="Snacks"),
    make("Uncle Chipps Plain Salted", "1 pack (55g)", 292, 3, 27, 19, 1.5, 280, 0.5, category="Snacks"),
    make("Pringles Original (40g)", "1 serving (40g)", 210, 2, 22, 13, 1, 380, 0.5, category="Snacks"),
    make("Pringles Sour Cream & Onion (40g)", "1 serving (40g)", 208, 2, 22, 12.5, 1, 400, 1, category="Snacks"),
    make("Pringles Hot & Spicy (40g)", "1 serving (40g)", 208, 2, 23, 12, 1, 420, 1, category="Snacks"),
    make("Doritos Nacho Cheese (44g)", "1 pack (44g)", 220, 3, 26, 12, 1.5, 350, 1, category="Snacks"),
    make("Doritos Sweet Chilli (44g)", "1 pack (44g)", 218, 3, 27, 11, 1.5, 330, 2, category="Snacks"),
    make("Too Yumm Multigrain Chips (28g)", "1 pack (28g)", 120, 2, 18, 5, 2, 200, 1, category="Healthy Snacks"),
    make("Too Yumm Veggie Stix (28g)", "1 pack (28g)", 115, 2, 17, 5, 1.5, 210, 1, category="Healthy Snacks"),
    make("Bikaji Bhujia Sev (50g)", "50g", 280, 5.5, 24, 18, 2, 440, 1, category="Snacks"),
    make("Bikaji Aloo Bhujia (50g)", "50g", 275, 5, 25, 17, 2, 420, 1, category="Snacks"),
]

# ============================================================
# PATANJALI & DABUR
# ============================================================
new_foods += [
    make("Patanjali Atta Noodles (1 pack)", "1 pack (70g)", 285, 7, 44, 9.5, 3, 820, 1, category="Snacks"),
    make("Patanjali Doodh Biscuit (5 biscuits)", "5 biscuits (33g)", 140, 2.5, 22, 5, 0.5, 120, 6, category="Snacks"),
    make("Patanjali Cow Ghee (1 tsp)", "1 tsp (5g)", 45, 0, 0, 5, 0, 0, 0, chol=1, vitA=30, category="Extras"),
    make("Patanjali Honey (1 tbsp)", "1 tbsp (21g)", 64, 0, 17, 0, 0, 2, 17, category="Extras"),
    make("Dabur Honey (1 tbsp)", "1 tbsp (21g)", 65, 0, 17, 0, 0, 2, 17, category="Extras"),
    make("Dabur Chyawanprash (1 tsp)", "1 tsp (15g)", 35, 0.5, 8, 0, 0.5, 5, 6, vitC=10, iron=1, category="Extras"),
    make("Dabur Real Juice - Guava (200ml)", "1 pack (200ml)", 88, 0.5, 21, 0, 1, 8, 18, vitC=30, category="Beverages"),
]

# ============================================================
# ICE CREAM BRANDS
# ============================================================
new_foods += [
    make("Amul Ice Cream (Vanilla, 1 scoop)", "1 scoop (80g)", 130, 2.5, 17, 6, 0, 40, 14, calcium=60, category="Sweets"),
    make("Amul Ice Cream (Chocolate, 1 scoop)", "1 scoop (80g)", 140, 3, 18, 6.5, 0.5, 45, 15, category="Sweets"),
    make("Amul Chocobar (1 bar)", "1 bar (65ml)", 165, 2.5, 18, 9.5, 0.5, 35, 16, category="Sweets"),
    make("Amul Kool Cafe (200ml)", "1 bottle (200ml)", 160, 4, 22, 6, 0, 80, 18, category="Beverages"),
    make("Amul Kool Kesar (200ml)", "1 bottle (200ml)", 140, 3, 20, 5, 0, 70, 18, category="Beverages"),
    make("Kwality Walls Cornetto (Butterscotch)", "1 cone (110ml)", 220, 3, 28, 10, 0.5, 70, 22, category="Sweets"),
    make("Kwality Walls Cornetto (Chocolate)", "1 cone (110ml)", 230, 3, 30, 11, 1, 75, 24, category="Sweets"),
    make("Kwality Walls Magnum (Classic)", "1 bar (90ml)", 260, 3.5, 26, 16, 1, 50, 22, category="Sweets"),
    make("Kwality Walls Feast (Orange)", "1 bar (65ml)", 55, 0.5, 13, 0.2, 0, 10, 10, category="Sweets"),
    make("Kwality Walls Paddle Pop (Rainbow)", "1 bar (60ml)", 60, 1, 10, 2, 0, 20, 8, category="Sweets"),
    make("Baskin Robbins Ice Cream (1 scoop)", "1 scoop (80g)", 160, 2.5, 20, 8, 0.5, 50, 16, category="Sweets"),
    make("Baskin Robbins Sundae (Regular)", "1 sundae (180g)", 380, 5, 48, 18, 1, 120, 38, category="Sweets"),
    make("Naturals Ice Cream Tender Coconut (1 scoop)", "1 scoop (80g)", 120, 2, 16, 5.5, 0.5, 25, 13, category="Sweets"),
    make("Naturals Ice Cream Alphonso Mango (1 scoop)", "1 scoop (80g)", 130, 2, 18, 5.5, 0.5, 25, 15, category="Sweets"),
    make("Naturals Ice Cream Sitaphal (1 scoop)", "1 scoop (80g)", 135, 2, 18, 6, 0.5, 20, 14, category="Sweets"),
]

# ============================================================
# MOTHER DAIRY
# ============================================================
new_foods += [
    make("Mother Dairy Toned Milk (200ml)", "1 glass (200ml)", 120, 6.2, 9.4, 6, 0, 90, 9, calcium=240, vitD=1, category="Dairy"),
    make("Mother Dairy Double Toned Milk (200ml)", "1 glass (200ml)", 86, 6.2, 9.4, 2.5, 0, 90, 9, calcium=240, category="Dairy"),
    make("Mother Dairy Full Cream Milk (200ml)", "1 glass (200ml)", 140, 6, 9, 8.5, 0, 80, 9, calcium=240, category="Dairy"),
    make("Mother Dairy Dahi (1 cup, 100g)", "1 cup (100g)", 58, 3, 5, 3, 0, 40, 4, calcium=120, category="Dairy"),
    make("Mother Dairy Mishti Doi (100g)", "1 cup (100g)", 100, 3, 15, 3, 0, 35, 13, calcium=100, category="Dairy"),
    make("Mother Dairy Lassi (Mango, 200ml)", "1 pack (200ml)", 130, 3, 24, 2.5, 0, 50, 22, category="Beverages"),
    make("Mother Dairy Ice Cream (Vanilla, 1 scoop)", "1 scoop (80g)", 130, 2.5, 17, 6, 0, 40, 14, category="Sweets"),
    make("Mother Dairy Paneer (100g)", "100g", 265, 18, 1.2, 21, 0, 18, 0, calcium=480, category="Dairy"),
]

# ============================================================
# KNORR SOUPS & SAUCES
# ============================================================
new_foods += [
    make("Knorr Classic Tomato Soup (1 serving)", "1 cup (200ml)", 65, 1, 11, 1.5, 1, 580, 4, vitC=5, category="Soups"),
    make("Knorr Classic Mixed Vegetable Soup", "1 cup (200ml)", 55, 1.5, 9, 1.5, 1, 560, 2, category="Soups"),
    make("Knorr Classic Hot & Sour Soup", "1 cup (200ml)", 50, 1, 9, 1, 0.5, 600, 1, category="Soups"),
    make("Knorr Classic Sweet Corn Soup", "1 cup (200ml)", 60, 1, 11, 1, 0.5, 540, 2, category="Soups"),
    make("Knorr Chicken Soup", "1 cup (200ml)", 70, 2, 10, 2, 0.5, 620, 2, category="Soups"),
]

# ============================================================
# BAKERY - Monginis, Theobroma
# ============================================================
new_foods += [
    make("Monginis Chocolate Truffle Pastry", "1 slice (100g)", 380, 4, 42, 22, 1.5, 180, 30, category="Bakery & Breads"),
    make("Monginis Black Forest Pastry", "1 slice (100g)", 340, 4, 40, 18, 1, 160, 28, category="Bakery & Breads"),
    make("Monginis Veg Puff", "1 piece (80g)", 260, 4, 26, 16, 1.5, 380, 2, category="Bakery & Breads"),
    make("Monginis Chicken Puff", "1 piece (80g)", 280, 8, 24, 17, 1, 400, 2, category="Bakery & Breads"),
    make("Monginis Veg Sandwich", "1 sandwich (120g)", 240, 6, 30, 11, 2, 420, 3, category="Bakery & Breads"),
    make("Monginis Cheese Garlic Bread", "1 piece (60g)", 200, 5, 24, 9, 1, 340, 2, category="Bakery & Breads"),
    make("Theobroma Chocolate Brownie", "1 piece (80g)", 360, 4, 40, 22, 2, 120, 30, category="Bakery & Breads"),
    make("Theobroma Red Velvet Pastry", "1 slice (110g)", 400, 5, 44, 24, 0.5, 200, 32, category="Bakery & Breads"),
    make("Theobroma Chocolate Overload Cake (1 slice)", "1 slice (120g)", 450, 5, 48, 28, 2, 180, 36, category="Bakery & Breads"),
    make("Theobroma Cheese Croissant", "1 piece (70g)", 280, 7, 24, 18, 1, 320, 2, category="Bakery & Breads"),
    make("Theobroma Almond Croissant", "1 piece (80g)", 330, 6, 28, 22, 2, 260, 8, category="Bakery & Breads"),
]

# ============================================================
# COOKING OILS & GHEE (per serving)
# ============================================================
new_foods += [
    make("Saffola Gold Oil (1 tbsp)", "1 tbsp (15ml)", 120, 0, 0, 14, 0, 0, 0, vitE=3, category="Extras"),
    make("Fortune Sunflower Oil (1 tbsp)", "1 tbsp (15ml)", 120, 0, 0, 14, 0, 0, 0, vitE=5, category="Extras"),
    make("Fortune Rice Bran Oil (1 tbsp)", "1 tbsp (15ml)", 120, 0, 0, 14, 0, 0, 0, vitE=4, category="Extras"),
    make("Sundrop Superlite Oil (1 tbsp)", "1 tbsp (15ml)", 120, 0, 0, 14, 0, 0, 0, vitE=3, category="Extras"),
    make("Mustard Oil (1 tbsp)", "1 tbsp (15ml)", 120, 0, 0, 14, 0, 0, 0, category="Extras"),
    make("Coconut Oil (1 tbsp)", "1 tbsp (15ml)", 120, 0, 0, 14, 0, 0, 0, category="Extras"),
    make("Olive Oil (1 tbsp)", "1 tbsp (15ml)", 119, 0, 0, 14, 0, 0, 0, vitE=2, vitK=8, category="Extras"),
    make("Desi Ghee (1 tsp)", "1 tsp (5g)", 45, 0, 0, 5, 0, 0, 0, chol=1, vitA=30, category="Extras"),
    make("Desi Ghee (1 tbsp)", "1 tbsp (14g)", 126, 0, 0, 14, 0, 0, 0, chol=3, vitA=84, category="Extras"),
    make("Butter (Amul, 1 tbsp)", "1 tbsp (14g)", 100, 0.1, 0, 11.5, 0, 82, 0, chol=31, vitA=96, category="Extras"),
]

# ============================================================
# MORE INTERNATIONAL / GLOBAL FOODS
# ============================================================
new_foods += [
    # Pasta
    make("Spaghetti Bolognese (Chicken)", "1 plate (350g)", 480, 24, 56, 16, 4, 620, 8, category="International"),
    make("Penne Arrabiata", "1 plate (300g)", 380, 10, 58, 12, 4, 540, 8, category="International"),
    make("Penne Alfredo (Chicken)", "1 plate (350g)", 520, 26, 52, 22, 3, 680, 5, category="International"),
    make("Mac & Cheese (1 bowl)", "1 bowl (250g)", 430, 16, 40, 22, 2, 720, 5, calcium=250, category="International"),
    make("Lasagna (Veg)", "1 serving (300g)", 380, 16, 36, 18, 4, 580, 6, category="International"),
    make("Lasagna (Chicken)", "1 serving (300g)", 420, 24, 34, 20, 3, 640, 5, category="International"),

    # Mexican
    make("Chicken Burrito", "1 burrito (350g)", 520, 28, 54, 20, 6, 820, 4, category="International"),
    make("Veg Burrito", "1 burrito (320g)", 450, 14, 58, 16, 8, 740, 4, category="International"),
    make("Chicken Tacos (2 pieces)", "2 tacos (200g)", 380, 20, 30, 20, 4, 580, 3, category="International"),
    make("Veg Tacos (2 pieces)", "2 tacos (180g)", 320, 8, 34, 16, 5, 520, 4, category="International"),
    make("Chicken Quesadilla", "1 quesadilla (250g)", 480, 26, 34, 26, 3, 720, 3, category="International"),
    make("Nachos with Cheese Dip", "1 plate (200g)", 440, 8, 42, 28, 3, 680, 4, category="International"),
    make("Guacamole (1 serving)", "1 serving (50g)", 80, 1, 4, 7, 3, 200, 0.5, potassium=250, category="International"),

    # Sushi
    make("Salmon Sushi Roll (6 pieces)", "6 pieces (180g)", 280, 12, 40, 6, 2, 500, 4, category="International"),
    make("Veg Sushi Roll (6 pieces)", "6 pieces (170g)", 220, 4, 42, 3, 2, 460, 5, category="International"),
    make("California Roll (6 pieces)", "6 pieces (180g)", 260, 8, 38, 8, 2, 480, 4, category="International"),

    # Thai
    make("Pad Thai (Chicken)", "1 plate (350g)", 480, 22, 58, 18, 3, 780, 8, category="International"),
    make("Thai Green Curry (Chicken)", "1 bowl (300g)", 380, 24, 14, 26, 3, 640, 4, category="International"),
    make("Thai Red Curry (Veg)", "1 bowl (300g)", 320, 8, 18, 24, 4, 600, 5, category="International"),
    make("Tom Yum Soup (Chicken)", "1 bowl (250g)", 140, 12, 8, 6, 1, 720, 3, vitC=10, category="Soups"),

    # Mediterranean
    make("Hummus (1 serving)", "1 serving (50g)", 80, 3, 8, 4, 2, 150, 0.5, iron=1, category="International"),
    make("Falafel (4 pieces)", "4 pieces (120g)", 280, 10, 30, 14, 5, 480, 2, iron=3, category="International"),
    make("Pita Bread (1 piece)", "1 piece (60g)", 165, 5.5, 33, 0.7, 1.3, 322, 0.7, category="Roti & Bread"),
    make("Tzatziki (1 serving)", "1 serving (50g)", 35, 2, 2, 2, 0, 120, 1, calcium=30, category="International"),

    # Japanese
    make("Miso Soup", "1 bowl (200g)", 40, 3, 4, 1.5, 0.5, 800, 1, category="Soups"),
    make("Teriyaki Chicken Bowl", "1 bowl (350g)", 480, 28, 56, 14, 2, 820, 12, category="International"),
    make("Ramen (Chicken)", "1 bowl (400g)", 450, 22, 50, 16, 2, 1200, 3, category="International"),
    make("Edamame (1 cup)", "1 cup (155g)", 188, 18, 14, 8, 8, 9, 3, iron=3.5, mag=100, category="International"),
]

# ============================================================
# MORE VEGETABLES & FRUITS
# ============================================================
new_foods += [
    make("Broccoli (Steamed, 1 cup)", "1 cup (156g)", 55, 3.7, 11, 0.6, 5.1, 64, 2, vitC=101, vitK=220, folate=168, category="Vegetables"),
    make("Spinach (Raw, 1 cup)", "1 cup (30g)", 7, 0.9, 1, 0.1, 0.7, 24, 0.1, iron=0.8, vitA=281, vitK=145, folate=58, category="Vegetables"),
    make("Spinach (Cooked, 1 cup)", "1 cup (180g)", 41, 5.3, 7, 0.5, 4.3, 126, 0.8, iron=6.4, calcium=245, vitA=943, category="Vegetables"),
    make("Sweet Potato (Baked, 1 medium)", "1 medium (114g)", 103, 2.3, 24, 0.1, 3.8, 41, 7, vitA=1096, vitC=22, potassium=542, category="Vegetables"),
    make("Avocado (1 whole)", "1 whole (200g)", 320, 4, 17, 30, 14, 14, 1, potassium=970, vitK=42, folate=162, mag=58, category="Fruits"),
    make("Avocado (1/2)", "1/2 avocado (100g)", 160, 2, 8.5, 15, 7, 7, 0.7, potassium=485, category="Fruits"),
    make("Blueberries (1 cup)", "1 cup (148g)", 85, 1.1, 21, 0.5, 3.6, 1, 15, vitC=14, vitK=29, mang=0.5, category="Fruits"),
    make("Strawberries (1 cup)", "1 cup (152g)", 49, 1, 12, 0.5, 3, 2, 7, vitC=89, folate=36, mang=0.6, category="Fruits"),
    make("Kiwi (1 fruit)", "1 kiwi (69g)", 42, 0.8, 10, 0.4, 2.1, 2, 6, vitC=64, vitK=28, category="Fruits"),
    make("Pineapple (1 cup)", "1 cup (165g)", 82, 0.9, 22, 0.2, 2.3, 2, 16, vitC=79, mang=1.5, category="Fruits"),
    make("Dragon Fruit (1 whole)", "1 whole (200g)", 120, 2.4, 26, 0.8, 3.6, 4, 16, vitC=6, iron=1.2, mag=68, category="Fruits"),
    make("Pomegranate (1 whole)", "1 whole (282g)", 234, 4.7, 53, 3.3, 11, 8, 39, vitC=29, potassium=666, folate=107, category="Fruits"),
    make("Pomegranate Seeds (1 cup)", "1 cup (174g)", 144, 2.9, 33, 2, 7, 5, 24, vitC=18, potassium=411, category="Fruits"),
    make("Jackfruit (1 cup)", "1 cup (165g)", 155, 2.8, 40, 0.5, 2.5, 3, 32, vitC=14, potassium=500, category="Fruits"),
    make("Litchi / Lychee (10 pieces)", "10 pieces (100g)", 66, 0.8, 17, 0.4, 1.3, 1, 15, vitC=72, category="Fruits"),
    make("Chikoo / Sapota (1 whole)", "1 whole (120g)", 100, 0.5, 25, 1.3, 6, 14, 20, vitC=17, potassium=250, category="Fruits"),
    make("Custard Apple / Sitaphal (1 whole)", "1 whole (150g)", 150, 2.5, 38, 0.5, 5.4, 6, 30, vitC=37, potassium=380, category="Fruits"),
    make("Amla / Indian Gooseberry (2 pieces)", "2 pieces (20g)", 9, 0.2, 2, 0, 0.7, 0.2, 0, vitC=100, category="Fruits"),
    make("Beetroot (Raw, 1 medium)", "1 medium (82g)", 35, 1.3, 8, 0.1, 2.3, 64, 5.5, iron=0.7, folate=89, potassium=267, category="Vegetables"),
    make("Carrot (Raw, 1 medium)", "1 medium (61g)", 25, 0.6, 6, 0.1, 1.7, 42, 2.9, vitA=509, vitK=8, category="Vegetables"),
    make("Cucumber (1 whole)", "1 whole (300g)", 45, 2, 11, 0.3, 1.5, 6, 5, vitK=49, category="Vegetables"),
    make("Tomato (1 medium)", "1 medium (123g)", 22, 1.1, 5, 0.2, 1.5, 6, 3.2, vitC=17, vitA=42, potassium=292, category="Vegetables"),
    make("Onion (1 medium)", "1 medium (110g)", 44, 1.2, 10, 0.1, 1.9, 4, 5, vitC=8, folate=21, category="Vegetables"),
    make("Green Peas (1 cup)", "1 cup (145g)", 118, 8, 21, 0.6, 7.4, 7, 8, vitC=58, vitK=36, iron=2.1, category="Vegetables"),
    make("Corn (1 cob)", "1 cob (100g)", 86, 3.3, 19, 1.2, 2.7, 15, 3.2, vitC=7, folate=42, category="Vegetables"),
    make("Mushroom (Raw, 1 cup)", "1 cup (70g)", 15, 2.2, 2.3, 0.2, 0.7, 4, 1.4, sel=6.5, vitD=0.1, category="Vegetables"),
    make("Bell Pepper (1 medium)", "1 medium (120g)", 31, 1, 7, 0.2, 2.5, 4, 4, vitC=152, vitA=37, category="Vegetables"),
    make("Cabbage (Raw, 1 cup shredded)", "1 cup (89g)", 22, 1.1, 5, 0.1, 2.2, 16, 2.8, vitC=33, vitK=67, category="Vegetables"),
]

# ============================================================
# MORE PROTEIN BARS FROM VARIOUS BRANDS
# ============================================================
new_foods += [
    make("Quest Protein Bar (Chocolate Chip Cookie Dough)", "1 bar (60g)", 200, 21, 22, 8, 14, 280, 1, calcium=200, category="Snacks"),
    make("ONE Protein Bar (Maple Glazed Doughnut)", "1 bar (60g)", 220, 20, 24, 8, 1, 210, 1, category="Snacks"),
    make("Clif Builder's Protein Bar (Chocolate)", "1 bar (68g)", 270, 20, 30, 10, 3, 280, 18, category="Snacks"),
    make("Kind Protein Bar (Crunchy Peanut Butter)", "1 bar (50g)", 250, 12, 17, 17, 5, 140, 6, category="Snacks"),
    make("Grenade Carb Killa (Caramel Chaos)", "1 bar (60g)", 222, 23, 18, 8, 2, 230, 2, category="Snacks"),
    make("Fulfill Protein Bar (Chocolate Brownie)", "1 bar (55g)", 173, 20, 18, 5, 1, 140, 1, category="Snacks"),
    make("Barebells Protein Bar (Caramel Cashew)", "1 bar (55g)", 199, 20, 18, 7, 0.5, 150, 2, category="Snacks"),
    make("PhD Smart Bar (Chocolate Brownie)", "1 bar (64g)", 228, 20, 24, 8, 2, 160, 2, category="Snacks"),
    make("Phab Protein Bar (Double Chocolate)", "1 bar (65g)", 248, 21, 24, 9, 10, 65, 3, category="Snacks"),
    make("Phab Protein Bar (Cookies & Cream)", "1 bar (65g)", 245, 21, 25, 8, 10, 60, 4, category="Snacks"),
]

# ============================================================
# DOSA / SOUTH INDIAN VARIETIES
# ============================================================
new_foods += [
    make("Mysore Masala Dosa", "1 dosa (200g)", 340, 7, 42, 16, 3, 460, 3, category="South Indian"),
    make("Set Dosa (2 pieces)", "2 pieces (150g)", 210, 5, 34, 6, 2, 340, 2, category="South Indian"),
    make("Neer Dosa (2 pieces)", "2 pieces (120g)", 160, 3, 30, 3, 1, 240, 1, category="South Indian"),
    make("Ghee Roast Dosa", "1 dosa (140g)", 260, 4, 30, 14, 1, 300, 1, category="South Indian"),
    make("Podi Dosa", "1 dosa (130g)", 240, 5, 28, 12, 2, 360, 1, category="South Indian"),
    make("Onion Uttapam", "1 uttapam (180g)", 240, 6, 36, 8, 2, 360, 2, category="South Indian"),
    make("Tomato Uttapam", "1 uttapam (180g)", 230, 6, 35, 7, 2, 370, 3, category="South Indian"),
    make("Idiyappam / String Hoppers (3 pieces)", "3 pieces (90g)", 160, 3, 32, 2, 1, 200, 0, category="South Indian"),
    make("Appam (1 piece)", "1 piece (80g)", 120, 2, 22, 3, 1, 180, 1, category="South Indian"),
    make("Pesarattu (Moong Dosa)", "1 dosa (120g)", 180, 8, 24, 6, 3, 300, 1, iron=2, category="South Indian"),
    make("Pongal (Ven Pongal)", "1 bowl (200g)", 250, 6, 38, 8, 2, 360, 1, category="South Indian"),
    make("Curd Vada (2 pieces)", "2 pieces (150g)", 260, 7, 28, 13, 2, 380, 4, category="South Indian"),
    make("Sambar Vada (2 pieces)", "2 pieces with sambar (200g)", 300, 9, 32, 14, 4, 480, 3, category="South Indian"),
    make("Filter Coffee (South Indian)", "1 cup (150ml)", 80, 2, 10, 3, 0, 30, 8, calcium=60, category="Beverages"),
]

# ============================================================
# MORE DAL & LENTIL VARIETIES
# ============================================================
new_foods += [
    make("Rajma Chawal (1 plate)", "1 plate (350g)", 420, 14, 62, 10, 8, 580, 3, iron=5, category="Thali"),
    make("Chole Chawal (1 plate)", "1 plate (350g)", 440, 14, 60, 14, 8, 620, 4, iron=5, category="Thali"),
    make("Dal Chawal (1 plate)", "1 plate (300g)", 350, 12, 56, 6, 5, 480, 2, iron=4, category="Thali"),
    make("Kadhi Chawal (1 plate)", "1 plate (350g)", 380, 8, 54, 14, 3, 500, 4, category="Thali"),
    make("Sambar Rice (1 plate)", "1 plate (300g)", 320, 8, 52, 8, 4, 520, 3, category="Thali"),
    make("Dal Khichdi", "1 bowl (250g)", 280, 10, 42, 8, 4, 400, 1, iron=3, category="Rice"),
    make("Pav Bhaji Rice", "1 plate (350g)", 450, 10, 58, 18, 5, 680, 6, category="Thali"),
]

# ============================================================
# DRY FRUITS & NUTS (per serving)
# ============================================================
new_foods += [
    make("Almonds (10 pieces)", "10 pieces (14g)", 82, 3, 2, 7, 1.7, 0, 0.5, vitE=3.6, mag=38, calcium=34, category="Dry Fruits & Nuts"),
    make("Almonds (1/4 cup)", "1/4 cup (35g)", 206, 7.5, 5.5, 18, 4.3, 0, 1, vitE=9, mag=96, calcium=85, category="Dry Fruits & Nuts"),
    make("Cashews (10 pieces)", "10 pieces (15g)", 87, 2.7, 4.5, 6.6, 0.5, 2, 0.9, zinc=0.8, iron=1, mag=44, category="Dry Fruits & Nuts"),
    make("Walnuts (5 halves)", "5 halves (15g)", 98, 2.3, 2, 9.8, 1, 0, 0.4, category="Dry Fruits & Nuts"),
    make("Walnuts (1/4 cup)", "1/4 cup (30g)", 196, 4.6, 4, 19.6, 2, 1, 0.8, category="Dry Fruits & Nuts"),
    make("Pistachios (30 pieces)", "30 pieces (18g)", 102, 3.7, 5, 8, 1.8, 1, 1, vitB6=0.3, potassium=182, category="Dry Fruits & Nuts"),
    make("Raisins (1 tbsp)", "1 tbsp (14g)", 42, 0.5, 11, 0, 0.5, 2, 9, iron=0.3, potassium=105, category="Dry Fruits & Nuts"),
    make("Dates (2 pieces)", "2 pieces (48g)", 133, 1.1, 36, 0.1, 3.2, 1, 32, potassium=334, mag=26, category="Dry Fruits & Nuts"),
    make("Dates (Medjool, 1 piece)", "1 piece (24g)", 66, 0.4, 18, 0, 1.6, 0, 16, potassium=167, category="Dry Fruits & Nuts"),
    make("Anjeer / Dried Figs (2 pieces)", "2 pieces (20g)", 50, 0.6, 13, 0.2, 2, 2, 10, calcium=32, iron=0.4, category="Dry Fruits & Nuts"),
    make("Prunes (3 pieces)", "3 pieces (25g)", 60, 0.5, 16, 0.1, 1.8, 1, 12, potassium=194, vitK=15, category="Dry Fruits & Nuts"),
    make("Mixed Dry Fruits Trail Mix (30g)", "1 handful (30g)", 150, 4, 12, 10, 2, 5, 6, vitE=3, mag=30, category="Dry Fruits & Nuts"),
    make("Makhana / Fox Nuts (1 cup roasted)", "1 cup (32g)", 106, 3, 18, 0.3, 1.4, 1, 0, calcium=16, phos=68, category="Healthy Snacks"),
    make("Flax Seeds (1 tbsp)", "1 tbsp (10g)", 55, 1.9, 3, 4.3, 2.8, 3, 0.2, mag=39, category="Seeds & Superfoods"),
    make("Chia Seeds (1 tbsp)", "1 tbsp (12g)", 58, 2, 5, 3.7, 4.1, 2, 0, calcium=76, mag=40, phos=108, category="Seeds & Superfoods"),
    make("Pumpkin Seeds (1 tbsp)", "1 tbsp (8g)", 47, 2, 1.5, 4, 0.5, 1, 0, zinc=0.7, mag=42, iron=0.7, category="Seeds & Superfoods"),
    make("Sunflower Seeds (1 tbsp)", "1 tbsp (9g)", 51, 1.8, 2, 4.5, 0.8, 1, 0.2, vitE=3, sel=4.5, category="Seeds & Superfoods"),
]

# ============================================================
# POPULAR ZOMATO/SWIGGY RESTAURANT ITEMS
# ============================================================
new_foods += [
    make("Tandoori Momos (6 pieces)", "6 pieces (180g)", 280, 12, 30, 12, 2, 460, 2, category="Snacks"),
    make("Afghani Momos (6 pieces)", "6 pieces (200g)", 340, 14, 28, 18, 2, 500, 3, category="Snacks"),
    make("Butter Chicken with 2 Naan", "1 plate (400g)", 780, 38, 58, 40, 4, 960, 6, category="Thali"),
    make("Chole Kulcha (1 plate)", "1 plate (350g)", 520, 14, 62, 22, 7, 680, 4, category="Thali"),
    make("Chicken Lollipop (6 pieces)", "6 pieces (180g)", 420, 24, 18, 28, 1, 680, 4, category="Non-Veg"),
    make("Chicken 65 (1 plate)", "1 plate (200g)", 380, 26, 16, 24, 1, 720, 3, category="Non-Veg"),
    make("Fish & Chips", "1 plate (300g)", 520, 24, 42, 28, 3, 640, 2, category="International"),
    make("Butter Garlic Prawns", "1 plate (200g)", 340, 22, 6, 26, 0, 540, 1, category="Non-Veg"),
    make("Masala Papad (1 piece)", "1 piece (30g)", 60, 3, 8, 2, 1, 400, 1, category="Extras"),
    make("Rumali Chicken Tikka Roll", "1 roll (180g)", 360, 22, 28, 18, 2, 560, 3, category="Fast Food"),
    make("Double Egg Roll", "1 roll (200g)", 380, 16, 34, 20, 2, 520, 3, category="Fast Food"),
    make("Mutton Seekh Kebab (2 pieces)", "2 pieces (120g)", 280, 22, 4, 20, 1, 500, 1, iron=3, category="Non-Veg"),
    make("Reshmi Kebab (4 pieces)", "4 pieces (120g)", 260, 24, 4, 16, 0, 460, 1, category="Non-Veg"),
    make("Galouti Kebab (4 pieces)", "4 pieces (100g)", 240, 18, 6, 16, 1, 440, 1, category="Non-Veg"),
    make("Hyderabadi Chicken Dum Biryani", "1 plate (400g)", 580, 28, 64, 22, 3, 740, 3, iron=4, category="Rice"),
    make("Lucknowi Biryani (Chicken)", "1 plate (400g)", 540, 26, 62, 20, 3, 700, 2, category="Rice"),
]

def main():
    with open(FOODS_PATH, "r", encoding="utf-8") as f:
        existing = json.load(f)

    existing_names = {item["name"].lower() for item in existing}

    added = 0
    skipped = 0
    for food in new_foods:
        if food["name"].lower() in existing_names:
            skipped += 1
        else:
            existing.append(food)
            existing_names.add(food["name"].lower())
            added += 1

    with open(FOODS_PATH, "w", encoding="utf-8") as f:
        json.dump(existing, f, indent=2, ensure_ascii=False)

    print(f"Done! Added {added} new foods, skipped {skipped} duplicates.")
    print(f"Total foods in database: {len(existing)}")

if __name__ == "__main__":
    main()