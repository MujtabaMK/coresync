class WeightLossTip {
  const WeightLossTip({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final String icon;
}

class WeightLossTipsData {
  static const List<WeightLossTip> lossTips = [
    WeightLossTip(
      title: 'Stay Well Hydrated',
      description:
          'Drink at least 8 glasses of water throughout the day. Water boosts '
          'your metabolism and helps curb hunger, especially when consumed '
          'before meals. Replace sugary drinks with water for an easy calorie cut.',
      icon: '\u{1F4A7}',
    ),
    WeightLossTip(
      title: 'Control Your Portions',
      description:
          'Use smaller plates and bowls to naturally reduce serving sizes. '
          'Measure out snacks instead of eating from the bag, and aim to fill '
          'half your plate with vegetables at every meal.',
      icon: '\u{1F37D}',
    ),
    WeightLossTip(
      title: 'Prioritize Quality Sleep',
      description:
          'Aim for 7 to 9 hours of sleep each night. Poor sleep disrupts '
          'hunger hormones like ghrelin and leptin, leading to increased '
          'cravings. Establish a consistent bedtime routine to improve sleep quality.',
      icon: '\u{1F634}',
    ),
    WeightLossTip(
      title: 'Eat More Protein',
      description:
          'Include a source of lean protein in every meal to stay full longer. '
          'Protein has a high thermic effect, meaning your body burns more '
          'calories digesting it. Great sources include chicken, fish, eggs, and legumes.',
      icon: '\u{1F356}',
    ),
    WeightLossTip(
      title: 'Practice Mindful Eating',
      description:
          'Slow down and pay attention to each bite without distractions. '
          'Chew thoroughly and put your fork down between bites. This helps '
          'your brain register fullness before you overeat.',
      icon: '\u{1F9D8}',
    ),
    WeightLossTip(
      title: 'Prep Meals Ahead',
      description:
          'Set aside time each week to plan and prepare healthy meals in advance. '
          'Having ready-to-eat nutritious food on hand prevents impulsive '
          'fast-food stops. Batch cooking saves both time and calories.',
      icon: '\u{1F957}',
    ),
    WeightLossTip(
      title: 'Reduce Added Sugar',
      description:
          'Read nutrition labels and limit foods with added sugars. Sugary '
          'foods spike your blood sugar and lead to energy crashes and '
          'cravings. Satisfy your sweet tooth with whole fruits instead.',
      icon: '\u{1F6AB}',
    ),
    WeightLossTip(
      title: 'Increase Fiber Intake',
      description:
          'Eat plenty of fiber-rich foods like beans, oats, and vegetables. '
          'Fiber slows digestion and keeps you feeling satisfied for hours. '
          'Aim for at least 25 grams of fiber per day for optimal results.',
      icon: '\u{1F33E}',
    ),
    WeightLossTip(
      title: 'Walk Every Day',
      description:
          'Aim for at least 10,000 steps daily to burn extra calories without '
          'intense effort. Take short walks after meals to aid digestion and '
          'regulate blood sugar. Even brief walks throughout the day add up significantly.',
      icon: '\u{1F6B6}',
    ),
    WeightLossTip(
      title: 'Manage Your Stress',
      description:
          'Chronic stress elevates cortisol, which promotes fat storage around '
          'the midsection. Practice deep breathing, meditation, or journaling '
          'to unwind. Finding healthy outlets for stress prevents emotional eating.',
      icon: '\u{1F60C}',
    ),
    WeightLossTip(
      title: 'Choose Whole Grains',
      description:
          'Replace refined grains like white bread and pasta with whole-grain '
          'alternatives. Whole grains provide more nutrients and fiber, keeping '
          'you full longer. Try brown rice, quinoa, and whole-wheat bread.',
      icon: '\u{1F35E}',
    ),
    WeightLossTip(
      title: 'Avoid Processed Foods',
      description:
          'Processed foods are often loaded with hidden calories, sodium, and '
          'unhealthy fats. Focus on whole, single-ingredient foods as much as '
          'possible. Cooking at home gives you full control over what you eat.',
      icon: '\u{1F6D2}',
    ),
    WeightLossTip(
      title: 'Eat At Regular Times',
      description:
          'Stick to a consistent meal schedule to keep your metabolism steady. '
          'Skipping meals often leads to overeating later in the day. Plan '
          'three balanced meals and one or two small snacks each day.',
      icon: '\u{23F0}',
    ),
    WeightLossTip(
      title: 'Track Your Calories',
      description:
          'Use a food diary or tracking app to log what you eat each day. '
          'Awareness of your calorie intake reveals patterns and hidden '
          'sources of excess calories. Tracking consistently is one of the strongest predictors of weight loss success.',
      icon: '\u{1F4CA}',
    ),
    WeightLossTip(
      title: 'Add Strength Training',
      description:
          'Incorporate resistance exercises at least two to three times per '
          'week. Building muscle increases your resting metabolic rate, so you '
          'burn more calories even at rest. Start with bodyweight exercises if you are new to lifting.',
      icon: '\u{1F4AA}',
    ),
    WeightLossTip(
      title: 'Load Up On Vegetables',
      description:
          'Fill at least half your plate with non-starchy vegetables at every '
          'meal. Vegetables are low in calories but high in volume, fiber, and '
          'essential nutrients. They help you feel full without adding excess calories.',
      icon: '\u{1F966}',
    ),
    WeightLossTip(
      title: 'Snack Smart Always',
      description:
          'Keep healthy snacks like nuts, yogurt, and cut-up fruit within easy '
          'reach. Pre-portioning snacks prevents mindless overeating. Pairing '
          'protein with fiber in your snacks keeps energy levels stable between meals.',
      icon: '\u{1F34E}',
    ),
    WeightLossTip(
      title: 'Stay Patient And Consistent',
      description:
          'Sustainable weight loss happens gradually at one to two pounds per '
          'week. Focus on building lasting habits rather than chasing quick '
          'fixes. Celebrate small victories and trust the process over time.',
      icon: '\u{1F3AF}',
    ),
  ];

  // Backward compat alias
  static const List<WeightLossTip> tips = lossTips;

  static const List<WeightLossTip> gainTips = [
    WeightLossTip(
      title: 'Eat in a Calorie Surplus',
      description:
          'Consume 300 to 500 calories more than your TDEE each day to gain '
          'weight steadily. Track your intake to ensure you are consistently '
          'eating enough. A controlled surplus minimizes excess fat gain.',
      icon: '\u{1F4AA}',
    ),
    WeightLossTip(
      title: 'Prioritize Protein Intake',
      description:
          'Eat 1.6 to 2.2 grams of protein per kilogram of body weight daily. '
          'Protein is the building block of muscle and essential for recovery. '
          'Include sources like chicken, eggs, paneer, dal, and whey protein.',
      icon: '\u{1F356}',
    ),
    WeightLossTip(
      title: 'Eat More Frequently',
      description:
          'Instead of 3 large meals, eat 5 to 6 smaller meals throughout the day. '
          'This makes it easier to consume enough calories without feeling overly '
          'full. Add snacks between main meals for extra energy.',
      icon: '\u{23F0}',
    ),
    WeightLossTip(
      title: 'Lift Heavy Weights',
      description:
          'Focus on compound exercises like squats, deadlifts, bench press, and '
          'rows. Progressive overload stimulates muscle growth and ensures your '
          'surplus calories go toward building muscle, not just fat.',
      icon: '\u{1F3CB}',
    ),
    WeightLossTip(
      title: 'Choose Calorie-Dense Foods',
      description:
          'Pick nutrient-rich foods that pack more calories per bite such as nuts, '
          'nut butters, dried fruits, avocado, cheese, and whole milk. These make '
          'it easier to hit your calorie target without excessive volume.',
      icon: '\u{1F95C}',
    ),
    WeightLossTip(
      title: 'Drink Your Calories',
      description:
          'Shakes and smoothies are an easy way to add extra calories. Blend milk, '
          'banana, oats, peanut butter, and protein powder for a high-calorie '
          'shake. Drink between meals to supplement your food intake.',
      icon: '\u{1F964}',
    ),
    WeightLossTip(
      title: 'Stay Consistent with Training',
      description:
          'Train each muscle group at least twice a week for optimal growth. '
          'Follow a structured program and track your progress. Consistency in '
          'the gym combined with proper nutrition yields the best results.',
      icon: '\u{1F4C5}',
    ),
    WeightLossTip(
      title: 'Get Enough Sleep',
      description:
          'Muscle growth and recovery happen primarily during sleep. Aim for 7 to '
          '9 hours each night. Poor sleep reduces testosterone and growth hormone '
          'levels, both crucial for muscle building.',
      icon: '\u{1F634}',
    ),
    WeightLossTip(
      title: 'Include Healthy Carbs',
      description:
          'Carbohydrates fuel your workouts and replenish glycogen stores. Eat '
          'complex carbs like rice, oats, sweet potatoes, and whole wheat roti. '
          'Time your carbs around your workouts for maximum performance.',
      icon: '\u{1F35E}',
    ),
    WeightLossTip(
      title: 'Use Creatine Supplement',
      description:
          'Creatine monohydrate is one of the most researched and effective '
          'supplements for muscle gain. Take 3 to 5 grams daily to improve '
          'strength and muscle volume. It is safe for long-term use.',
      icon: '\u{1F4CA}',
    ),
    WeightLossTip(
      title: 'Add Healthy Fats',
      description:
          'Fats are calorie-dense at 9 calories per gram. Include ghee, olive oil, '
          'coconut oil, and nuts in your meals. Healthy fats also support hormone '
          'production essential for muscle growth.',
      icon: '\u{1FAD2}',
    ),
    WeightLossTip(
      title: 'Track Your Progress',
      description:
          'Weigh yourself weekly and take body measurements to monitor gains. '
          'If the scale is not moving, increase your calorie intake by 200 to 300 '
          'calories. Adjust your plan based on results, not feelings.',
      icon: '\u{1F4CF}',
    ),
    WeightLossTip(
      title: 'Avoid Excessive Cardio',
      description:
          'Too much cardio burns calories you need for muscle growth. Limit '
          'cardio to 2 to 3 light sessions per week for heart health. Focus most '
          'of your training energy on resistance exercises.',
      icon: '\u{1F6B6}',
    ),
    WeightLossTip(
      title: 'Eat Before Bed',
      description:
          'Have a protein-rich snack before sleep like Greek yogurt, cottage cheese, '
          'or a casein shake. This provides your muscles with amino acids during '
          'the overnight fasting period for better recovery.',
      icon: '\u{1F319}',
    ),
    WeightLossTip(
      title: 'Stay Hydrated',
      description:
          'Water is essential for nutrient transport and muscle function. Drink '
          'at least 3 to 4 liters per day, more on training days. Dehydration can '
          'reduce strength and impair recovery.',
      icon: '\u{1F4A7}',
    ),
    WeightLossTip(
      title: 'Be Patient and Persistent',
      description:
          'Healthy weight gain takes time. Aim for 0.25 to 0.5 kg per week to '
          'minimize fat gain. Building quality muscle is a marathon, not a sprint. '
          'Trust the process and stay committed.',
      icon: '\u{1F3AF}',
    ),
  ];

  static const List<WeightLossTip> maintainTips = [
    WeightLossTip(
      title: 'Eat at Maintenance Calories',
      description:
          'Consume calories equal to your TDEE to maintain your current weight. '
          'Use a food tracker to stay aware of your intake. Small daily '
          'fluctuations are normal, focus on weekly averages.',
      icon: '\u{2696}',
    ),
    WeightLossTip(
      title: 'Stay Active Daily',
      description:
          'Continue regular exercise to maintain muscle mass and fitness levels. '
          'Mix strength training with cardio for overall health. Aim for at least '
          '150 minutes of moderate activity per week.',
      icon: '\u{1F3C3}',
    ),
    WeightLossTip(
      title: 'Keep Eating Balanced Meals',
      description:
          'Fill your plate with a good balance of protein, carbs, and healthy fats. '
          'Include plenty of vegetables and fruits for micronutrients. A balanced '
          'diet keeps energy levels steady throughout the day.',
      icon: '\u{1F37D}',
    ),
    WeightLossTip(
      title: 'Monitor Your Weight Weekly',
      description:
          'Weigh yourself once a week at the same time for consistency. If your '
          'weight drifts up or down by more than 1 to 2 kg, adjust your calories '
          'slightly. Early correction prevents larger swings.',
      icon: '\u{1F4CA}',
    ),
    WeightLossTip(
      title: 'Maintain Good Sleep Habits',
      description:
          'Continue getting 7 to 9 hours of quality sleep each night. Sleep '
          'regulates appetite hormones and supports recovery. A consistent sleep '
          'schedule is one of the best tools for weight maintenance.',
      icon: '\u{1F634}',
    ),
    WeightLossTip(
      title: 'Practice Mindful Eating',
      description:
          'Stay connected to hunger and fullness cues even after reaching your '
          'goal. Eat without distractions and enjoy each meal. Mindful eating '
          'prevents gradual overeating that leads to weight regain.',
      icon: '\u{1F9D8}',
    ),
    WeightLossTip(
      title: 'Keep Healthy Routines',
      description:
          'The habits that got you here will keep you here. Continue meal prepping, '
          'staying hydrated, and exercising regularly. Consistency is the key to '
          'long-term weight maintenance.',
      icon: '\u{1F504}',
    ),
    WeightLossTip(
      title: 'Allow Flexibility',
      description:
          'Enjoy occasional treats without guilt as part of a balanced lifestyle. '
          'The 80/20 rule works well: eat nutritious foods 80 percent of the time. '
          'Restriction often backfires, so be kind to yourself.',
      icon: '\u{1F389}',
    ),
    WeightLossTip(
      title: 'Manage Stress Levels',
      description:
          'Chronic stress can trigger emotional eating and weight fluctuations. '
          'Practice relaxation techniques like deep breathing or meditation. '
          'Find healthy outlets for stress to protect your progress.',
      icon: '\u{1F60C}',
    ),
    WeightLossTip(
      title: 'Stay Hydrated Always',
      description:
          'Continue drinking plenty of water throughout the day. Proper hydration '
          'supports metabolism, digestion, and overall well-being. Aim for at '
          'least 8 glasses daily.',
      icon: '\u{1F4A7}',
    ),
  ];
}
