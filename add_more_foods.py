#!/usr/bin/env python3
"""Add more packed foods, Haldiram's full range, Balaji, chocolates, wafers, etc."""

import json, os

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
# HALDIRAM'S - Full Product Range
# ============================================================
new_foods += [
    # Namkeen
    make("Haldiram's Khatta Meetha", "50g serving", 265, 5, 28, 14, 2, 420, 4, category="Snacks"),
    make("Haldiram's Navratan Mix", "50g serving", 270, 6, 26, 16, 2, 400, 3, category="Snacks"),
    make("Haldiram's Nut Cracker", "50g serving", 285, 6.5, 22, 19, 2, 380, 2, category="Snacks"),
    make("Haldiram's Chana Jor Garam", "50g serving", 230, 10, 28, 8, 4, 440, 2, category="Snacks"),
    make("Haldiram's Dal Moth", "50g serving", 260, 8, 24, 15, 3, 400, 1, category="Snacks"),
    make("Haldiram's Panchratan", "50g serving", 268, 6, 26, 16, 2, 410, 3, category="Snacks"),
    make("Haldiram's Tasty Nuts", "50g serving", 290, 7, 20, 20, 2, 350, 2, category="Snacks"),
    make("Haldiram's Cornflakes Mixture", "50g serving", 260, 5, 28, 14, 1, 430, 2, category="Snacks"),
    make("Haldiram's Kashmiri Mix", "50g serving", 275, 6, 24, 17, 2, 390, 3, category="Snacks"),
    make("Haldiram's Murukku / Chakli", "50g serving", 250, 4, 30, 13, 2, 360, 1, category="Snacks"),
    make("Haldiram's Banana Chips", "50g serving", 280, 1, 28, 18, 2, 200, 3, category="Snacks"),
    make("Haldiram's Bhel Puri Kit", "1 serving (100g)", 250, 5, 38, 9, 3, 380, 5, category="Snacks"),
    make("Haldiram's Pani Puri Kit", "1 serving (80g)", 180, 3, 28, 6, 2, 320, 4, category="Snacks"),
    make("Haldiram's Samosa Snack", "50g serving", 265, 4, 26, 16, 2, 380, 2, category="Snacks"),
    make("Haldiram's Mathri", "50g serving (3 pcs)", 255, 4, 26, 15, 1, 360, 1, category="Snacks"),
    make("Haldiram's Mini Bhakarwadi", "50g serving", 260, 4, 28, 14, 2, 400, 4, category="Snacks"),
    make("Haldiram's Aloo Laccha", "50g serving", 275, 3, 26, 18, 2, 380, 1, category="Snacks"),
    make("Haldiram's Moong Dal Namkeen", "50g serving", 270, 8, 22, 17, 3, 350, 1, category="Snacks"),
    make("Haldiram's Peanut Chatpata", "50g serving", 285, 10, 16, 20, 3, 380, 2, category="Snacks"),
    # Sweets
    make("Haldiram's Besan Ladoo (1 piece)", "1 piece (30g)", 140, 2.5, 16, 7.5, 1, 10, 12, category="Sweets"),
    make("Haldiram's Motichoor Ladoo (1 piece)", "1 piece (35g)", 150, 2, 20, 7, 0.5, 15, 16, category="Sweets"),
    make("Haldiram's Peda (1 piece)", "1 piece (20g)", 80, 2, 11, 3, 0, 15, 9, calcium=40, category="Sweets"),
    make("Haldiram's Kalakand (1 piece)", "1 piece (30g)", 110, 3, 14, 5, 0, 20, 12, calcium=50, category="Sweets"),
    make("Haldiram's Barfi (1 piece)", "1 piece (25g)", 100, 2, 14, 4.5, 0, 10, 12, category="Sweets"),
    make("Haldiram's Rasgulla Can (1 piece)", "1 piece (40g)", 120, 2, 22, 2.5, 0, 15, 20, category="Sweets"),
    make("Haldiram's Gulab Jamun Can (1 piece)", "1 piece (40g)", 160, 2, 26, 5.5, 0, 18, 22, category="Sweets"),
    make("Haldiram's Cham Cham (1 piece)", "1 piece (35g)", 130, 2.5, 18, 5, 0, 15, 15, category="Sweets"),
    # Ready to Eat
    make("Haldiram's Minute Khana Dal Makhani", "1 pack (300g)", 310, 12, 34, 14, 6, 680, 3, iron=4, category="Indian"),
    make("Haldiram's Minute Khana Rajma Masala", "1 pack (300g)", 320, 10, 38, 14, 8, 700, 3, iron=5, category="Indian"),
    make("Haldiram's Minute Khana Pav Bhaji", "1 pack (300g)", 280, 6, 34, 14, 5, 640, 5, category="Indian"),
    make("Haldiram's Minute Khana Paneer Makhani", "1 pack (300g)", 350, 12, 20, 24, 3, 720, 4, calcium=200, category="Indian"),
    make("Haldiram's Minute Khana Chhole", "1 pack (300g)", 320, 12, 36, 14, 8, 680, 3, iron=4, category="Indian"),
    make("Haldiram's Minute Khana Biryani", "1 pack (250g)", 340, 8, 48, 12, 3, 620, 2, category="Indian"),
    # Frozen
    make("Haldiram's Frozen Samosa (2 pieces)", "2 pieces (120g)", 300, 5, 30, 17, 3, 440, 2, category="Snacks"),
    make("Haldiram's Frozen Aloo Tikki (2 pieces)", "2 pieces (120g)", 260, 4, 30, 14, 3, 400, 2, category="Snacks"),
    make("Haldiram's Frozen Paneer Tikka (6 pcs)", "6 pieces (180g)", 320, 16, 14, 22, 2, 520, 2, category="Snacks"),
]

