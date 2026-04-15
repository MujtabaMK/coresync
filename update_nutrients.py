#!/usr/bin/env python3
"""Script to add micronutrient values to food items in common_foods_data.dart"""

import re

FILE_PATH = '/Users/mujtabakhan/StudioProjects/coresync/lib/features/gym/data/common_foods_data.dart'

# Map of food name -> (fiber, sodium, sugar, cholesterol, iron, calcium, potassium)
# fiber(g), sodium(mg), sugar(g), cholesterol(mg), iron(mg), calcium(mg), potassium(mg)
# Note: for items that already have fiber, we keep their existing fiber value

nutrients = {
    # ── Vegetables (cooked) ──
    'Aloo Gobi': (3.0, 380.0, 3.5, 0.0, 1.2, 40.0, 350.0),
    'Bhindi / Okra Fry': (3.0, 320.0, 2.5, 0.0, 1.0, 110.0, 280.0),
    'Palak Paneer': (3.0, 480.0, 3.0, 30.0, 3.5, 350.0, 520.0),
    'Baingan Bharta': (4.0, 360.0, 4.0, 0.0, 0.8, 30.0, 300.0),
    'Mix Veg Curry': (4.0, 400.0, 4.0, 0.0, 1.5, 55.0, 380.0),
    'Aloo Matar': (4.0, 390.0, 4.5, 0.0, 1.4, 35.0, 360.0),
    'Paneer Butter Masala': (1.5, 520.0, 5.0, 45.0, 1.0, 280.0, 260.0),
    'Shahi Paneer': (1.5, 490.0, 4.5, 40.0, 1.2, 300.0, 250.0),
    'Matar Paneer': (3.0, 450.0, 4.0, 30.0, 1.5, 260.0, 320.0),
    'Malai Kofta': (2.0, 500.0, 5.0, 35.0, 1.2, 180.0, 280.0),
    'Kadhi Pakora': (1.5, 420.0, 3.5, 5.0, 0.8, 120.0, 220.0),
    'Chana Masala': (7.0, 480.0, 5.0, 0.0, 3.2, 65.0, 420.0),
    'Mushroom Masala': (2.0, 380.0, 3.0, 0.0, 1.5, 20.0, 350.0),
    'Boiled Vegetables': (3.5, 30.0, 4.0, 0.0, 1.0, 40.0, 280.0),
    'Salad (green, no dressing)': (2.5, 20.0, 2.5, 0.0, 1.2, 45.0, 260.0),
    'Raita (cucumber)': (0.5, 280.0, 5.0, 12.0, 0.3, 120.0, 200.0),
    'Aloo Jeera': (2.5, 350.0, 2.0, 0.0, 1.0, 25.0, 420.0),
    'Gobi Manchurian': (3.0, 680.0, 6.0, 0.0, 1.0, 35.0, 280.0),
    'Baby Corn Masala': (3.0, 400.0, 3.5, 0.0, 0.8, 30.0, 250.0),
    'Tinda Masala': (2.5, 340.0, 3.0, 0.0, 0.6, 30.0, 220.0),
    'Lauki / Bottle Gourd Curry': (2.0, 320.0, 3.5, 0.0, 0.5, 30.0, 240.0),
    'Karela / Bitter Gourd Fry': (3.0, 300.0, 1.5, 0.0, 0.8, 25.0, 320.0),
    'Stuffed Capsicum': (3.0, 350.0, 4.0, 0.0, 1.0, 20.0, 280.0),
    'Bhindi Masala': (3.5, 340.0, 3.0, 0.0, 1.2, 120.0, 300.0),
    'Sem ki Phali': (4.0, 310.0, 3.0, 0.0, 1.5, 50.0, 320.0),
    'Gajar Matar': (4.5, 340.0, 6.0, 0.0, 1.0, 45.0, 350.0),
    'Dum Aloo': (2.5, 440.0, 3.5, 0.0, 1.2, 30.0, 420.0),
    'Kaju Curry': (1.5, 420.0, 5.0, 15.0, 1.8, 50.0, 280.0),
    'Navratan Korma': (3.0, 460.0, 6.0, 20.0, 1.5, 100.0, 320.0),
    'Aloo Palak': (3.5, 380.0, 2.5, 0.0, 3.0, 120.0, 450.0),
    'Aloo Patta Gobi': (3.5, 370.0, 3.5, 0.0, 1.0, 50.0, 340.0),
    'Beans Aloo Sabzi': (4.0, 340.0, 3.0, 0.0, 1.4, 50.0, 340.0),
    'Paneer Sabzi (dry)': (1.5, 350.0, 2.5, 30.0, 0.8, 280.0, 180.0),
    'Aloo Sabzi (dry)': (3.0, 360.0, 2.0, 0.0, 1.0, 20.0, 400.0),
    'Paneer Tomato Sabzi': (2.5, 420.0, 4.0, 35.0, 1.0, 290.0, 280.0),
    'Tori / Ridge Gourd Sabzi': (3.0, 300.0, 3.5, 0.0, 0.6, 35.0, 240.0),
    'Parwal Sabzi': (3.0, 310.0, 3.0, 0.0, 0.7, 35.0, 260.0),
    'Chana Sabzi (Dry)': (6.0, 380.0, 4.0, 0.0, 2.8, 55.0, 380.0),
    'Kaddu / Pumpkin Sabzi': (3.0, 300.0, 5.5, 0.0, 0.8, 35.0, 340.0),
    'Raw Banana Sabzi (Kache Kele)': (3.0, 330.0, 2.0, 0.0, 0.8, 20.0, 480.0),
    'Arbi / Colocasia Sabzi': (3.5, 340.0, 2.0, 0.0, 0.9, 50.0, 480.0),
    'Methi Sabzi (Dry)': (4.0, 300.0, 1.5, 0.0, 2.5, 80.0, 310.0),
    'Sarson ka Saag': (4.0, 350.0, 2.0, 0.0, 3.2, 180.0, 420.0),
    'Saag (Mixed Greens)': (4.0, 340.0, 2.0, 0.0, 3.0, 160.0, 400.0),
    'Palak Sabzi': (3.5, 330.0, 1.5, 0.0, 3.8, 200.0, 460.0),
    'Paneer Do Pyaza': (2.0, 460.0, 4.5, 35.0, 1.0, 280.0, 260.0),
    'Paneer Tikka Masala': (2.0, 500.0, 4.0, 40.0, 1.2, 310.0, 270.0),
    'Kadhai Paneer': (2.0, 470.0, 3.5, 38.0, 1.2, 300.0, 280.0),
    'Veg Kolhapuri': (3.0, 450.0, 4.0, 0.0, 1.5, 50.0, 350.0),
    'Aloo Methi': (3.5, 360.0, 2.0, 0.0, 2.2, 60.0, 380.0),
    'Bharwa Bhindi (Stuffed Okra)': (3.0, 330.0, 2.5, 0.0, 1.0, 100.0, 270.0),

    # ── Non-Veg Curries ──
    'Chicken Breast (grilled)': (0.0, 70.0, 0.0, 85.0, 1.0, 15.0, 320.0),
    'Chicken Curry': (1.0, 520.0, 3.0, 90.0, 1.5, 30.0, 310.0),
    'Butter Chicken': (1.0, 580.0, 5.0, 95.0, 1.5, 55.0, 300.0),
    'Chicken Tikka': (0.5, 450.0, 1.5, 100.0, 1.8, 20.0, 340.0),
    'Tandoori Chicken': (0.5, 480.0, 1.0, 80.0, 1.5, 18.0, 280.0),
    'Egg Curry': (1.0, 480.0, 3.5, 380.0, 2.0, 65.0, 250.0),
    'Fish Curry': (1.0, 450.0, 2.5, 55.0, 1.2, 40.0, 380.0),
    'Fish Fry': (0.5, 350.0, 1.0, 50.0, 1.0, 25.0, 280.0),
    'Mutton Curry': (1.0, 520.0, 3.0, 95.0, 3.0, 25.0, 340.0),
    'Mutton Keema': (1.0, 500.0, 2.5, 100.0, 3.2, 20.0, 330.0),
    'Prawns / Shrimp Curry': (1.0, 550.0, 2.5, 170.0, 2.5, 80.0, 280.0),
    'Chicken 65': (0.5, 620.0, 3.0, 85.0, 1.5, 20.0, 280.0),
    'Chicken Fried Rice': (1.5, 680.0, 2.0, 75.0, 1.5, 25.0, 250.0),
    'Chicken Momos': (1.0, 480.0, 1.5, 55.0, 1.2, 20.0, 200.0),
    'Chicken Korma': (1.5, 540.0, 4.0, 90.0, 1.5, 60.0, 300.0),
    'Chicken Biryani (plate)': (2.0, 720.0, 3.0, 85.0, 2.0, 40.0, 350.0),
    'Mutton Biryani': (2.0, 750.0, 3.0, 95.0, 2.8, 35.0, 380.0),
    'Chicken Seekh Kebab': (0.5, 420.0, 1.0, 80.0, 1.5, 15.0, 260.0),
    'Chicken Malai Tikka': (0.5, 430.0, 1.5, 95.0, 1.2, 30.0, 310.0),
    'Fish Tikka': (0.5, 380.0, 1.0, 55.0, 1.0, 25.0, 340.0),
    'Bombay Duck Fry': (0.5, 420.0, 1.5, 60.0, 1.2, 30.0, 250.0),
    'Crab Curry': (1.0, 580.0, 2.5, 80.0, 1.5, 90.0, 320.0),
    'Chicken Shawarma Plate': (2.0, 780.0, 4.0, 80.0, 2.0, 40.0, 350.0),
    'Chicken Lollipop': (0.5, 550.0, 3.0, 70.0, 1.2, 18.0, 220.0),
    'Chicken Manchurian': (1.0, 720.0, 5.0, 80.0, 1.5, 25.0, 270.0),
    'Keema Pav': (2.0, 650.0, 4.0, 95.0, 3.0, 40.0, 350.0),
    'Mutton Rogan Josh': (1.5, 530.0, 3.0, 100.0, 3.2, 25.0, 350.0),
    'Butter Fish': (0.5, 420.0, 2.0, 65.0, 1.0, 35.0, 360.0),
    'Beef Curry': (1.0, 500.0, 2.5, 80.0, 2.8, 20.0, 320.0),
    'Fried Rohu Fish': (0.5, 320.0, 1.0, 55.0, 1.0, 30.0, 290.0),
    'Kadai Chicken': (1.5, 510.0, 3.0, 90.0, 1.5, 25.0, 300.0),
    'Chicken Crispy': (0.5, 580.0, 2.0, 75.0, 1.2, 18.0, 240.0),
    'Chicken Rezala': (1.0, 490.0, 3.0, 90.0, 1.5, 40.0, 280.0),
    'Goan Fish Curry': (1.5, 480.0, 3.0, 55.0, 1.2, 35.0, 350.0),
    'Fish Fry (Pomfret)': (0.5, 380.0, 1.0, 60.0, 1.0, 30.0, 320.0),
    'Egg Fried Rice': (1.5, 650.0, 2.0, 190.0, 1.5, 35.0, 220.0),
    'Seekh Kebab (Mutton)': (0.5, 450.0, 1.0, 90.0, 2.8, 15.0, 280.0),
    'Shammi Kebab': (1.0, 380.0, 1.5, 75.0, 2.0, 20.0, 220.0),
    'Nihari': (1.0, 560.0, 2.5, 95.0, 3.5, 30.0, 350.0),
    'Paya (Trotters Curry)': (0.5, 520.0, 1.5, 80.0, 2.5, 40.0, 280.0),
    'Haleem': (4.0, 620.0, 3.0, 75.0, 3.0, 45.0, 380.0),
    'Meen Pollichathu (Kerala)': (1.0, 440.0, 2.0, 60.0, 1.2, 30.0, 350.0),
    'Dragon Chicken': (1.0, 700.0, 5.0, 85.0, 1.5, 22.0, 270.0),
    'Chicken Chap': (0.5, 470.0, 2.5, 85.0, 1.2, 25.0, 260.0),
    'Mutton Do Pyaza': (2.0, 510.0, 3.5, 95.0, 3.0, 25.0, 330.0),
    'Chicken Do Pyaza': (2.0, 480.0, 3.5, 85.0, 1.5, 25.0, 290.0),
    'Prawn Fry': (0.5, 450.0, 1.0, 150.0, 2.0, 60.0, 220.0),
    'Hyderabadi Chicken Fry': (0.5, 550.0, 2.0, 90.0, 1.5, 20.0, 290.0),
    'Chicken Afghani': (0.5, 460.0, 1.5, 95.0, 1.2, 30.0, 300.0),
    'Mutton Boti Kebab': (0.5, 430.0, 1.0, 95.0, 2.8, 18.0, 300.0),
    'Chicken Wings (fried)': (0.5, 650.0, 2.0, 110.0, 1.5, 25.0, 280.0),
    'Chicken Popcorn': (0.5, 600.0, 2.5, 70.0, 1.2, 18.0, 220.0),
    'Tandoori Fish': (0.5, 400.0, 1.0, 55.0, 1.0, 25.0, 330.0),
    'Egg Masala Curry': (1.5, 500.0, 3.5, 390.0, 2.2, 70.0, 260.0),
    'Chicken Gravy': (1.0, 510.0, 3.0, 85.0, 1.5, 25.0, 300.0),
    'Mutton Nihari': (1.0, 580.0, 2.5, 100.0, 3.5, 30.0, 360.0),
    'Fish Fingers (fried)': (0.5, 480.0, 1.5, 45.0, 1.0, 20.0, 220.0),

    # ── Snacks & Street Food ──
    'Samosa': (1.5, 320.0, 2.0, 0.0, 1.0, 15.0, 150.0),
    'Pakora / Bhajiya': (1.5, 350.0, 1.5, 0.0, 1.0, 20.0, 140.0),
    'Vada Pav': (2.0, 450.0, 3.0, 0.0, 1.2, 25.0, 200.0),
    'Pav Bhaji': (4.0, 580.0, 5.0, 10.0, 2.0, 50.0, 350.0),
    'Pani Puri / Golgappa': (1.5, 480.0, 4.0, 0.0, 0.8, 15.0, 120.0),
    'Bhel Puri': (2.0, 420.0, 4.0, 0.0, 1.0, 20.0, 150.0),
    'Sev Puri': (1.5, 450.0, 3.5, 0.0, 0.8, 18.0, 130.0),
    'Dahi Puri': (1.5, 380.0, 5.0, 8.0, 0.8, 50.0, 160.0),
    'Kachori': (1.5, 340.0, 2.0, 0.0, 1.0, 15.0, 120.0),
    'Spring Roll (veg)': (1.5, 380.0, 2.0, 0.0, 0.8, 15.0, 130.0),
    'Veg Momos': (2.0, 420.0, 2.0, 0.0, 1.0, 25.0, 180.0),
    'Aloo Tikki': (1.5, 350.0, 2.0, 0.0, 0.8, 15.0, 220.0),
    'Dhokla': (1.5, 380.0, 3.0, 0.0, 1.2, 30.0, 150.0),
    'Khandvi': (1.0, 320.0, 2.5, 0.0, 0.8, 25.0, 120.0),
    'Maggi Noodles': (1.5, 860.0, 2.0, 0.0, 1.5, 20.0, 100.0),
    'Chips / Wafers': (1.0, 280.0, 0.5, 0.0, 0.5, 10.0, 150.0),
    'Biscuits (Marie)': (0.5, 180.0, 6.0, 0.0, 0.8, 15.0, 40.0),
    'Biscuits (cream)': (0.3, 120.0, 8.0, 2.0, 0.5, 10.0, 30.0),
    'Namkeen / Mixture': (1.5, 350.0, 1.5, 0.0, 0.8, 15.0, 100.0),
    'Makhana (roasted)': (1.5, 5.0, 0.5, 0.0, 0.5, 20.0, 85.0),
    'Murmura / Puffed Rice': (0.5, 2.0, 0.3, 0.0, 0.5, 5.0, 30.0),
    'Bread Pakora': (1.5, 400.0, 2.5, 0.0, 1.0, 20.0, 120.0),
    'Paneer Pakora': (1.0, 380.0, 2.0, 25.0, 0.8, 150.0, 140.0),
    'Corn Chaat': (3.0, 350.0, 4.0, 0.0, 0.8, 10.0, 220.0),
    'Aloo Chaat': (2.5, 420.0, 3.5, 0.0, 0.8, 15.0, 280.0),
    'Papdi Chaat': (2.0, 480.0, 5.0, 5.0, 1.0, 30.0, 180.0),
    'Raj Kachori': (2.0, 520.0, 5.0, 5.0, 1.2, 35.0, 200.0),
    'Dabeli': (2.0, 450.0, 4.0, 0.0, 1.2, 30.0, 200.0),
    'Misal (snack)': (6.0, 550.0, 3.0, 0.0, 2.5, 45.0, 350.0),
    'Ragda Pattice': (4.0, 480.0, 4.0, 0.0, 2.0, 35.0, 300.0),
    'Frankie / Kathi Roll': (2.0, 500.0, 3.0, 0.0, 1.5, 30.0, 200.0),
    'Cutlet (Veg)': (2.0, 350.0, 2.0, 0.0, 1.0, 20.0, 180.0),
    'Cutlet (Chicken)': (1.0, 380.0, 1.5, 40.0, 1.0, 15.0, 180.0),
    'Masala Vada': (6.1, 380.0, 2.0, 0.0, 2.0, 30.0, 250.0),
    'Dahi Bhalla / Dahi Vada': (2.5, 420.0, 5.0, 8.0, 1.2, 60.0, 200.0),
    'Bhutta / Roasted Corn': (2.7, 15.0, 3.2, 0.0, 0.5, 5.0, 270.0),
    'Bhujia Namkeen': (1.0, 320.0, 1.0, 0.0, 0.8, 12.0, 80.0),
    'Aloo Pakora': (2.0, 380.0, 1.5, 0.0, 0.8, 15.0, 220.0),
    'Batata Vada': (2.5, 400.0, 2.0, 0.0, 1.0, 20.0, 250.0),
    'Gujarati Gathiya': (1.5, 280.0, 1.0, 0.0, 1.0, 15.0, 80.0),
    'Dal Vada': (3.0, 340.0, 1.5, 0.0, 1.5, 25.0, 200.0),
    'Chana Dal Vada': (3.5, 350.0, 1.5, 0.0, 1.8, 28.0, 220.0),
    'Litti Chokha': (5.0, 580.0, 3.0, 0.0, 2.5, 40.0, 350.0),
    'Samosa Pav': (3.0, 480.0, 3.0, 0.0, 1.5, 25.0, 200.0),
    'Jhal Muri': (2.5, 450.0, 2.0, 0.0, 1.0, 15.0, 150.0),
    'Churmuri / Churumuri': (2.0, 420.0, 2.0, 0.0, 0.8, 12.0, 140.0),
    'Pyaaz Kachori': (1.5, 360.0, 2.0, 0.0, 1.0, 12.0, 100.0),
    'Onion Bhajiya / Kanda Bhaji': (2.5, 400.0, 3.0, 0.0, 1.2, 30.0, 180.0),
    'Palak Pakoda': (2.0, 350.0, 1.5, 0.0, 1.5, 55.0, 180.0),
    'Methi Pakoda': (2.5, 340.0, 1.0, 0.0, 1.8, 40.0, 170.0),
    'Banana Fritters / Pazham Pori': (1.5, 150.0, 12.0, 0.0, 0.5, 10.0, 180.0),
    'Sundal (Chana)': (5.0, 280.0, 3.0, 0.0, 2.5, 50.0, 300.0),
    'Ribbon Murukku': (1.0, 250.0, 1.0, 0.0, 0.5, 10.0, 50.0),
    'Boiled Chana Chaat': (9.0, 320.0, 4.0, 0.0, 3.0, 60.0, 400.0),
    'Sprouts Salad': (5.0, 120.0, 2.5, 0.0, 2.0, 35.0, 320.0),
    'Sprouts Chaat': (5.0, 250.0, 3.0, 0.0, 2.2, 35.0, 330.0),
    'Boiled Egg Salad': (2.0, 350.0, 2.0, 370.0, 1.8, 60.0, 250.0),
    'Chole Kulche': (7.0, 680.0, 5.0, 0.0, 3.5, 70.0, 420.0),
    'Chicken Kathi Roll': (2.0, 520.0, 2.5, 60.0, 1.5, 25.0, 240.0),
    'Protein Bar': (3.0, 200.0, 8.0, 5.0, 2.5, 100.0, 200.0),
    'Khakhra': (2.0, 280.0, 1.0, 0.0, 1.0, 15.0, 80.0),
    'Fafda': (1.5, 350.0, 1.0, 0.0, 1.2, 18.0, 80.0),
    'Mathri': (1.0, 300.0, 1.5, 0.0, 0.8, 12.0, 60.0),
    'Shakarpara': (0.5, 180.0, 10.0, 0.0, 0.5, 10.0, 40.0),
    'Chakli': (1.0, 260.0, 1.0, 0.0, 0.6, 10.0, 50.0),
    'Shev / Sev': (1.0, 300.0, 1.0, 0.0, 0.8, 12.0, 70.0),
    'Egg Puff': (1.0, 380.0, 2.0, 80.0, 1.0, 25.0, 100.0),
    'Paneer Puff': (1.0, 360.0, 2.0, 20.0, 0.8, 80.0, 100.0),
    'Veg Puff': (1.5, 340.0, 2.0, 0.0, 0.8, 15.0, 100.0),
    'Chicken Puff': (1.0, 400.0, 2.0, 35.0, 1.0, 18.0, 120.0),
    'Veg Sandwich (grilled)': (3.0, 420.0, 3.0, 0.0, 1.2, 30.0, 200.0),
    'Cheese Sandwich (grilled)': (1.5, 520.0, 2.5, 30.0, 0.8, 150.0, 130.0),
    'Bombay Sandwich': (3.0, 450.0, 3.5, 0.0, 1.2, 30.0, 220.0),

    # ── Nuts & Seeds ──
    'Almonds': (1.7, 0.0, 0.6, 0.0, 0.5, 37.0, 100.0),
    'Soaked Almonds (Badam)': (1.7, 0.0, 0.6, 0.0, 0.5, 37.0, 100.0),
    'Soaked Anjeer (Figs)': (2.5, 3.0, 12.0, 0.0, 0.6, 48.0, 190.0),
    'Soaked Kishmish (Raisins)': (0.6, 4.0, 10.0, 0.0, 0.3, 8.0, 115.0),
    'Soaked Munakka (Black Raisins)': (0.7, 4.0, 9.0, 0.0, 0.3, 8.0, 110.0),
    'Soaked Walnuts (Akhrot)': (1.0, 0.0, 0.4, 0.0, 0.4, 14.0, 62.0),
    'Soaked Cashews (Kaju)': (0.5, 2.0, 0.9, 0.0, 1.0, 6.0, 100.0),
    'Soaked Dates (Khajoor)': (1.5, 1.0, 15.0, 0.0, 0.2, 15.0, 167.0),
    'Walnuts': (1.0, 0.0, 0.4, 0.0, 0.4, 15.0, 66.0),
    'Cashews': (0.5, 2.0, 0.9, 0.0, 1.0, 6.0, 100.0),
    'Peanuts (roasted)': (2.5, 5.0, 1.4, 0.0, 1.6, 26.0, 245.0),
    'Pistachios': (1.5, 1.0, 1.1, 0.0, 0.6, 16.0, 152.0),
    'Flax Seeds': (2.8, 3.0, 0.2, 0.0, 0.6, 26.0, 81.0),
    'Chia Seeds': (4.1, 2.0, 0.0, 0.0, 0.9, 76.0, 48.0),
    'Sunflower Seeds': (1.7, 2.0, 0.5, 0.0, 1.1, 16.0, 130.0),
    'Pumpkin Seeds': (1.0, 4.0, 0.3, 0.0, 1.7, 9.0, 168.0),
    'Mixed Dry Fruits': (1.5, 3.0, 4.0, 0.0, 0.8, 25.0, 150.0),
    'Raisins / Kishmish': (0.8, 5.0, 13.0, 0.0, 0.4, 10.0, 150.0),
    'Dried Apricot': (1.5, 2.0, 9.0, 0.0, 0.5, 11.0, 120.0),
    'Pine Nuts': (0.7, 0.0, 0.7, 0.0, 1.1, 3.0, 122.0),
    'Brazil Nuts': (1.1, 0.0, 0.4, 0.0, 0.4, 24.0, 99.0),
    'Macadamia Nuts': (1.3, 1.0, 0.7, 0.0, 0.6, 13.0, 56.0),
    'Trail Mix': (2.0, 45.0, 5.0, 0.0, 1.0, 22.0, 175.0),
    'Chikki / Peanut Bar': (1.0, 15.0, 9.0, 0.0, 0.6, 12.0, 100.0),
}

