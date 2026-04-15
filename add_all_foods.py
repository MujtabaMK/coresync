#!/usr/bin/env python3
"""Add comprehensive food data to common_foods.json - NO PORK."""

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
# THE WHOLE TRUTH - Protein Bars
# ============================================================
new_foods += [
    make("The Whole Truth Protein Bar - Double Cocoa", "1 bar (52g)", 256, 13.3, 19.6, 13.8, 4.4, 7.3, 10.4),
    make("The Whole Truth Protein Bar - Peanut Butter", "1 bar (52g)", 259, 12.4, 19.1, 14.8, 2.5, 1.4, 14.8),
    make("The Whole Truth Protein Bar - Coconut Cocoa", "1 bar (52g)", 253, 12.2, 19.9, 13.9, 3.3, 6.2, 10.9),
    make("The Whole Truth Protein Bar - Cranberry", "1 bar (52g)", 235, 12.0, 21.2, 11.4, 2.2, 1.9, 14.6),
    make("The Whole Truth Protein Bar - Hazelnut Cocoa", "1 bar (52g)", 265, 12.1, 15.6, 17.2, 2.2, 13.2, 11.4),
    make("The Whole Truth Protein Bar - Orange Cocoa", "1 bar (52g)", 256, 12.9, 19.6, 13.8, 4.4, 7.0, 10.4),
    make("The Whole Truth Protein Bar - Lemon Cranberry", "1 bar (52g)", 253, 13.4, 20.8, 12.9, 2.3, 13.6, 11.1),
    make("The Whole Truth Protein Bar - Cranberry Raisin", "1 bar (52g)", 254, 12.0, 21.2, 13.5, 3.4, 13.2, 13.3),
    make("The Whole Truth Protein Bar - Almond Millet Cocoa", "1 bar (55g)", 282, 13.0, 22.0, 15.7, 8.0, 58.3, 13.1),
    make("The Whole Truth Protein Bar - Peanut Millet Cocoa", "1 bar (55g)", 270, 13.6, 23.3, 13.7, 8.2, 65.7, 11.7),
]

# THE WHOLE TRUTH - Protein Bar Pro (20g)
new_foods += [
    make("The Whole Truth Protein Bar Pro - Double Cocoa (20g)", "1 bar (67g)", 337, 20.3, 21.4, 18.8, 5.8, 143, 12.9),
    make("The Whole Truth Protein Bar Pro - Coffee Cocoa (20g)", "1 bar (67g)", 342, 20.3, 21.5, 19.4, 7.1, 122, 11.9),
    make("The Whole Truth Protein Bar Pro - Peanut Cocoa (20g)", "1 bar (67g)", 348, 20.6, 19.8, 20.7, 3.9, 117, 13.3),
]

# THE WHOLE TRUTH - Mini Protein Bars
new_foods += [
    make("The Whole Truth Mini Protein Bar - Double Cocoa", "1 bar (27g)", 133, 6.9, 10.2, 7.2, 2.8, 4, 5.4),
    make("The Whole Truth Mini Protein Bar - Coffee Cocoa", "1 bar (27g)", 128, 6.7, 10.1, 6.4, 2.8, 3, 6.1),
    make("The Whole Truth Mini Protein Bar - Cranberry", "1 bar (27g)", 122, 6.2, 11.0, 5.9, 1.2, 0.4, 7.6),
    make("The Whole Truth Mini Protein Bar - Peanut Butter", "1 bar (27g)", 134, 6.4, 9.9, 7.7, 1.3, 1, 7.7),
    make("The Whole Truth Mini Protein Bar - Peanut Cocoa", "1 bar (27g)", 127, 7.8, 11.1, 5.7, 1.4, 14, 6.5),
    make("The Whole Truth Mini Protein Bar - Coconut Cocoa", "1 bar (27g)", 131, 6.3, 10.3, 7.2, 1.7, 3.2, 5.7),
]

# THE WHOLE TRUTH - Energy Bars
new_foods += [
    make("The Whole Truth Energy Bar - Almond Choco Fudge", "1 bar (40g)", 201, 5.2, 20.7, 10.8, 4.7, 5, 9.2),
    make("The Whole Truth Energy Bar - Peanut Choco Fudge", "1 bar (40g)", 206, 5.0, 20.6, 11.5, 5.2, 4, 9.1),
    make("The Whole Truth Energy Bar - Cocoa Cranberry Fudge", "1 bar (40g)", 195, 4.8, 20.8, 10.0, 3.5, 5, 9.9),
    make("The Whole Truth Energy Bar - Mocha Almond Fudge", "1 bar (40g)", 200, 4.5, 22.0, 10.0, 4.3, 5, 9.8),
    make("The Whole Truth Energy Bar - Fig Apricot Orange", "1 bar (40g)", 170, 4.0, 23.7, 6.5, 4.0, 5, 10.9),
]

# THE WHOLE TRUTH - Nut Butters & Spreads
new_foods += [
    make("The Whole Truth Unsweetened Peanut Butter", "1 tbsp (32g)", 208, 8.0, 5.7, 17.1, 2.8, 8, 1.1, category="Spreads"),
    make("The Whole Truth Date Sweetened Peanut Butter", "1 tbsp (35g)", 223, 8.5, 7.7, 17.6, 2.8, 11, 4.5, category="Spreads"),
    make("The Whole Truth Dark Chocolate Peanut Spread", "1 tbsp (32g)", 189, 5.7, 13.4, 12.5, 3.2, 33, 4.5, category="Spreads"),
    make("The Whole Truth Hazelnut Spread", "1 tbsp (15g)", 85, 2.3, 6.8, 5.4, 1.7, 16, 2.6, category="Spreads"),
]

# THE WHOLE TRUTH - Muesli
new_foods += [
    make("The Whole Truth Muesli - Nuts, Fruits & Seeds", "50g (2 scoops)", 222, 8.1, 27.5, 8.9, 4.8, 5, 8.1, category="Breakfast"),
    make("The Whole Truth Muesli - Choco Fruit Crunch", "50g (2 scoops)", 225, 6.0, 34.2, 7.1, 5.0, 29, 10.5, category="Breakfast"),
    make("The Whole Truth Muesli - 5 Grain (No Added Sugar)", "50g (2 scoops)", 236, 6.2, 31.0, 9.8, 3.7, 5, 2.3, category="Breakfast"),
]

# THE WHOLE TRUTH - Dark Chocolates
new_foods += [
    make("The Whole Truth 71% Dark Chocolate", "1 piece (10g)", 59.7, 0.8, 4.0, 4.5, 0.8, 0.3, 2.2),
    make("The Whole Truth 55% Dark Chocolate", "1 piece (10g)", 55.9, 0.7, 5.4, 3.5, 1.0, 1.0, 3.4),
    make("The Whole Truth Orange Dark Chocolate (71%)", "1 piece (10g)", 59.8, 0.8, 4.0, 4.5, 1.0, 1.3, 2.2),
    make("The Whole Truth Sea Salt Dark Chocolate (71%)", "1 piece (10g)", 59.2, 0.8, 4.0, 4.4, 0.8, 24.6, 2.1),
    make("The Whole Truth Hazelnut Dark Chocolate (47%)", "1 piece (10g)", 57.7, 0.8, 4.8, 3.9, 1.0, 1.3, 3.0),
    make("The Whole Truth Almond Raisin Dark Chocolate (47%)", "1 piece (10g)", 54.8, 0.8, 5.2, 3.4, 0.8, 0.9, 3.3),
]