# ============================================================
# BALAJI WAFERS & SNACKS
# ============================================================
new_foods += [
    make("Balaji Wafers Simply Salted", "1 pack (45g)", 245, 2.5, 24, 16, 1, 280, 0.5, category="Snacks"),
    make("Balaji Wafers Masala Masti", "1 pack (45g)", 243, 2.5, 24, 15.5, 1, 320, 1, category="Snacks"),
    make("Balaji Wafers Tomato Twist", "1 pack (45g)", 242, 2.5, 25, 15, 1, 310, 1.5, category="Snacks"),
    make("Balaji Wafers Chat Chaska", "1 pack (45g)", 240, 2.5, 25, 15, 1, 330, 1, category="Snacks"),
    make("Balaji Wafers Cream & Onion", "1 pack (45g)", 245, 2.5, 24, 16, 1, 300, 1, category="Snacks"),
    make("Balaji Ratlami Sev", "50g serving", 280, 6, 22, 19, 2, 440, 1, category="Snacks"),
    make("Balaji Sev Mamra", "50g serving", 265, 5, 28, 14, 2, 420, 2, category="Snacks"),
    make("Balaji Tikha Mitha Mix", "50g serving", 260, 5, 27, 14.5, 2, 430, 3, category="Snacks"),
    make("Balaji Farali Chevda", "50g serving", 265, 3, 26, 16, 1, 350, 3, category="Snacks"),
    make("Balaji Chana Jor Garam", "50g serving", 228, 10, 28, 8, 4, 420, 2, category="Snacks"),
    make("Balaji Ring Chips", "1 pack (40g)", 210, 2, 24, 12, 1, 300, 1, category="Snacks"),
]

