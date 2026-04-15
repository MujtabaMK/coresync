/// Maps food-name keywords to extra water (ml) the user should drink.
/// Only supplements and specific foods that require extra hydration.
/// Protein shake and BCAA/EAA are already liquid — no extra needed.
const List<({List<String> keywords, int boostMl, String reason})>
    waterBoostFoods = [
  (
    keywords: ['whey', 'casein', 'protein powder'],
    boostMl: 500,
    reason: 'Whey protein needs extra hydration',
  ),
  (
    keywords: ['mass gainer'],
    boostMl: 500,
    reason: 'High protein + carb load',
  ),
  (
    keywords: ['pre-workout', 'pre workout'],
    boostMl: 350,
    reason: 'Caffeine + stimulant combo',
  ),
  (
    keywords: ['creatine'],
    boostMl: 300,
    reason: 'Pulls water into muscles',
  ),
  (
    keywords: ['chia', 'sabja', 'basil seed'],
    boostMl: 300,
    reason: 'Seeds absorb 10-12x weight in water',
  ),
  (
    keywords: ['psyllium', 'isabgol', 'metamucil'],
    boostMl: 300,
    reason: 'Fiber needs water to form gel',
  ),
  (
    keywords: ['protein bar', 'max protein', 'whole truth'],
    boostMl: 100,
    reason: 'Solid protein bar needs hydration',
  ),
  // Protein shake → 0 (already liquid, no extra needed)
  // BCAA / EAA   → 0 (mixed with water, counts as normal intake)
];

/// Returns the water boost in ml for a single food name.
/// Returns 0 if no keyword matches.
int waterBoostForFood(String foodName) {
  final lower = foodName.toLowerCase();
  for (final entry in waterBoostFoods) {
    for (final keyword in entry.keywords) {
      if (lower.contains(keyword)) return entry.boostMl;
    }
  }
  return 0;
}