# ============================================================
# RITEBITE MAX PROTEIN - New flavors & products
# ============================================================
new_foods += [
    make("RiteBite Max Protein Daily Choco Berry Bar", "1 bar (50g)", 173, 10, 27.8, 5.8, 5, 80, 1.5),
    make("RiteBite Max Protein Daily Fruit & Nut Bar", "1 bar (50g)", 253, 10, 27, 7.3, 5, 79, 9.1),
    make("RiteBite Max Protein Daily Salt & Caramel Bar", "1 bar (50g)", 213, 10, 30, 9, 6, 51, 11),
    make("RiteBite Max Protein Active Choco Fudge Bar", "1 bar (75g)", 313, 20, 34, 13, 5, 244, 11),
    make("RiteBite Max Protein Active Peanut Butter Bar", "1 bar (70g)", 299, 20, 21, 14.9, 5, 244, 2),
    make("RiteBite Max Protein Active Choco Slim Bar", "1 bar (67g)", 267, 20, 41, 9.8, 5, 125, 3.9, calcium=250, vitB12=1.5, vitC=15, vitD=2.5, zinc=3.8, mag=40, vitE=10.1, vitB6=0.5, folate=100, phos=150, sel=17.5),
    make("RiteBite Max Protein Active Green Coffee Beans Bar", "1 bar (70g)", 235, 20, 31.6, 8.3, 7, 125, 1.9),
    make("RiteBite Max Protein Ultimate Choco Almond Bar", "1 bar (100g)", 361, 30, 76, 14.7, 10, 150, 1),
    make("RiteBite Max Protein Ultimate Choco Berry Bar", "1 bar (100g)", 361, 30, 76, 14.7, 10, 150, 1),
    make("RiteBite Max Protein Cookie Choco Chips", "1 cookie (55g)", 263, 10, 24.8, 13.7, 4, 121, 10, calcium=300),
    make("RiteBite Max Protein Cookie Choco Almond", "1 cookie (60g)", 278, 12, 22.1, 16.3, 8, 176, 3.5, calcium=325),
    make("RiteBite Max Protein Chips Cream & Onion", "1 pack (60g)", 289, 10, 29, 14, 4, 500, 2),
    make("RiteBite Max Protein Chips Peri Peri", "1 pack (60g)", 286, 10, 29.9, 13.6, 4, 500, 1.8),
    make("RiteBite Max Protein Chips Cheese & Jalapeno", "1 pack (60g)", 289, 10, 29.4, 14.1, 4, 500, 1.9),
    make("RiteBite Max Protein Chips Chinese Manchurian", "1 pack (60g)", 286, 10, 29.9, 13.6, 4, 500, 1.9),
    make("RiteBite Max Protein Chips Spanish Tomato", "1 pack (60g)", 286, 10, 29.9, 13.6, 4, 500, 1.9),
    make("RiteBite Max Protein Chips Desi Masala", "1 pack (60g)", 286, 10, 29.9, 13.6, 4, 500, 1.9),
    make("RiteBite Max Protein Peanut Butter Classic Creamy", "2 tbsp (32g)", 183, 9, 9, 12, 1, 29, 3, category="Spreads"),
    make("RiteBite Max Protein Peanut Butter Classic Crunchy", "2 tbsp (32g)", 183, 9, 9, 12, 1, 29, 3, category="Spreads"),
    make("RiteBite Max Protein Peanut Butter Choco Creamy", "2 tbsp (32g)", 179, 8, 11, 12, 1, 53, 3, category="Spreads"),
    make("RiteBite Max Protein Peanut Butter Jaggery Crunchy", "2 tbsp (32g)", 180, 7, 12, 11, 1, 30, 5, category="Spreads"),
    make("RiteBite Max Protein Peanut Butter Unsweetened", "2 tbsp (32g)", 190, 10, 6, 14, 2, 5, 1, category="Spreads"),
]

# ============================================================
# YOGA BAR - Additional products
# ============================================================
new_foods += [
    make("Yoga Bar 20g Protein Bar Almond Fudge", "1 bar (60g)", 260, 22, 18, 15, 10, 30, 3, calcium=134),
    make("Yoga Bar 20g Protein Bar Baked Brownie", "1 bar (60g)", 268, 20, 30, 15, 11, 30, 6, calcium=134),
    make("Yoga Bar 20g Protein Bar Chocolate Brownie", "1 bar (70g)", 320, 21, 27, 14.4, 9, 72, 15),
    make("Yoga Bar 20g Protein Bar Hazelnut Toffee", "1 bar (70g)", 325, 20.8, 24.2, 16.1, 9, 60, 10),
]

# ============================================================
# MUSCLEBLAZE - Additional products
# ============================================================
new_foods += [
    make("MuscleBlaze Protein Bar 10g Choco Almond", "1 bar (45g)", 181, 10, 19.9, 7.9, 3, 100, 5),
    make("MuscleBlaze Protein Bar 20g Cookies & Cream", "1 bar (62g)", 250, 20, 23.6, 9.6, 5.6, 229, 10.5),
    make("MuscleBlaze Protein Bar 30g Choco Delight", "1 bar (100g)", 334, 30, 40, 7.5, 6.5, 25, 5),
]

# ============================================================
# MYFITNESS PEANUT BUTTER
# ============================================================
new_foods += [
    make("MyFitness Peanut Butter Original Smooth", "2 tbsp (32g)", 200, 8.3, 6.1, 16, 1.6, 36, 2.2, category="Spreads"),
    make("MyFitness Peanut Butter Original Crunchy", "2 tbsp (32g)", 200, 8.3, 6.1, 16, 1.6, 36, 2.2, category="Spreads"),
    make("MyFitness Peanut Butter Chocolate Smooth", "2 tbsp (32g)", 201, 9, 5.6, 15.9, 1.6, 112, 2.2, category="Spreads"),
    make("MyFitness Natural Peanut Butter Crunchy", "2 tbsp (32g)", 199, 10.2, 4.5, 15.7, 2.6, 2, 0, category="Spreads"),
]

# ============================================================
# PINTOLA PEANUT BUTTER
# ============================================================
new_foods += [
    make("Pintola All Natural Peanut Butter", "2 tbsp (32g)", 204, 10, 6, 16, 3, 20, 1, category="Spreads"),
    make("Pintola High Protein Peanut Butter", "2 tbsp (32g)", 187, 9.6, 8.6, 12.2, 2.2, 5, 3.8, chol=4.5, category="Spreads"),
    make("Pintola Dark Chocolate Peanut Butter", "2 tbsp (32g)", 186, 6.4, 11.2, 12.8, 1.6, 4.8, 6.4, category="Spreads"),
]

# ============================================================
# PROTEIN SHAKES - Different sizes and types
# ============================================================
new_foods += [
    # Whey Protein - different scoop sizes
    make("Whey Protein (1 scoop with water)", "1 scoop (30g)", 120, 24, 3, 1.5, 0, 130, 1, category="Protein"),
    make("Whey Protein (2 scoops with water)", "2 scoops (60g)", 240, 48, 6, 3, 0, 260, 2, category="Protein"),
    make("Whey Protein (1 scoop with milk)", "1 scoop + 200ml milk", 250, 31, 13, 5.5, 0, 180, 11, calcium=200, category="Protein"),
    make("Whey Protein (2 scoops with milk)", "2 scoops + 300ml milk", 430, 58, 21, 8, 0, 340, 16, calcium=300, category="Protein"),

    # Protein Shake sizes
    make("Protein Shake - Small (200ml)", "200ml", 160, 20, 10, 4, 0, 120, 6, calcium=150, category="Protein"),
    make("Protein Shake - Medium (300ml)", "300ml", 240, 30, 15, 6, 0, 180, 9, calcium=225, category="Protein"),
    make("Protein Shake - Large (400ml)", "400ml", 320, 40, 20, 8, 0, 240, 12, calcium=300, category="Protein"),
    make("Protein Shake - Extra Large (500ml)", "500ml", 400, 50, 25, 10, 0, 300, 15, calcium=375, category="Protein"),

    # Casein Protein
    make("Casein Protein (1 scoop with water)", "1 scoop (33g)", 120, 24, 3, 1, 0.5, 160, 1, calcium=500, category="Protein"),
    make("Casein Protein (1 scoop with milk)", "1 scoop + 200ml milk", 250, 31, 13, 5, 0.5, 210, 11, calcium=700, category="Protein"),

    # Plant-Based Protein
    make("Plant Protein (1 scoop with water)", "1 scoop (35g)", 130, 22, 5, 2.5, 2, 300, 1, category="Protein"),
    make("Plant Protein (1 scoop with milk)", "1 scoop + 200ml milk", 260, 29, 15, 6.5, 2, 350, 11, calcium=200, category="Protein"),

    # Mass Gainer
    make("Mass Gainer (1 scoop with water)", "1 scoop (75g)", 280, 15, 50, 2.5, 2, 150, 8, category="Protein"),
    make("Mass Gainer (2 scoops with water)", "2 scoops (150g)", 560, 30, 100, 5, 4, 300, 16, category="Protein"),
    make("Mass Gainer (1 scoop with milk)", "1 scoop + 300ml milk", 430, 25, 65, 7, 2, 230, 23, category="Protein"),
    make("Mass Gainer (2 scoops with milk)", "2 scoops + 400ml milk", 760, 42, 118, 11, 4, 380, 34, category="Protein"),

    # BCAA
    make("BCAA Powder (1 scoop with water)", "1 scoop (7g)", 0, 5, 0, 0, 0, 10, 0, category="Protein"),
    make("EAA Powder (1 scoop with water)", "1 scoop (10g)", 5, 8, 0, 0, 0, 15, 0, category="Protein"),

    # Pre-workout
    make("Pre-Workout (1 scoop with water)", "1 scoop (10g)", 10, 0, 2, 0, 0, 50, 0, category="Protein"),

    # Creatine
    make("Creatine Monohydrate (1 scoop)", "1 scoop (5g)", 0, 0, 0, 0, 0, 0, 0, category="Protein"),
]