# ============================================================
# ALL CHOCOLATES & WAFERS
# ============================================================
new_foods += [
    # More Cadbury
    make("Cadbury Dairy Milk Crackle (36g)", "1 bar (36g)", 192, 2.5, 22, 10.5, 0.5, 60, 20, category="Snacks"),
    make("Cadbury Dairy Milk Lickables", "1 pack (20g)", 110, 1.5, 13, 6, 0, 30, 12, category="Snacks"),
    make("Cadbury Dairy Milk Shots (18g)", "1 pack (18g)", 95, 1.5, 10, 5.5, 0, 25, 9, category="Snacks"),
    make("Cadbury Temptations Almond Treat (72g)", "1 bar (72g)", 385, 6, 42, 22, 2, 80, 36, category="Snacks"),
    make("Cadbury Temptations Rum Raisin (72g)", "1 bar (72g)", 370, 4, 44, 20, 1, 70, 38, category="Snacks"),
    make("Cadbury Silk Mousse", "1 bar (50g)", 285, 3, 30, 17, 0.5, 80, 28, category="Snacks"),
    make("Cadbury Silk Roast Almond", "1 bar (58g)", 320, 5, 32, 19, 1.5, 75, 28, category="Snacks"),
    make("Cadbury Eclairs (3 pieces)", "3 pieces (18g)", 82, 0.5, 13, 3, 0, 25, 10, category="Snacks"),
    make("Cadbury Choclairs Gold (3 pieces)", "3 pieces (18g)", 85, 0.5, 14, 3, 0, 30, 11, category="Snacks"),

    # Amul Chocolate
    make("Amul Dark Chocolate (30g)", "1 bar (30g)", 155, 2, 16, 9.5, 1.5, 5, 11, category="Snacks"),
    make("Amul Fruit & Nut Chocolate (40g)", "1 bar (40g)", 210, 3, 22, 12, 1, 20, 18, category="Snacks"),
    make("Amul Milk Chocolate (40g)", "1 bar (40g)", 220, 3, 24, 12.5, 0.5, 40, 22, category="Snacks"),

    # Wafers
    make("Parle Hide & Seek (4 biscuits)", "4 biscuits (32g)", 155, 2, 21, 7, 0.5, 90, 8, category="Snacks"),
    make("Parle Monaco (5 biscuits)", "5 biscuits (30g)", 136, 2.5, 20, 5, 0.5, 220, 2, category="Snacks"),
    make("Parle Krackjack (5 biscuits)", "5 biscuits (30g)", 132, 2, 20, 5, 0.5, 210, 3, category="Snacks"),
    make("Parle 20-20 Butter Cookies (5 pcs)", "5 biscuits (33g)", 155, 2, 22, 6.5, 0.5, 100, 6, category="Snacks"),
    make("Parle Fab Bourbon (4 biscuits)", "4 biscuits (40g)", 188, 2, 28, 8, 1, 120, 13, category="Snacks"),
    make("Parle Magix Cream Biscuit (4 pcs)", "4 biscuits (38g)", 180, 2, 26, 8, 0.5, 100, 11, category="Snacks"),
    make("Parle Rusk (2 pieces)", "2 pieces (40g)", 160, 4, 28, 4, 1, 180, 4, category="Bakery & Breads"),

    # Wafer brands
    make("Loacker Wafer Classic (1 pack)", "1 pack (45g)", 240, 3, 27, 14, 0.5, 35, 15, category="Snacks"),
    make("Parle Wafer Chocolate", "1 pack (30g)", 155, 1.5, 19, 8.5, 0.5, 50, 11, category="Snacks"),
    make("Priyagold Snax (5 biscuits)", "5 biscuits (30g)", 135, 2, 20, 5.5, 0.5, 200, 2, category="Snacks"),
    make("Unibic Choco Chip Cookies (4 pcs)", "4 cookies (40g)", 195, 2.5, 25, 9.5, 1, 100, 10, category="Snacks"),
    make("Unibic Butter Cookies (4 pcs)", "4 cookies (40g)", 200, 2, 26, 10, 0.5, 110, 8, category="Snacks"),

    # Cream Roll / Swiss Roll
    make("Cream Roll (1 piece)", "1 piece (50g)", 180, 2.5, 24, 8.5, 0.5, 120, 12, category="Bakery & Breads"),
    make("Swiss Roll Chocolate (1 slice)", "1 slice (60g)", 220, 3, 30, 10, 1, 140, 18, category="Bakery & Breads"),

    # More international chocolates
    make("M&M's Peanut (45g)", "1 pack (45g)", 225, 4, 27, 11.5, 1, 25, 24, category="Snacks"),
    make("M&M's Milk Chocolate (45g)", "1 pack (45g)", 220, 2, 31, 10, 0.5, 30, 28, category="Snacks"),
    make("Hershey's Milk Chocolate (43g)", "1 bar (43g)", 220, 3.5, 26, 12, 1, 40, 24, category="Snacks"),
    make("Hershey's Cookies & Cream (43g)", "1 bar (43g)", 220, 3, 27, 11, 0.5, 100, 25, category="Snacks"),
    make("Hershey's Kisses (7 pieces)", "7 pieces (33g)", 170, 2.5, 19, 10, 0.5, 30, 18, category="Snacks"),
    make("Milka Chocolate (25g)", "1 piece (25g)", 135, 2, 14, 8, 0.3, 25, 13, category="Snacks"),
    make("Reese's Peanut Butter Cup (2 pcs)", "2 pieces (42g)", 210, 5, 22, 12, 1, 140, 18, category="Snacks"),
    make("Maltesers (37g)", "1 pack (37g)", 187, 2.5, 24, 9, 0.5, 70, 21, category="Snacks"),
]