with open(FILE_PATH, 'r') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []

for line in lines:
    modified = False
    for food_name, (fiber, sodium, sugar, cholesterol, iron, calcium, potassium) in nutrients.items():
        # Check if this line contains this food item
        search_str = f"name: '{food_name}'"
        if search_str in line:
            # Check if sodium is already present (already has micronutrients)
            if 'sodium:' in line:
                new_lines.append(line)
                modified = True
                break

            # Determine if fiber already exists in the line
            has_fiber = 'fiber:' in line

            # Build the micronutrient string to insert
            if has_fiber:
                # Insert sodium, sugar, cholesterol, iron, calcium, potassium after the existing fiber value
                # Find "fiber: X.X, category:" or "fiber: X.X, category:"
                # Replace "category:" with "sodium: X, sugar: X, ... category:"
                micro_str = f"sodium: {sodium}, sugar: {sugar}, cholesterol: {cholesterol}, iron: {iron}, calcium: {calcium}, potassium: {potassium}, "
                line = line.replace("category:", micro_str + "category:")
            else:
                # Insert fiber and all micronutrients before category:
                micro_str = f"fiber: {fiber}, sodium: {sodium}, sugar: {sugar}, cholesterol: {cholesterol}, iron: {iron}, calcium: {calcium}, potassium: {potassium}, "
                line = line.replace("category:", micro_str + "category:")

            new_lines.append(line)
            modified = True
            break

    if not modified:
        new_lines.append(line)

with open(FILE_PATH, 'w') as f:
    f.write('\n'.join(new_lines))

print(f"Done! Processed {len(nutrients)} food items.")