# ============================================================
# RESTAURANT FOODS - Popular Indian chains (NO PORK)
# ============================================================
new_foods += [
    # McDonald's
    make("McDonald's McSpicy Chicken Burger", "1 burger (190g)", 453, 22, 40, 23, 2, 780, 5, category="Fast Food"),
    make("McDonald's Chicken McNuggets (6pc)", "6 pieces (100g)", 259, 13, 16, 16, 1, 540, 0, category="Fast Food"),
    make("McDonald's Chicken McNuggets (9pc)", "9 pieces (150g)", 389, 19.5, 24, 24, 1.5, 810, 0, category="Fast Food"),
    make("McDonald's McAloo Tikki Burger", "1 burger (146g)", 339, 8, 44, 15, 3, 560, 4, category="Fast Food"),
    make("McDonald's Filet-O-Fish", "1 burger (142g)", 329, 15, 37, 14, 1, 490, 5, category="Fast Food"),
    make("McDonald's Egg McMuffin", "1 muffin (137g)", 300, 17, 30, 12, 2, 730, 3, category="Fast Food"),
    make("McDonald's Hash Brown", "1 piece (56g)", 144, 1.4, 15, 9, 1.5, 310, 0, category="Fast Food"),
    make("McDonald's French Fries (Small)", "1 small (71g)", 222, 2.7, 29, 11, 2.5, 160, 0, category="Fast Food"),
    make("McDonald's French Fries (Medium)", "1 medium (113g)", 340, 4.3, 44, 16, 4, 250, 0, category="Fast Food"),
    make("McDonald's French Fries (Large)", "1 large (154g)", 480, 6, 62, 23, 5, 350, 0, category="Fast Food"),
    make("McDonald's McFlurry Oreo", "1 cup (200g)", 340, 7, 53, 11, 0.5, 210, 43, category="Fast Food"),
    make("McDonald's Chocolate Shake (Medium)", "1 medium (400ml)", 490, 10, 79, 14, 1, 280, 63, category="Fast Food"),
    make("McDonald's Veg Pizza McPuff", "1 piece (115g)", 283, 6.4, 34, 13, 2, 430, 3, category="Fast Food"),
    make("McDonald's Chicken Maharaja Mac", "1 burger (296g)", 659, 32, 52, 36, 3, 1050, 8, category="Fast Food"),

    # KFC
    make("KFC Hot & Crispy Chicken (1 piece)", "1 piece (120g)", 290, 20, 12, 18, 0, 660, 0, category="Fast Food"),
    make("KFC Hot & Crispy Chicken (2 pieces)", "2 pieces (240g)", 580, 40, 24, 36, 0, 1320, 0, category="Fast Food"),
    make("KFC Chicken Popcorn (Regular)", "1 regular (100g)", 310, 16, 20, 18, 1, 740, 1, category="Fast Food"),
    make("KFC Chicken Popcorn (Large)", "1 large (180g)", 558, 28.8, 36, 32.4, 1.8, 1332, 1.8, category="Fast Food"),
    make("KFC Veg Zinger Burger", "1 burger (175g)", 440, 11, 52, 21, 3, 760, 5, category="Fast Food"),
    make("KFC Chicken Zinger Burger", "1 burger (190g)", 490, 24, 42, 24, 2, 830, 4, category="Fast Food"),
    make("KFC Hot Wings (5 pieces)", "5 pieces (130g)", 390, 26, 14, 26, 0, 890, 0, category="Fast Food"),
    make("KFC Chicken Rice Bowl", "1 bowl (350g)", 450, 20, 55, 16, 2, 850, 3, category="Fast Food"),
    make("KFC Coleslaw", "1 cup (100g)", 150, 1, 11, 12, 1.5, 190, 8, category="Fast Food"),
    make("KFC Tandoori Chicken (2 pieces)", "2 pieces (200g)", 380, 34, 8, 24, 0, 700, 2, category="Fast Food"),

    # Domino's Pizza (Medium - per slice)
    make("Domino's Margherita Pizza (1 slice)", "1 slice (85g)", 190, 8, 24, 7, 1, 370, 3, category="Fast Food"),
    make("Domino's Farmhouse Pizza (1 slice)", "1 slice (110g)", 230, 9, 28, 9, 2, 440, 4, category="Fast Food"),
    make("Domino's Peppy Paneer Pizza (1 slice)", "1 slice (105g)", 225, 9, 27, 9, 2, 420, 3, category="Fast Food"),
    make("Domino's Chicken Dominator Pizza (1 slice)", "1 slice (120g)", 270, 14, 28, 12, 1, 520, 3, category="Fast Food"),
    make("Domino's Veg Extravaganza Pizza (1 slice)", "1 slice (115g)", 240, 9, 29, 10, 2, 460, 4, category="Fast Food"),
    make("Domino's Non Veg Supreme Pizza (1 slice)", "1 slice (120g)", 260, 13, 27, 11, 1, 500, 3, category="Fast Food"),
    make("Domino's Garlic Breadsticks (4 pcs)", "4 pieces (100g)", 330, 8, 42, 14, 2, 580, 2, category="Fast Food"),
    make("Domino's Stuffed Garlic Bread (4 pcs)", "4 pieces (140g)", 470, 14, 48, 24, 2, 740, 3, category="Fast Food"),
    make("Domino's Pasta Italiano White Sauce (Veg)", "1 bowl (300g)", 420, 14, 52, 18, 3, 680, 5, category="Fast Food"),
    make("Domino's Pasta Italiano Red Sauce (Chicken)", "1 bowl (300g)", 380, 18, 48, 14, 4, 720, 6, category="Fast Food"),
    make("Domino's Choco Lava Cake", "1 piece (90g)", 352, 4.5, 48, 16, 1, 280, 32, category="Fast Food"),
    make("Domino's Butterscotch Mousse Cake", "1 piece (80g)", 290, 3, 38, 14, 0, 180, 28, category="Fast Food"),

    # Pizza Hut
    make("Pizza Hut Chicken Tikka Pizza (1 slice)", "1 slice (120g)", 265, 14, 28, 11, 1, 510, 3, category="Fast Food"),
    make("Pizza Hut Tandoori Paneer Pizza (1 slice)", "1 slice (110g)", 240, 10, 27, 10, 2, 450, 3, category="Fast Food"),
    make("Pizza Hut Stuffed Crust Margherita (1 slice)", "1 slice (130g)", 310, 13, 32, 14, 1, 560, 4, category="Fast Food"),
    make("Pizza Hut Chicken Wings (6 pcs)", "6 pieces (180g)", 480, 30, 12, 36, 0, 960, 2, category="Fast Food"),

    # Subway
    make("Subway Chicken Teriyaki (6 inch)", "1 sub (270g)", 340, 26, 45, 5, 4, 920, 9, category="Fast Food"),
    make("Subway Tuna Sub (6 inch)", "1 sub (250g)", 410, 19, 42, 19, 4, 720, 6, category="Fast Food"),
    make("Subway Chicken Tikka (6 inch)", "1 sub (260g)", 370, 24, 44, 8, 4, 780, 7, category="Fast Food"),
    make("Subway Paneer Tikka (6 inch)", "1 sub (250g)", 390, 16, 46, 14, 4, 680, 7, category="Fast Food"),
    make("Subway Egg Mayo (6 inch)", "1 sub (240g)", 380, 18, 43, 14, 4, 650, 5, category="Fast Food"),
    make("Subway Aloo Patty (6 inch)", "1 sub (245g)", 370, 10, 52, 13, 5, 720, 5, category="Fast Food"),
    make("Subway Chocolate Chip Cookie", "1 cookie (45g)", 210, 2, 30, 10, 1, 160, 18, category="Fast Food"),

    # Burger King
    make("Burger King Chicken Whopper", "1 burger (275g)", 630, 28, 49, 36, 2, 1050, 8, category="Fast Food"),
    make("Burger King Veg Whopper", "1 burger (260g)", 540, 14, 56, 28, 4, 920, 9, category="Fast Food"),
    make("Burger King Crispy Chicken", "1 burger (180g)", 420, 18, 38, 22, 2, 730, 5, category="Fast Food"),
    make("Burger King Paneer Royale", "1 burger (200g)", 480, 15, 42, 28, 3, 780, 5, category="Fast Food"),
    make("Burger King Onion Rings (Regular)", "1 regular (90g)", 320, 4, 36, 18, 2, 460, 4, category="Fast Food"),
    make("Burger King BK Veggie", "1 burger (155g)", 340, 10, 42, 14, 3, 620, 6, category="Fast Food"),

    # Starbucks
    make("Starbucks Caffe Latte (Tall)", "1 tall (350ml)", 150, 10, 15, 6, 0, 150, 14, calcium=250, category="Beverages"),
    make("Starbucks Caffe Latte (Grande)", "1 grande (470ml)", 190, 13, 19, 7, 0, 190, 18, calcium=350, category="Beverages"),
    make("Starbucks Cappuccino (Tall)", "1 tall (350ml)", 120, 8, 12, 4.5, 0, 120, 11, calcium=200, category="Beverages"),
    make("Starbucks Caramel Frappuccino (Tall)", "1 tall (350ml)", 300, 4, 46, 11, 0, 180, 42, category="Beverages"),
    make("Starbucks Java Chip Frappuccino (Tall)", "1 tall (350ml)", 340, 5, 50, 14, 1, 200, 45, category="Beverages"),
    make("Starbucks Hot Chocolate (Tall)", "1 tall (350ml)", 320, 10, 42, 13, 2, 210, 36, calcium=250, category="Beverages"),
    make("Starbucks Iced Americano (Tall)", "1 tall (350ml)", 10, 0, 2, 0, 0, 10, 0, category="Beverages"),
    make("Starbucks Matcha Green Tea Latte (Tall)", "1 tall (350ml)", 240, 8, 34, 7, 1, 160, 32, category="Beverages"),
    make("Starbucks Chicken Pesto Sandwich", "1 sandwich (200g)", 390, 22, 36, 18, 2, 680, 3, category="Fast Food"),
    make("Starbucks Paneer Tikka Wrap", "1 wrap (180g)", 350, 14, 38, 16, 3, 580, 4, category="Fast Food"),

    # Haldiram's
    make("Haldiram's Aloo Bhujia", "50g serving", 279, 5.5, 25, 17.5, 2, 450, 1, category="Snacks"),
    make("Haldiram's Moong Dal", "50g serving", 270, 8, 22, 17, 3, 350, 1, category="Snacks"),
    make("Haldiram's Namkeen Mix", "50g serving", 265, 5, 25, 16.5, 2, 400, 2, category="Snacks"),
    make("Haldiram's Sev Bhujia", "50g serving", 282, 5.5, 24, 18, 1.5, 420, 1, category="Snacks"),
    make("Haldiram's Rasgulla (1 piece)", "1 piece (40g)", 120, 2, 22, 2.5, 0, 15, 20, category="Sweets"),
    make("Haldiram's Gulab Jamun (1 piece)", "1 piece (35g)", 150, 2, 24, 5, 0, 20, 20, category="Sweets"),
    make("Haldiram's Kaju Katli (1 piece)", "1 piece (25g)", 120, 3, 12, 7, 0.5, 10, 10, category="Sweets"),
    make("Haldiram's Soan Papdi (1 piece)", "1 piece (25g)", 115, 2, 15, 5.5, 0.5, 8, 12, category="Sweets"),

    # Bikanervala
    make("Bikanervala Samosa (1 piece)", "1 piece (80g)", 240, 4, 24, 14, 2, 320, 2, category="Snacks"),
    make("Bikanervala Kachori (1 piece)", "1 piece (60g)", 220, 4, 22, 13, 2, 280, 1, category="Snacks"),

    # Chai & Coffee Chains
    make("Chaayos Kulhad Chai (Regular)", "1 cup (200ml)", 90, 3, 12, 3.5, 0, 40, 10, category="Beverages"),
    make("Chaayos Masala Chai (Regular)", "1 cup (200ml)", 95, 3, 13, 3.5, 0, 45, 10, category="Beverages"),
    make("CCD Cappuccino (Regular)", "1 regular (250ml)", 170, 6, 22, 6, 0, 130, 18, category="Beverages"),
    make("CCD Cold Coffee (Regular)", "1 regular (300ml)", 250, 6, 36, 9, 0, 150, 30, category="Beverages"),
    make("CCD Chocolate Shake", "1 glass (350ml)", 380, 8, 52, 16, 1, 200, 44, category="Beverages"),
]