# ============================================================
# PACKED / READY-TO-EAT FOODS
# ============================================================
new_foods += [
    # MTR
    make("MTR Ready Meal - Rajma Masala", "1 pack (300g)", 310, 10, 36, 14, 8, 680, 3, iron=4, category="Indian"),
    make("MTR Ready Meal - Dal Fry", "1 pack (300g)", 240, 10, 30, 8, 5, 620, 2, iron=3, category="Indian"),
    make("MTR Ready Meal - Pav Bhaji", "1 pack (300g)", 270, 6, 32, 13, 5, 640, 5, category="Indian"),
    make("MTR Ready Meal - Palak Paneer", "1 pack (300g)", 310, 12, 14, 22, 4, 700, 2, calcium=250, category="Indian"),
    make("MTR Ready Meal - Alu Muttar", "1 pack (300g)", 260, 6, 30, 12, 4, 640, 3, category="Indian"),
    make("MTR Ready Meal - Chana Masala", "1 pack (300g)", 300, 10, 34, 14, 7, 680, 3, category="Indian"),
    make("MTR Ready Meal - Kadhi Pakora", "1 pack (300g)", 240, 6, 20, 15, 2, 600, 3, category="Indian"),
    make("MTR Breakfast Mix - Rava Idli (per serving)", "1 serving (40g dry)", 135, 3, 24, 2.5, 1, 350, 1, category="Breakfast"),
    make("MTR Breakfast Mix - Dosa (per dosa)", "1 dosa (35g dry)", 120, 3, 22, 2, 1, 320, 0.5, category="Breakfast"),
    make("MTR Gulab Jamun Mix (2 pieces)", "2 pieces (70g)", 280, 3, 48, 8, 0, 40, 38, category="Sweets"),
    make("MTR Badam Drink Mix (1 serving)", "1 serving (25g)", 115, 3, 16, 4.5, 1, 15, 12, calcium=60, category="Beverages"),

    # Gits
    make("Gits Ready Meal - Dal Makhani", "1 pack (300g)", 320, 12, 32, 16, 6, 700, 3, iron=4, category="Indian"),
    make("Gits Ready Meal - Paneer Makhani", "1 pack (300g)", 360, 12, 18, 26, 3, 720, 4, calcium=200, category="Indian"),
    make("Gits Ready Meal - Rajma", "1 pack (300g)", 300, 10, 36, 12, 8, 680, 3, category="Indian"),
    make("Gits Gulab Jamun Mix (2 pieces)", "2 pieces (70g)", 275, 3, 46, 8, 0, 35, 36, category="Sweets"),

    # ITC Kitchen of India
    make("Kitchen of India Dal Bukhara", "1 pack (285g)", 310, 12, 30, 16, 6, 680, 3, iron=4, category="Indian"),
    make("Kitchen of India Pav Bhaji", "1 pack (285g)", 260, 6, 30, 13, 5, 640, 5, category="Indian"),

    # Frozen Foods
    make("McCain French Fries (Baked, 100g)", "100g baked", 160, 2.5, 24, 6, 2, 280, 0.5, category="Snacks"),
    make("McCain Smiles (Baked, 100g)", "100g baked", 170, 2, 25, 7, 2, 300, 0.5, category="Snacks"),
    make("McCain Aloo Tikki (2 pieces)", "2 pieces (100g)", 200, 3, 26, 9, 2, 380, 1, category="Snacks"),
    make("Safal Frozen Peas (1 cup)", "1 cup (100g)", 80, 5, 14, 0.4, 5, 5, 5, vitC=20, category="Vegetables"),
    make("Safal Frozen Mixed Vegetables (1 cup)", "1 cup (100g)", 60, 3, 10, 0.3, 3, 40, 3, category="Vegetables"),

    # Cup Noodles / Instant
    make("Nissin Cup Noodles (Chicken)", "1 cup (70g)", 295, 6, 38, 13, 2, 940, 2, category="Snacks"),
    make("Nissin Cup Noodles (Mazedaar Masala)", "1 cup (70g)", 290, 5.5, 39, 12.5, 2, 920, 2, category="Snacks"),
    make("Wai Wai Noodles (1 pack)", "1 pack (70g)", 310, 6, 40, 14, 2, 960, 1, category="Snacks"),
    make("Ching's Instant Noodles (1 pack)", "1 pack (60g)", 270, 5, 36, 12, 1, 880, 1, category="Snacks"),
    make("Ching's Schezwan Noodles (1 pack)", "1 pack (60g)", 275, 5, 36, 12.5, 1, 900, 1, category="Snacks"),
    make("Knorr Soupy Noodles (1 pack)", "1 pack (75g)", 310, 6, 42, 13, 2, 950, 2, category="Snacks"),

    # Pasta packs
    make("Maggi Pazzta (Cheese Macaroni)", "1 pack (70g)", 290, 7, 42, 10, 2, 720, 3, category="Snacks"),
    make("Sunfeast Pasta Treat (Masala)", "1 pack (70g)", 285, 6, 44, 9.5, 2, 700, 2, category="Snacks"),
]

# ============================================================
# MORE KURKURE & LAY'S VARIANTS
# ============================================================
new_foods += [
    make("Kurkure Masala Munch", "1 pack (42g)", 215, 2.5, 25, 12, 1, 380, 2, category="Snacks"),
    make("Kurkure Chilli Chatka", "1 pack (42g)", 218, 2.5, 24, 12.5, 1, 400, 2, category="Snacks"),
    make("Kurkure Puffcorn Yummy Cheese", "1 pack (32g)", 155, 1.5, 18, 8.5, 0.5, 280, 1, category="Snacks"),
    make("Kurkure Green Chutney Rajasthani Style", "1 pack (42g)", 212, 2.5, 25, 11.5, 1, 390, 2, category="Snacks"),
    make("Kurkure Solid Masti Masala", "1 pack (42g)", 218, 2.5, 24, 12.5, 1, 410, 2, category="Snacks"),
    make("Lay's India's Magic Masala (28g)", "1 small pack (28g)", 148, 1.5, 15, 9.5, 0.5, 170, 0.5, category="Snacks"),
    make("Lay's American Style Cream & Onion (28g)", "1 small pack (28g)", 150, 1.5, 14, 10, 0.5, 180, 0.5, category="Snacks"),
    make("Lay's Maxx Hot N Chilli (35g)", "1 pack (35g)", 180, 2, 19, 11, 1, 240, 1, category="Snacks"),
    make("Lay's Wafer Style Simply Salted (28g)", "1 pack (28g)", 150, 1.5, 15, 10, 0.5, 160, 0, category="Snacks"),
]

