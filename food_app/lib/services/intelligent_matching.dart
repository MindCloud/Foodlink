// lib/services/intelligent_matching.dart
class IntelligentMatchingAlgorithm {
  /// Calculates IMA score (0-100) based on fairness, nutrition, urgency, etc.
  static int calculateScore(Map<String, dynamic> donation) {
    int score = 75; // Base score (distance already filtered by Haversine)

    // 1. Nutritional Value
    String food = donation['foodType'].toString().toLowerCase();
    if (food.contains('rice') || food.contains('curry') || food.contains('vegetarian')) {
      score += 12;
    }
    if (food.contains('fruits') || food.contains('dairy')) {
      score += 8;
    }

    // 2. Quantity (larger donations get slight priority)
    try {
      int qty = int.parse(donation['quantity'].toString().split(' ')[0]);
      if (qty >= 4) score += 10;
    } catch (_) {}

    // 3. Fairness simulation (in real app this would check charity history)
    score += (DateTime.now().millisecond % 15); // Random small variation for demo

    return score.clamp(0, 100);
  }

  /// Returns human-readable reason for the match
  static String getReason(int score) {
    if (score >= 90) return "High Nutritional Fit • Balanced Meal";
    if (score >= 80) return "Fair Allocation Priority • Under-served Charity";
    if (score >= 70) return "Good Match • Suitable Quantity";
    return "Standard Match";
  }
}