# ============================================================
# HOMEMADE INDIAN FOODS (NO PORK)
# ============================================================
new_foods += [
    # Breakfast items
    make("Poha (Flattened Rice)", "1 plate (200g)", 250, 5, 45, 5, 2, 280, 2, iron=3.5, potassium=120, category="Breakfast"),
    make("Upma (Semolina)", "1 bowl (200g)", 230, 6, 36, 7, 3, 350, 1, iron=1.5, category="Breakfast"),
    make("Idli (2 pieces)", "2 pieces (120g)", 130, 4, 25, 1, 1.5, 380, 0.5, iron=1.0, category="South Indian"),
    make("Medu Vada (2 pieces)", "2 pieces (100g)", 280, 8, 28, 15, 3, 350, 1, category="South Indian"),
    make("Masala Dosa", "1 dosa (180g)", 296, 6, 42, 12, 3, 420, 2, iron=2, category="South Indian"),
    make("Plain Dosa", "1 dosa (120g)", 168, 4, 28, 5, 1, 280, 1, category="South Indian"),
    make("Rava Dosa", "1 dosa (150g)", 220, 4, 32, 8, 1, 380, 1, category="South Indian"),
    make("Uttapam (Onion)", "1 uttapam (180g)", 240, 6, 36, 8, 2, 360, 2, category="South Indian"),
    make("Aloo Paratha", "1 paratha (120g)", 300, 6, 38, 14, 3, 380, 1, iron=2, category="Breakfast"),
    make("Gobi Paratha", "1 paratha (120g)", 270, 6, 36, 12, 3, 350, 1, category="Breakfast"),
    make("Paneer Paratha", "1 paratha (130g)", 320, 10, 34, 16, 2, 370, 1, calcium=120, category="Breakfast"),
    make("Methi Paratha", "1 paratha (100g)", 250, 6, 32, 12, 3, 340, 1, iron=3, category="Breakfast"),
    make("Mooli Paratha", "1 paratha (120g)", 260, 5, 34, 12, 3, 360, 1, category="Breakfast"),
    make("Stuffed Paratha (Mixed Veg)", "1 paratha (130g)", 280, 6, 36, 13, 3, 370, 1, category="Breakfast"),
    make("Puri (2 pieces)", "2 pieces (60g)", 200, 3, 24, 10, 1, 180, 0, category="Breakfast"),
    make("Chole Bhature (1 plate)", "1 plate (350g)", 550, 16, 62, 26, 8, 680, 3, iron=4, category="Breakfast"),
    make("Pav Bhaji (1 plate)", "1 plate (350g)", 420, 10, 52, 20, 6, 720, 8, category="Breakfast"),
    make("Misal Pav", "1 plate (350g)", 450, 14, 54, 20, 8, 680, 4, category="Breakfast"),
    make("Sabudana Khichdi", "1 bowl (200g)", 310, 4, 52, 10, 1, 280, 2, category="Breakfast"),
    make("Besan Chilla (2 pieces)", "2 pieces (120g)", 220, 8, 20, 12, 3, 320, 1, category="Breakfast"),
    make("Moong Dal Chilla (2 pieces)", "2 pieces (120g)", 200, 10, 22, 8, 3, 300, 1, category="Breakfast"),
    make("Bread Omelette", "2 slices + 2 eggs", 350, 18, 28, 18, 2, 520, 3, category="Breakfast"),
    make("French Toast (2 slices)", "2 slices (120g)", 300, 10, 32, 14, 1, 380, 6, category="Breakfast"),
    make("Vermicelli Upma (Semiya)", "1 bowl (200g)", 240, 5, 38, 7, 2, 320, 2, category="Breakfast"),

    # Dal varieties
    make("Dal Fry", "1 bowl (200g)", 200, 10, 28, 6, 5, 450, 2, iron=3, potassium=350, category="Dal & Lentils"),
    make("Dal Tadka", "1 bowl (200g)", 220, 10, 28, 8, 5, 480, 2, iron=3, category="Dal & Lentils"),
    make("Dal Makhani", "1 bowl (200g)", 280, 12, 30, 12, 6, 520, 3, iron=4, category="Dal & Lentils"),
    make("Chana Dal", "1 bowl (200g)", 230, 12, 32, 6, 7, 420, 2, iron=3.5, category="Dal & Lentils"),
    make("Moong Dal", "1 bowl (200g)", 190, 10, 26, 5, 4, 380, 1, iron=2.5, category="Dal & Lentils"),
    make("Masoor Dal", "1 bowl (200g)", 200, 10, 28, 5, 5, 400, 1, iron=3, category="Dal & Lentils"),
    make("Toor Dal", "1 bowl (200g)", 210, 11, 28, 6, 5, 420, 2, iron=3, category="Dal & Lentils"),
    make("Sambhar", "1 bowl (200g)", 150, 6, 20, 5, 4, 500, 3, iron=2, category="South Indian"),
    make("Rasam", "1 bowl (200g)", 60, 2, 8, 2, 1, 450, 1, vitC=8, category="South Indian"),

    # Sabzi / Vegetable curries
    make("Aloo Gobi (Dry)", "1 bowl (150g)", 180, 4, 22, 8, 3, 380, 2, vitC=30, category="Indian"),
    make("Aloo Gobi (Gravy)", "1 bowl (200g)", 210, 5, 26, 10, 3, 420, 3, category="Indian"),
    make("Aloo Matar", "1 bowl (200g)", 200, 6, 28, 8, 4, 400, 3, category="Indian"),
    make("Aloo Jeera", "1 bowl (150g)", 170, 3, 24, 7, 2, 350, 1, category="Indian"),
    make("Bhindi Masala (Dry)", "1 bowl (150g)", 160, 3, 14, 10, 4, 320, 2, category="Indian"),
    make("Baingan Bharta", "1 bowl (200g)", 180, 4, 16, 12, 5, 380, 3, category="Indian"),
    make("Palak Paneer", "1 bowl (200g)", 280, 14, 12, 20, 4, 520, 2, calcium=300, iron=5, vitA=400, category="Indian"),
    make("Shahi Paneer", "1 bowl (200g)", 340, 14, 16, 26, 2, 540, 4, calcium=250, category="Indian"),
    make("Paneer Butter Masala", "1 bowl (200g)", 380, 14, 18, 28, 2, 560, 5, calcium=250, category="Indian"),
    make("Kadai Paneer", "1 bowl (200g)", 320, 14, 14, 24, 3, 500, 3, calcium=250, category="Indian"),
    make("Paneer Tikka Masala", "1 bowl (200g)", 350, 16, 16, 26, 3, 540, 4, calcium=280, category="Indian"),
    make("Matar Paneer", "1 bowl (200g)", 290, 14, 18, 18, 4, 480, 3, calcium=220, category="Indian"),
    make("Paneer Bhurji", "1 bowl (200g)", 310, 16, 10, 24, 2, 460, 2, calcium=280, category="Indian"),
    make("Malai Kofta", "1 bowl (200g)", 380, 10, 22, 28, 3, 540, 5, category="Indian"),
    make("Dum Aloo", "1 bowl (200g)", 280, 6, 28, 16, 3, 480, 3, category="Indian"),
    make("Aloo Palak", "1 bowl (200g)", 200, 5, 24, 9, 4, 420, 2, iron=4, category="Indian"),
    make("Mixed Veg Curry", "1 bowl (200g)", 180, 5, 20, 9, 4, 420, 3, category="Indian"),
    make("Lauki (Bottle Gourd) Sabzi", "1 bowl (200g)", 120, 3, 14, 6, 3, 350, 3, category="Indian"),
    make("Tinda Masala", "1 bowl (200g)", 130, 3, 14, 7, 3, 360, 2, category="Indian"),
    make("Karela Sabzi (Bitter Gourd)", "1 bowl (150g)", 140, 3, 12, 9, 4, 340, 1, vitC=40, category="Indian"),
    make("Tori (Ridge Gourd) Sabzi", "1 bowl (200g)", 110, 3, 12, 6, 3, 320, 2, category="Indian"),
    make("Cabbage Sabzi", "1 bowl (150g)", 120, 3, 12, 7, 3, 340, 2, vitC=20, category="Indian"),
    make("Rajma (Kidney Beans)", "1 bowl (200g)", 260, 12, 36, 6, 8, 520, 2, iron=4, potassium=400, category="Indian"),
    make("Chole (Chickpea Curry)", "1 bowl (200g)", 280, 12, 34, 10, 8, 560, 3, iron=4, category="Indian"),
    make("Kala Chana Masala", "1 bowl (200g)", 250, 12, 32, 8, 8, 480, 2, iron=4, category="Indian"),
    make("Kadhi Pakora", "1 bowl (200g)", 220, 6, 18, 14, 2, 440, 2, category="Indian"),
    make("Bhindi Fry (Kurkuri)", "1 bowl (150g)", 200, 3, 16, 14, 4, 360, 2, category="Indian"),
    make("Mushroom Masala", "1 bowl (200g)", 180, 6, 14, 12, 3, 420, 2, category="Indian"),
    make("Mushroom Matar", "1 bowl (200g)", 190, 8, 18, 10, 4, 440, 3, category="Indian"),
    make("Soya Chunk Curry", "1 bowl (200g)", 280, 22, 20, 12, 5, 460, 3, iron=5, category="Indian"),
    make("Chana Masala (Dry)", "1 bowl (150g)", 220, 8, 26, 10, 6, 400, 2, iron=3, category="Indian"),

    # Non-Veg Curries (NO PORK)
    make("Butter Chicken", "1 bowl (200g)", 380, 28, 14, 24, 2, 580, 4, category="Non-Veg Curry"),
    make("Chicken Tikka Masala", "1 bowl (200g)", 350, 28, 12, 22, 2, 560, 3, category="Non-Veg Curry"),
    make("Kadai Chicken", "1 bowl (200g)", 320, 26, 10, 20, 2, 520, 2, category="Non-Veg Curry"),
    make("Chicken Korma", "1 bowl (200g)", 360, 24, 16, 24, 2, 540, 4, category="Non-Veg Curry"),
    make("Chicken Do Pyaza", "1 bowl (200g)", 300, 26, 12, 18, 2, 500, 3, category="Non-Veg Curry"),
    make("Chicken Curry (Homemade)", "1 bowl (200g)", 280, 24, 10, 16, 2, 480, 2, category="Non-Veg Curry"),
    make("Chicken Saag", "1 bowl (200g)", 290, 26, 10, 18, 3, 500, 2, iron=4, category="Non-Veg Curry"),
    make("Egg Curry", "1 bowl (2 eggs, 200g)", 260, 14, 12, 18, 2, 480, 3, category="Non-Veg Curry"),
    make("Mutton Curry", "1 bowl (200g)", 380, 30, 10, 26, 2, 520, 2, iron=4, zinc=5, category="Non-Veg Curry"),
    make("Mutton Rogan Josh", "1 bowl (200g)", 400, 32, 12, 26, 2, 540, 3, iron=4, category="Non-Veg Curry"),
    make("Mutton Keema", "1 bowl (200g)", 360, 28, 10, 24, 2, 500, 2, iron=4, category="Non-Veg Curry"),
    make("Fish Curry (Homemade)", "1 bowl (200g)", 240, 22, 10, 12, 2, 480, 2, category="Non-Veg Curry"),
    make("Fish Fry (2 pieces)", "2 pieces (150g)", 320, 24, 14, 20, 1, 440, 1, category="Non-Veg"),
    make("Prawn Curry", "1 bowl (200g)", 260, 24, 10, 14, 2, 500, 2, category="Non-Veg Curry"),
    make("Prawn Masala", "1 bowl (200g)", 280, 24, 12, 16, 2, 520, 3, category="Non-Veg Curry"),
    make("Chicken Biryani (Homemade)", "1 plate (350g)", 500, 24, 60, 18, 3, 680, 2, category="Rice"),
    make("Mutton Biryani (Homemade)", "1 plate (350g)", 550, 26, 58, 22, 3, 700, 2, iron=4, category="Rice"),
    make("Veg Biryani (Homemade)", "1 plate (300g)", 380, 8, 58, 12, 4, 600, 3, category="Rice"),
    make("Egg Biryani (Homemade)", "1 plate (350g)", 450, 16, 58, 16, 3, 650, 2, category="Rice"),
    make("Chicken Pulao", "1 plate (300g)", 420, 20, 54, 14, 2, 580, 1, category="Rice"),
    make("Veg Pulao", "1 plate (300g)", 340, 6, 52, 12, 3, 520, 2, category="Rice"),
    make("Jeera Rice", "1 plate (200g)", 250, 4, 44, 6, 1, 300, 0, category="Rice"),
    make("Lemon Rice", "1 plate (200g)", 270, 4, 46, 8, 1, 350, 1, category="Rice"),
    make("Curd Rice", "1 bowl (250g)", 280, 8, 42, 8, 1, 320, 4, calcium=150, category="Rice"),
    make("Tomato Rice", "1 plate (200g)", 260, 4, 44, 7, 2, 380, 3, category="Rice"),

    # Tandoori & Tikka
    make("Tandoori Chicken (2 pieces)", "2 pieces (200g)", 340, 36, 6, 18, 1, 600, 2, category="Non-Veg"),
    make("Chicken Tikka (6 pieces)", "6 pieces (180g)", 310, 34, 6, 16, 1, 580, 2, category="Non-Veg"),
    make("Chicken Seekh Kebab (2 pieces)", "2 pieces (120g)", 240, 20, 6, 16, 1, 480, 1, category="Non-Veg"),
    make("Paneer Tikka (6 pieces)", "6 pieces (180g)", 320, 18, 12, 22, 2, 480, 2, calcium=300, category="Snacks"),
    make("Chicken Malai Tikka (6 pieces)", "6 pieces (180g)", 350, 32, 6, 22, 1, 520, 2, category="Non-Veg"),
    make("Fish Tikka (6 pieces)", "6 pieces (180g)", 280, 28, 8, 14, 1, 500, 1, category="Non-Veg"),

    # Roti & Bread
    make("Chapati (Homemade)", "1 chapati (35g)", 80, 2.5, 15, 1.5, 2, 120, 0, iron=1, category="Roti & Bread"),
    make("Phulka", "1 phulka (25g)", 60, 2, 12, 0.5, 1.5, 80, 0, category="Roti & Bread"),
    make("Tandoori Roti", "1 roti (50g)", 120, 3.5, 22, 2, 2, 200, 0, iron=1.5, category="Roti & Bread"),
    make("Butter Naan", "1 naan (90g)", 260, 7, 40, 8, 2, 420, 3, category="Roti & Bread"),
    make("Garlic Naan", "1 naan (90g)", 270, 7, 42, 8, 2, 440, 3, category="Roti & Bread"),
    make("Cheese Naan", "1 naan (100g)", 320, 10, 40, 14, 2, 500, 3, calcium=120, category="Roti & Bread"),
    make("Laccha Paratha", "1 paratha (80g)", 240, 4, 30, 12, 2, 320, 0, category="Roti & Bread"),
    make("Missi Roti", "1 roti (50g)", 130, 5, 20, 3.5, 3, 250, 0, iron=2, category="Roti & Bread"),
    make("Makki di Roti", "1 roti (60g)", 140, 3, 28, 2, 3, 200, 0, iron=1.5, category="Roti & Bread"),
    make("Rumali Roti", "1 roti (40g)", 90, 2.5, 18, 1, 1, 160, 0, category="Roti & Bread"),
    make("Kulcha (Plain)", "1 kulcha (80g)", 220, 5, 36, 6, 2, 380, 2, category="Roti & Bread"),
    make("Amritsari Kulcha (Stuffed)", "1 kulcha (120g)", 340, 8, 42, 16, 3, 480, 2, category="Roti & Bread"),
    make("Bhatura (1 piece)", "1 bhatura (80g)", 280, 5, 36, 13, 1, 340, 1, category="Roti & Bread"),

    # Snacks & Street Food
    make("Samosa (1 piece)", "1 piece (80g)", 240, 4, 24, 14, 2, 320, 2, category="Snacks"),
    make("Vada Pav", "1 piece (150g)", 290, 5, 40, 12, 3, 440, 3, category="Snacks"),
    make("Pani Puri / Gol Gappa (6 pieces)", "6 pieces (120g)", 180, 3, 30, 5, 2, 350, 4, category="Snacks"),
    make("Bhel Puri", "1 plate (150g)", 250, 5, 38, 9, 3, 380, 5, category="Snacks"),
    make("Sev Puri (6 pieces)", "6 pieces (120g)", 280, 4, 32, 15, 2, 420, 5, category="Snacks"),
    make("Dahi Puri (6 pieces)", "6 pieces (150g)", 260, 5, 32, 12, 2, 400, 6, category="Snacks"),
    make("Ragda Pattice (1 plate)", "1 plate (250g)", 350, 8, 48, 14, 5, 520, 5, category="Snacks"),
    make("Dabeli (1 piece)", "1 piece (120g)", 250, 5, 36, 10, 3, 380, 5, category="Snacks"),
    make("Kathi Roll (Chicken)", "1 roll (200g)", 380, 20, 34, 18, 2, 540, 3, category="Snacks"),
    make("Kathi Roll (Paneer)", "1 roll (200g)", 360, 14, 36, 18, 3, 500, 3, category="Snacks"),
    make("Kathi Roll (Egg)", "1 roll (180g)", 320, 14, 32, 16, 2, 480, 3, category="Snacks"),
    make("Spring Roll (Veg, 2 pieces)", "2 pieces (100g)", 220, 4, 24, 12, 2, 380, 2, category="Snacks"),
    make("Aloo Tikki (2 pieces)", "2 pieces (120g)", 280, 5, 32, 15, 3, 400, 2, category="Snacks"),
    make("Dahi Bhalla (2 pieces)", "2 pieces (150g)", 240, 6, 28, 12, 2, 420, 6, category="Snacks"),
    make("Aloo Chaat", "1 plate (150g)", 220, 4, 30, 10, 3, 380, 4, category="Snacks"),
    make("Papdi Chaat", "1 plate (150g)", 280, 5, 34, 14, 2, 440, 6, category="Snacks"),
    make("Momos (Veg, 6 pieces)", "6 pieces (150g)", 220, 5, 30, 8, 2, 380, 2, category="Snacks"),
    make("Momos (Chicken, 6 pieces)", "6 pieces (150g)", 260, 14, 28, 10, 2, 420, 2, category="Snacks"),
    make("Fried Momos (Veg, 6 pieces)", "6 pieces (180g)", 320, 5, 32, 18, 2, 440, 2, category="Snacks"),
    make("Fried Momos (Chicken, 6 pieces)", "6 pieces (180g)", 360, 14, 30, 20, 2, 480, 2, category="Snacks"),
    make("Pakora / Bhajiya (10 pieces)", "10 pieces (100g)", 280, 5, 22, 19, 2, 360, 1, category="Snacks"),
    make("Bread Pakora (2 pieces)", "2 pieces (100g)", 300, 6, 28, 18, 2, 420, 2, category="Snacks"),
    make("Paneer Pakora (6 pieces)", "6 pieces (120g)", 340, 12, 22, 24, 2, 440, 1, category="Snacks"),
    make("Onion Bhaji (5 pieces)", "5 pieces (100g)", 260, 4, 24, 16, 2, 380, 2, category="Snacks"),

    # Chinese / Indo-Chinese
    make("Veg Fried Rice", "1 plate (250g)", 320, 6, 50, 10, 3, 620, 2, category="International"),
    make("Chicken Fried Rice", "1 plate (250g)", 380, 16, 48, 14, 2, 680, 2, category="International"),
    make("Egg Fried Rice", "1 plate (250g)", 350, 12, 48, 12, 2, 650, 2, category="International"),
    make("Veg Hakka Noodles", "1 plate (250g)", 340, 6, 48, 14, 3, 700, 3, category="International"),
    make("Chicken Hakka Noodles", "1 plate (250g)", 400, 16, 46, 16, 2, 760, 3, category="International"),
    make("Egg Hakka Noodles", "1 plate (250g)", 370, 12, 46, 14, 2, 730, 3, category="International"),
    make("Manchurian (Veg, Dry)", "1 plate (200g)", 280, 5, 24, 18, 2, 580, 4, category="International"),
    make("Manchurian (Veg, Gravy)", "1 plate (250g)", 320, 5, 30, 20, 2, 640, 5, category="International"),
    make("Chicken Manchurian (Dry)", "1 plate (200g)", 320, 18, 22, 18, 2, 620, 4, category="International"),
    make("Chicken Manchurian (Gravy)", "1 plate (250g)", 360, 18, 28, 20, 2, 680, 5, category="International"),
    make("Gobi Manchurian (Dry)", "1 plate (200g)", 260, 4, 24, 16, 3, 560, 4, category="International"),
    make("Chilli Chicken (Dry)", "1 plate (200g)", 320, 22, 16, 20, 2, 640, 3, category="International"),
    make("Chilli Paneer (Dry)", "1 plate (200g)", 300, 12, 16, 22, 2, 580, 3, category="International"),
    make("Chilli Garlic Noodles", "1 plate (250g)", 360, 6, 50, 14, 2, 720, 3, category="International"),
    make("Sweet Corn Soup (Veg)", "1 bowl (200g)", 100, 3, 16, 2, 1, 500, 3, category="Soups"),
    make("Hot & Sour Soup (Veg)", "1 bowl (200g)", 80, 3, 12, 2, 1, 580, 2, category="Soups"),
    make("Manchow Soup (Veg)", "1 bowl (200g)", 110, 3, 14, 4, 1, 540, 3, category="Soups"),
    make("Chicken Sweet Corn Soup", "1 bowl (200g)", 130, 8, 16, 4, 1, 560, 3, category="Soups"),
    make("Chicken Hot & Sour Soup", "1 bowl (200g)", 110, 8, 12, 4, 1, 620, 2, category="Soups"),
    make("Chicken Manchow Soup", "1 bowl (200g)", 140, 8, 14, 6, 1, 580, 3, category="Soups"),
    make("Tomato Soup (Homemade)", "1 bowl (200g)", 90, 2, 14, 3, 2, 420, 6, vitC=15, category="Soups"),

    # Raita & Sides
    make("Boondi Raita", "1 bowl (100g)", 110, 4, 10, 6, 0.5, 280, 4, calcium=80, category="Extras"),
    make("Mixed Veg Raita", "1 bowl (100g)", 80, 3, 6, 5, 1, 250, 3, calcium=80, category="Extras"),
    make("Cucumber Raita", "1 bowl (100g)", 60, 3, 5, 3, 0.5, 200, 3, calcium=70, category="Extras"),
    make("Onion Salad", "1 serving (50g)", 20, 0.5, 4, 0, 0.5, 2, 2, vitC=4, category="Extras"),
    make("Green Chutney", "1 tbsp (15g)", 8, 0.5, 1, 0.3, 0.5, 50, 0.5, category="Extras"),
    make("Tamarind Chutney", "1 tbsp (15g)", 25, 0.2, 6, 0, 0.5, 30, 5, category="Extras"),
    make("Pickle (Mixed, 1 tbsp)", "1 tbsp (15g)", 30, 0.3, 2, 2.5, 0.5, 400, 1, category="Extras"),
    make("Papad (Roasted)", "1 piece (15g)", 45, 3, 7, 0.5, 1, 350, 0, category="Extras"),
    make("Papad (Fried)", "1 piece (15g)", 65, 3, 7, 3, 1, 380, 0, category="Extras"),

    # Desserts & Sweets
    make("Kheer (Rice)", "1 bowl (150g)", 250, 6, 36, 9, 0.5, 60, 28, calcium=150, category="Sweets"),
    make("Gulab Jamun (2 pieces)", "2 pieces (70g)", 300, 4, 48, 10, 0, 40, 40, category="Sweets"),
    make("Rasgulla (2 pieces)", "2 pieces (80g)", 240, 4, 44, 5, 0, 30, 40, category="Sweets"),
    make("Gajar Ka Halwa", "1 bowl (150g)", 320, 6, 38, 16, 3, 60, 30, vitA=600, calcium=100, category="Sweets"),
    make("Moong Dal Halwa", "1 bowl (100g)", 350, 6, 32, 22, 2, 30, 24, category="Sweets"),
    make("Suji Ka Halwa", "1 bowl (100g)", 280, 3, 34, 14, 1, 40, 22, category="Sweets"),
    make("Jalebi (3 pieces)", "3 pieces (75g)", 300, 2, 52, 10, 0, 15, 44, category="Sweets"),
    make("Rasmalai (2 pieces)", "2 pieces (80g)", 280, 6, 32, 14, 0, 50, 28, calcium=120, category="Sweets"),
    make("Kulfi (1 stick)", "1 stick (80g)", 180, 4, 22, 8, 0, 50, 18, calcium=100, category="Sweets"),
    make("Falooda", "1 glass (300ml)", 350, 6, 56, 12, 1, 80, 40, category="Sweets"),
    make("Lassi (Sweet)", "1 glass (250ml)", 180, 6, 28, 5, 0, 80, 24, calcium=200, category="Beverages"),
    make("Lassi (Salted)", "1 glass (250ml)", 100, 6, 8, 5, 0, 350, 4, calcium=200, category="Beverages"),
    make("Chaach / Buttermilk", "1 glass (250ml)", 60, 3, 6, 2, 0, 300, 4, calcium=150, category="Beverages"),
    make("Mango Shake", "1 glass (300ml)", 280, 6, 48, 7, 2, 60, 40, vitA=200, vitC=30, category="Beverages"),
    make("Banana Shake", "1 glass (300ml)", 260, 8, 40, 7, 2, 80, 32, potassium=400, category="Beverages"),
    make("Nimbu Pani (Lemon Water)", "1 glass (250ml)", 40, 0, 10, 0, 0, 200, 8, vitC=15, category="Beverages"),
    make("Sugarcane Juice", "1 glass (250ml)", 180, 0.5, 45, 0, 0, 15, 42, iron=1, category="Beverages"),
    make("Coconut Water", "1 glass (250ml)", 46, 1.7, 9, 0.5, 2.6, 252, 6, potassium=600, mag=60, category="Beverages"),
    make("Aam Panna", "1 glass (250ml)", 90, 0.5, 22, 0, 1, 200, 18, vitC=20, category="Beverages"),
    make("Jaljeera", "1 glass (250ml)", 30, 0.5, 7, 0, 0, 350, 4, category="Beverages"),

    # Egg preparations
    make("Boiled Egg (1 whole)", "1 large egg (50g)", 78, 6, 0.6, 5, 0, 62, 0.6, chol=186, vitB12=0.6, vitD=1, sel=15.4, category="Eggs & Dairy"),
    make("Boiled Egg White (1)", "1 egg white (33g)", 17, 3.6, 0.2, 0, 0, 55, 0.2, sel=6.6, category="Eggs & Dairy"),
    make("Scrambled Eggs (2 eggs)", "2 eggs (120g)", 220, 14, 2, 16, 0, 340, 1, chol=370, category="Eggs & Dairy"),
    make("Omelette (2 eggs)", "2 eggs (120g)", 190, 12, 1, 14, 0, 300, 1, chol=370, category="Eggs & Dairy"),
    make("Egg Bhurji (2 eggs)", "2 eggs with masala (150g)", 230, 14, 4, 18, 1, 380, 2, category="Eggs & Dairy"),
    make("Anda Curry (2 eggs)", "2 eggs in gravy (200g)", 260, 14, 12, 18, 2, 480, 3, category="Non-Veg Curry"),

    # Dairy
    make("Paneer (Raw)", "100g", 265, 18, 1.2, 21, 0, 18, 0, calcium=480, chol=51, category="Dairy"),
    make("Curd / Yogurt (Homemade)", "1 bowl (100g)", 60, 3, 5, 3, 0, 40, 4, calcium=120, vitB12=0.4, category="Dairy"),
    make("Greek Yogurt (Plain)", "1 cup (150g)", 130, 15, 6, 5, 0, 65, 5, calcium=180, category="Dairy"),
    make("Amul Cheese (1 slice)", "1 slice (20g)", 60, 3.5, 0.4, 5, 0, 160, 0.2, calcium=120, chol=14, category="Dairy"),
    make("Cottage Cheese (Paneer Cubes)", "50g", 132, 9, 0.6, 10.5, 0, 9, 0, calcium=240, category="Dairy"),

    # Salads
    make("Green Salad (Mixed)", "1 bowl (150g)", 25, 1.5, 4, 0.3, 2, 15, 2, vitC=15, vitA=80, category="Salads"),
    make("Kachumber Salad", "1 bowl (100g)", 30, 1, 5, 0.5, 1.5, 10, 3, vitC=10, category="Salads"),
    make("Sprouts Salad", "1 bowl (150g)", 120, 8, 18, 1, 4, 20, 2, iron=2, vitC=8, category="Salads"),
    make("Corn Salad", "1 bowl (150g)", 140, 4, 24, 3, 3, 180, 4, category="Salads"),
    make("Pasta Salad", "1 bowl (200g)", 280, 6, 38, 12, 2, 380, 4, category="Salads"),
    make("Caesar Salad (with Chicken)", "1 bowl (250g)", 350, 22, 14, 24, 3, 600, 2, category="Salads"),
    make("Fruit Salad (Mixed)", "1 bowl (200g)", 100, 1, 24, 0.5, 3, 5, 18, vitC=40, category="Salads"),

    # Thali components
    make("Plain Rice (Cooked)", "1 katori (100g)", 130, 2.7, 28, 0.3, 0.4, 1, 0, category="Rice"),
    make("Brown Rice (Cooked)", "1 katori (100g)", 112, 2.6, 24, 0.9, 1.8, 1, 0, mag=43, phos=83, category="Rice"),
    make("Basmati Rice (Cooked)", "1 katori (100g)", 121, 3.5, 25, 0.4, 0.4, 1, 0, category="Rice"),

    # Swiggy/Zomato Popular
    make("Chicken Shawarma", "1 roll (200g)", 400, 24, 34, 18, 2, 680, 3, category="Fast Food"),
    make("Veg Shawarma", "1 roll (200g)", 340, 8, 38, 16, 3, 600, 4, category="Fast Food"),
    make("Chicken Wrap (Tortilla)", "1 wrap (220g)", 420, 22, 36, 20, 3, 720, 4, category="Fast Food"),
    make("Falafel Wrap", "1 wrap (200g)", 380, 12, 42, 18, 5, 640, 4, category="Fast Food"),
    make("Grilled Chicken Sandwich", "1 sandwich (200g)", 350, 24, 32, 14, 3, 620, 3, category="Fast Food"),
    make("Veg Club Sandwich", "1 sandwich (200g)", 320, 10, 36, 16, 3, 560, 4, category="Fast Food"),
    make("Paneer Sandwich (Grilled)", "1 sandwich (180g)", 340, 14, 32, 18, 2, 540, 3, category="Fast Food"),
    make("Cheese Burger", "1 burger (180g)", 410, 20, 36, 22, 2, 680, 6, category="Fast Food"),
    make("Chicken Burger", "1 burger (180g)", 390, 22, 34, 18, 2, 660, 5, category="Fast Food"),

    # Maggi / Instant Noodles
    make("Maggi 2-Minute Noodles (1 pack)", "1 pack (70g)", 310, 7, 41, 13, 2, 950, 1, category="Snacks"),
    make("Maggi 2-Minute Noodles (2 packs)", "2 packs (140g)", 620, 14, 82, 26, 4, 1900, 2, category="Snacks"),
    make("Yippee Noodles (1 pack)", "1 pack (70g)", 300, 6.5, 42, 12, 2, 880, 1, category="Snacks"),
    make("Top Ramen (1 pack)", "1 pack (70g)", 310, 6, 42, 13, 2, 920, 1, category="Snacks"),
    make("Cup Noodles (1 cup)", "1 cup (70g)", 290, 5.5, 38, 13, 2, 900, 2, category="Snacks"),

    # More protein supplements - different brands & sizes
    make("Optimum Nutrition Gold Standard Whey (1 scoop)", "1 scoop (30.4g)", 120, 24, 3, 1, 0.5, 130, 1, calcium=100, chol=35, category="Protein"),
    make("Optimum Nutrition Gold Standard Whey (2 scoops)", "2 scoops (60.8g)", 240, 48, 6, 2, 1, 260, 2, calcium=200, chol=70, category="Protein"),
    make("MuscleBlaze Biozyme Whey (1 scoop)", "1 scoop (32g)", 126, 25, 3.6, 1.4, 0, 127, 1.5, category="Protein"),
    make("MuscleBlaze Biozyme Whey (2 scoops)", "2 scoops (64g)", 252, 50, 7.2, 2.8, 0, 254, 3, category="Protein"),
    make("Nakpro Whey Protein (1 scoop)", "1 scoop (30g)", 117, 24, 2.1, 1.2, 0, 75, 1.2, category="Protein"),
    make("AS-IT-IS Whey Protein (1 scoop)", "1 scoop (30g)", 113, 24, 2, 0.6, 0, 55, 1, category="Protein"),
    make("MyProtein Impact Whey (1 scoop)", "1 scoop (25g)", 103, 21, 1, 1.9, 0, 50, 1, category="Protein"),
    make("MyProtein Impact Whey (2 scoops)", "2 scoops (50g)", 206, 42, 2, 3.8, 0, 100, 2, category="Protein"),
    make("Dymatize ISO 100 (1 scoop)", "1 scoop (32g)", 120, 25, 2, 0.5, 0, 160, 1, calcium=80, category="Protein"),
    make("MuscleTech NitroTech (1 scoop)", "1 scoop (44g)", 160, 30, 4, 2.5, 1, 250, 2, calcium=150, category="Protein"),

    # Ready-to-Drink Protein
    make("Amul Protein Shake (Chocolate)", "1 bottle (200ml)", 140, 20, 8, 3.5, 0, 120, 6, calcium=200, category="Protein"),
    make("Amul Protein Lassi", "1 bottle (200ml)", 130, 15, 12, 3, 0, 100, 10, calcium=180, category="Protein"),
    make("Epigamia Greek Yogurt (Plain)", "1 cup (90g)", 74, 8, 4, 2.5, 0, 30, 3, calcium=100, category="Dairy"),
    make("Epigamia Greek Yogurt (Strawberry)", "1 cup (90g)", 90, 6, 10, 2.5, 0, 30, 8, calcium=80, category="Dairy"),
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