# ============================================================
# PROTEIN POWDERS - MORE BRANDS
# ============================================================
new_foods += [
    make("GNC Pro Performance Whey (1 scoop)", "1 scoop (35g)", 130, 24, 5, 2, 0.5, 120, 2, calcium=100, category="Protein"),
    make("Isopure Zero Carb Whey (1 scoop)", "1 scoop (31g)", 100, 25, 0, 0.5, 0, 230, 0, calcium=60, category="Protein"),
    make("BSN Syntha-6 (1 scoop)", "1 scoop (47g)", 200, 22, 15, 6, 3, 280, 2, calcium=200, category="Protein"),
    make("Avvatar Whey Protein (1 scoop)", "1 scoop (32g)", 120, 24, 4, 1.5, 0, 100, 2, category="Protein"),
    make("Fast&Up Plant Protein (1 scoop)", "1 scoop (34g)", 130, 25, 3, 1.5, 2, 200, 0, category="Protein"),
    make("Oziva Protein & Herbs (Women, 1 scoop)", "1 scoop (35g)", 125, 23, 4, 2, 1, 150, 1, iron=3, category="Protein"),
    make("HealthKart HK Vitals Whey (1 scoop)", "1 scoop (32g)", 120, 24, 3.5, 1.5, 0, 110, 1.5, category="Protein"),
]

# ============================================================
# SPREADS & JAMS
# ============================================================
new_foods += [
    make("Kissan Mixed Fruit Jam (1 tbsp)", "1 tbsp (20g)", 52, 0, 13, 0, 0, 5, 12, category="Extras"),
    make("Kissan Pineapple Jam (1 tbsp)", "1 tbsp (20g)", 50, 0, 13, 0, 0, 5, 12, category="Extras"),
    make("Nutella (1 tbsp)", "1 tbsp (15g)", 80, 0.8, 9, 4.5, 0.5, 8, 8, category="Extras"),
    make("Nutella (2 tbsp)", "2 tbsp (30g)", 160, 1.5, 18, 9, 1, 15, 16, category="Extras"),
    make("Vegemite (1 tsp)", "1 tsp (5g)", 11, 1.6, 0.6, 0, 0, 180, 0.2, vitB12=0.5, folate=50, category="Extras"),
    make("Cream Cheese (1 tbsp)", "1 tbsp (15g)", 50, 1, 0.5, 5, 0, 47, 0.3, chol=16, category="Extras"),
    make("Mayonnaise (1 tbsp)", "1 tbsp (14g)", 94, 0.1, 0.1, 10, 0, 88, 0.1, category="Extras"),
    make("Dr. Oetker FunFoods Sandwich Spread (1 tbsp)", "1 tbsp (15g)", 70, 0, 2, 7, 0, 120, 1, category="Extras"),
    make("Dr. Oetker FunFoods Mayonnaise Veg (1 tbsp)", "1 tbsp (14g)", 90, 0, 1, 10, 0, 100, 0.5, category="Extras"),
]

# ============================================================
# DAIRY - More Products
# ============================================================
new_foods += [
    make("Amul Taaza Toned Milk (200ml)", "1 glass (200ml)", 120, 6, 9.6, 6, 0, 100, 9, calcium=240, category="Dairy"),
    make("Amul Gold Full Cream Milk (200ml)", "1 glass (200ml)", 148, 6, 9, 10, 0, 80, 9, calcium=240, category="Dairy"),
    make("Amul Masti Buttermilk (200ml)", "1 pack (200ml)", 36, 1.4, 5, 1, 0, 280, 3, calcium=60, category="Beverages"),
    make("Amul Lassi Mango (200ml)", "1 pack (200ml)", 130, 3, 24, 2.5, 0, 50, 22, category="Beverages"),
    make("Amul Shrikhand (Kesar, 100g)", "1 cup (100g)", 250, 5, 38, 8, 0, 40, 34, calcium=100, category="Sweets"),
    make("Epigamia Mishti Doi (100g)", "1 cup (100g)", 105, 3.5, 16, 3, 0, 30, 14, calcium=80, category="Dairy"),
    make("Yakult (1 bottle)", "1 bottle (65ml)", 50, 1, 12, 0, 0, 15, 10, category="Beverages"),
    make("Yakult Gold (1 bottle)", "1 bottle (65ml)", 42, 1, 10, 0, 0, 12, 8, category="Beverages"),
]

# ============================================================
# RUSK & TOAST
# ============================================================
new_foods += [
    make("Britannia Toastea Premium Bake Rusk (2 pcs)", "2 pieces (40g)", 160, 4, 28, 4, 1, 180, 4, category="Bakery & Breads"),
    make("Britannia Suji Rusk (2 pieces)", "2 pieces (44g)", 175, 4, 30, 4.5, 1, 180, 5, category="Bakery & Breads"),
    make("Modern Bread Rusk (2 pieces)", "2 pieces (40g)", 158, 4, 28, 3.5, 1, 170, 4, category="Bakery & Breads"),
]

# ============================================================
# ENERGY DRINKS & SPORTS
# ============================================================
new_foods += [
    make("Gatorade (500ml)", "1 bottle (500ml)", 120, 0, 30, 0, 0, 460, 28, potassium=75, category="Beverages"),
    make("Gatorade (250ml)", "1 serving (250ml)", 60, 0, 15, 0, 0, 230, 14, category="Beverages"),
    make("Electral Powder (1 sachet)", "1 sachet (21.8g) in 1L water", 70, 0, 18, 0, 0, 520, 16, potassium=300, category="Beverages"),
    make("ORS Powder (1 sachet)", "1 sachet in 1L water", 40, 0, 10, 0, 0, 480, 8, potassium=250, category="Beverages"),
    make("Glucon-D (1 glass)", "4 tsp (25g) in 200ml water", 100, 0, 25, 0, 0, 5, 24, vitC=20, category="Beverages"),
    make("Tang Orange (1 glass)", "1 tbsp + 200ml water", 50, 0, 12, 0, 0, 10, 11, vitC=15, category="Beverages"),
]

# ============================================================
# NOODLES & PASTA BRANDS
# ============================================================
new_foods += [
    make("Ching's Secret Hakka Noodles (1 pack)", "1 pack (150g cooked)", 240, 5, 38, 7, 2, 580, 1, category="International"),
    make("Smith & Jones Fried Rice Masala (per serving)", "1 tbsp (8g)", 20, 0.5, 3, 0.5, 0, 400, 0.5, category="Extras"),
    make("Maggi Hot Heads (Green Chile)", "1 pack (71g)", 300, 6, 40, 13, 2, 900, 2, category="Snacks"),
    make("Maggi Masala-ae-Magic (1 sachet)", "1 sachet (6g)", 15, 0.5, 2, 0.5, 0, 480, 0, category="Extras"),
]

# ============================================================
# POPCORN
# ============================================================
new_foods += [
    make("ACT II Butter Popcorn (1 pack)", "1 pack (40g popped)", 195, 3, 22, 11, 3, 350, 1, category="Snacks"),
    make("ACT II Classic Salted Popcorn (1 pack)", "1 pack (40g popped)", 180, 3, 23, 9, 3, 320, 0, category="Snacks"),
    make("Homemade Popcorn (Air Popped)", "1 cup (8g)", 31, 1, 6, 0.4, 1.2, 1, 0, category="Snacks"),
    make("Homemade Popcorn (Butter)", "1 cup (11g)", 55, 1, 6, 3, 1, 50, 0, category="Snacks"),
    make("Movie Theater Popcorn (Small)", "1 small (100g)", 450, 5, 50, 26, 6, 800, 1, category="Snacks"),
    make("Movie Theater Popcorn (Large)", "1 large (200g)", 900, 10, 100, 52, 12, 1600, 2, category="Snacks"),
]

# ============================================================
# CAKES, PASTRIES & BAKERY
# ============================================================
new_foods += [
    make("Chocolate Truffle Cake (1 slice)", "1 slice (100g)", 380, 4, 42, 22, 2, 180, 32, category="Bakery & Breads"),
    make("Black Forest Cake (1 slice)", "1 slice (100g)", 340, 4, 40, 18, 1, 160, 28, category="Bakery & Breads"),
    make("Red Velvet Cake (1 slice)", "1 slice (110g)", 400, 4, 46, 22, 1, 200, 34, category="Bakery & Breads"),
    make("Cheesecake (1 slice)", "1 slice (120g)", 380, 6, 30, 27, 0.5, 250, 22, chol=80, category="Bakery & Breads"),
    make("Butterscotch Cake (1 slice)", "1 slice (100g)", 360, 4, 42, 20, 0.5, 180, 30, category="Bakery & Breads"),
    make("Pineapple Cake (1 slice)", "1 slice (100g)", 320, 3, 40, 16, 0.5, 160, 26, category="Bakery & Breads"),
    make("Vanilla Sponge Cake (1 slice)", "1 slice (80g)", 250, 3, 34, 12, 0.5, 150, 20, category="Bakery & Breads"),
    make("Muffin (Chocolate Chip)", "1 muffin (110g)", 380, 5, 52, 17, 2, 320, 28, category="Bakery & Breads"),
    make("Muffin (Blueberry)", "1 muffin (110g)", 360, 4, 50, 16, 2, 300, 26, category="Bakery & Breads"),
    make("Croissant (Plain)", "1 croissant (55g)", 230, 4, 26, 12, 1, 310, 4, category="Bakery & Breads"),
    make("Croissant (Chocolate Filled)", "1 croissant (70g)", 310, 5, 34, 18, 1.5, 280, 14, category="Bakery & Breads"),
    make("Doughnut (Glazed)", "1 doughnut (50g)", 195, 2.5, 26, 9, 0.5, 160, 12, category="Bakery & Breads"),
    make("Doughnut (Chocolate)", "1 doughnut (60g)", 260, 3, 32, 14, 1, 200, 16, category="Bakery & Breads"),
    make("Brownie (1 piece)", "1 piece (60g)", 260, 3, 30, 15, 1, 120, 22, category="Bakery & Breads"),
    make("Cinnamon Roll (1 piece)", "1 piece (80g)", 320, 4, 44, 14, 1, 300, 20, category="Bakery & Breads"),
    make("Puff Pastry (Veg)", "1 piece (80g)", 260, 4, 26, 16, 1, 380, 2, category="Bakery & Breads"),
    make("Puff Pastry (Chicken)", "1 piece (80g)", 280, 8, 24, 17, 1, 400, 2, category="Bakery & Breads"),
    make("Paneer Puff", "1 piece (80g)", 270, 7, 24, 16, 1, 380, 2, category="Bakery & Breads"),
    make("Egg Puff", "1 piece (80g)", 260, 8, 24, 15, 1, 400, 2, category="Bakery & Breads"),
    make("Banana Bread (1 slice)", "1 slice (60g)", 195, 3, 28, 8, 1, 180, 14, category="Bakery & Breads"),
]

# ============================================================
# MORE HEALTHY FOODS & SUPERFOODS
# ============================================================
new_foods += [
    make("Quinoa (Cooked, 1 cup)", "1 cup (185g)", 222, 8, 39, 3.5, 5, 13, 2, iron=2.8, mag=118, phos=281, folate=78, mang=1.2, category="Grains"),
    make("Quinoa (Dry, 50g)", "50g", 180, 7, 32, 3, 3.5, 7, 0.8, iron=2.3, mag=96, phos=228, category="Grains"),
    make("Couscous (Cooked, 1 cup)", "1 cup (157g)", 176, 6, 36, 0.3, 2, 8, 0.3, sel=43, category="Grains"),
    make("Bulgur Wheat (Cooked, 1 cup)", "1 cup (182g)", 151, 5.6, 34, 0.4, 8, 9, 0.3, iron=1.7, mag=58, category="Grains"),
    make("Amaranth (Cooked, 1 cup)", "1 cup (246g)", 251, 9, 46, 4, 5, 15, 0, iron=5, mag=160, phos=364, category="Grains"),
    make("Ragi / Finger Millet Porridge", "1 bowl (200g)", 160, 4, 30, 2, 4, 10, 2, calcium=320, iron=3.5, category="Breakfast"),
    make("Ragi Dosa", "1 dosa (100g)", 150, 3.5, 28, 3, 3, 260, 1, calcium=280, category="South Indian"),
    make("Jowar (Sorghum) Roti", "1 roti (50g)", 130, 3.5, 26, 1.5, 3, 180, 0, iron=2, category="Roti & Bread"),
    make("Bajra (Pearl Millet) Roti", "1 roti (50g)", 140, 4, 24, 3, 4, 160, 0, iron=3, mag=60, category="Roti & Bread"),
    make("Sattu Drink", "1 glass (200ml)", 120, 6, 18, 2, 3, 200, 2, iron=2, category="Beverages"),
    make("Sattu Paratha", "1 paratha (100g)", 260, 8, 32, 11, 4, 340, 1, iron=3, category="Breakfast"),
    make("Overnight Oats (with fruits)", "1 bowl (250g)", 280, 10, 42, 8, 6, 60, 14, calcium=180, category="Breakfast"),
    make("Smoothie Bowl (Acai)", "1 bowl (300g)", 280, 5, 50, 7, 8, 15, 28, vitC=20, category="Breakfast"),
    make("Smoothie Bowl (Banana Peanut Butter)", "1 bowl (300g)", 350, 12, 48, 14, 6, 40, 24, potassium=500, category="Breakfast"),
    make("Protein Pancakes (2 pieces)", "2 pancakes (120g)", 240, 18, 24, 8, 2, 340, 4, category="Breakfast"),
    make("Avocado Toast (1 slice)", "1 slice (120g)", 220, 6, 22, 12, 5, 280, 2, potassium=300, category="Breakfast"),
    make("Egg White Omelette (3 whites)", "3 egg whites (100g)", 52, 11, 0.7, 0.2, 0, 166, 0.6, sel=20, category="Eggs & Dairy"),
    make("Greek Yogurt Parfait", "1 cup (250g)", 280, 14, 36, 8, 3, 60, 24, calcium=200, category="Breakfast"),
    make("Chia Seed Pudding", "1 bowl (200g)", 220, 6, 24, 12, 10, 20, 8, calcium=150, mag=80, category="Breakfast"),
    make("Tofu (Raw, 100g)", "100g", 76, 8, 1.9, 4.8, 0.3, 7, 0, calcium=350, iron=5.4, mag=30, category="Protein"),
    make("Tofu Scramble", "1 bowl (200g)", 200, 16, 8, 12, 2, 380, 2, calcium=600, iron=8, category="Protein"),
    make("Tempeh (100g)", "100g", 192, 20, 8, 11, 0, 9, 0, iron=2.7, calcium=111, mag=81, category="Protein"),
    make("Soya Chunks (Dry, 50g)", "50g dry", 170, 26, 17, 0.5, 7, 3, 0, iron=5, calcium=120, category="Protein"),
    make("Soya Milk (200ml)", "1 glass (200ml)", 80, 7, 4, 4, 0.6, 50, 2, calcium=120, vitD=1, category="Beverages"),
    make("Almond Milk (200ml)", "1 glass (200ml)", 30, 1, 1, 2.5, 0.5, 150, 0, calcium=200, vitD=1, vitE=3.3, category="Beverages"),
    make("Oat Milk (200ml)", "1 glass (200ml)", 100, 2, 16, 3, 1.5, 100, 5, calcium=240, vitD=1, category="Beverages"),
    make("Coconut Milk (200ml)", "1 glass (200ml)", 90, 0.5, 2, 9, 0, 30, 1, category="Beverages"),
]

# ============================================================
# CHICKEN PREPARATIONS - MORE
# ============================================================
new_foods += [
    make("Grilled Chicken Breast", "1 piece (150g)", 230, 43, 0, 5, 0, 380, 0, chol=120, sel=35, vitB6=0.9, category="Non-Veg"),
    make("Boiled Chicken Breast", "1 piece (150g)", 220, 42, 0, 4.5, 0, 360, 0, chol=115, category="Non-Veg"),
    make("Chicken Breast (Raw, 100g)", "100g", 120, 23, 0, 2.6, 0, 74, 0, chol=73, category="Non-Veg"),
    make("Chicken Thigh (Cooked, 1 piece)", "1 piece (100g)", 209, 26, 0, 11, 0, 84, 0, chol=105, iron=1.3, category="Non-Veg"),
    make("Chicken Wing (2 pieces, cooked)", "2 pieces (80g)", 200, 18, 0, 14, 0, 76, 0, chol=72, category="Non-Veg"),
    make("Chicken Drumstick (1 piece, cooked)", "1 piece (80g)", 160, 20, 0, 8, 0, 72, 0, chol=85, category="Non-Veg"),
    make("Butter Chicken (Restaurant Style)", "1 bowl (250g)", 480, 34, 16, 32, 2, 720, 5, category="Non-Veg Curry"),
    make("Chicken Tikka (Street Style, 8 pcs)", "8 pieces (250g)", 420, 44, 8, 22, 1, 740, 3, category="Non-Veg"),
    make("Chicken Fry (Home Style, 4 pcs)", "4 pieces (200g)", 440, 36, 16, 26, 1, 580, 2, category="Non-Veg"),
    make("Tandoori Chicken (Full)", "1 full (600g)", 840, 96, 12, 46, 2, 1400, 4, iron=8, category="Non-Veg"),
    make("Chicken Liver Fry", "1 bowl (150g)", 200, 22, 4, 10, 0.5, 420, 1, iron=8, vitA=4000, vitB12=16, folate=300, category="Non-Veg"),
]

# ============================================================
# FISH & SEAFOOD
# ============================================================
new_foods += [
    make("Salmon (Grilled, 100g)", "100g", 208, 20, 0, 13, 0, 59, 0, chol=55, sel=31, vitD=11, vitB12=2.8, category="Non-Veg"),
    make("Tuna (Canned in Water, 100g)", "100g", 116, 26, 0, 0.8, 0, 338, 0, chol=30, sel=90, vitB12=2.2, category="Non-Veg"),
    make("Pomfret (Fried, 1 piece)", "1 piece (150g)", 280, 24, 8, 18, 0, 400, 1, category="Non-Veg"),
    make("Surmai / Kingfish (Fry, 1 piece)", "1 piece (150g)", 300, 26, 8, 20, 0, 380, 1, sel=40, category="Non-Veg"),
    make("Rohu Fish Curry", "1 bowl (200g)", 260, 24, 10, 14, 2, 480, 2, category="Non-Veg Curry"),
    make("Hilsa Fish (Steamed)", "1 piece (100g)", 250, 22, 0, 18, 0, 50, 0, category="Non-Veg"),
    make("Prawns (10 pieces, cooked)", "10 pieces (100g)", 99, 24, 0.2, 0.3, 0, 111, 0, chol=189, sel=38, vitB12=1.1, category="Non-Veg"),
    make("Crab Curry", "1 bowl (200g)", 200, 20, 8, 10, 1, 500, 2, zinc=4, category="Non-Veg Curry"),
    make("Squid / Calamari (Fried)", "1 plate (150g)", 340, 18, 20, 22, 1, 520, 1, category="Non-Veg"),
    make("Fish Fingers (5 pieces)", "5 pieces (125g)", 310, 14, 24, 18, 1, 480, 1, category="Non-Veg"),
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