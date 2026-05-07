// lib/Charity/spoilage_risk_calculator.dart
// Calculates spoilage risk based on food properties and elapsed time

class SpoilageRiskCalculator {
  /// Calculate spoilage risk percentage (0.0 to 1.0)
  /// Based on expiry hours, cold storage requirement, and time elapsed
  static double calculateRisk({
    required double expiryHours,
    required bool coldRequired,
    required DateTime postedTime,
    String? foodType,
  }) {
    final now = DateTime.now();
    final elapsedMinutes = now.difference(postedTime).inMinutes;
    final elapsedHours = elapsedMinutes / 60.0;
    
    // Base risk increases with time elapsed
    double baseRisk = elapsedHours / expiryHours;
    
    // Cold storage reduces risk significantly
    if (coldRequired) {
      // Cold items spoil slower (0.4x rate)
      baseRisk *= 0.4;
    }
    
    // Food type multipliers
    double foodTypeMultiplier = 1.0;
    if (foodType != null) {
      final type = foodType.toLowerCase();
      if (type.contains('cooked') || type.contains('rice') || type.contains('curry')) {
        foodTypeMultiplier = 1.2; // Cooked food spoils faster
      } else if (type.contains('bread') || type.contains('bakery')) {
        foodTypeMultiplier = 0.8; // Bread lasts longer
      } else if (type.contains('fruit') || type.contains('vegetable')) {
        foodTypeMultiplier = 0.9; // Produce moderate
      } else if (type.contains('dairy') || type.contains('milk') || type.contains('yogurt')) {
        foodTypeMultiplier = 1.5; // Dairy spoils fastest
      } else if (type.contains('frozen') || type.contains('meat') || type.contains('fish')) {
        foodTypeMultiplier = coldRequired ? 0.5 : 2.0; // Depends on cold storage
      }
    }
    
    baseRisk *= foodTypeMultiplier;
    
    // Cap between 0 and 1
    return baseRisk.clamp(0.0, 1.0);
  }
  
  /// Get risk category and color info
  static RiskInfo getRiskInfo(double risk) {
    if (risk < 0.3) {
      return RiskInfo(
        label: "Low Risk",
        color: 0xFF10B981, // Green
        icon: "check_circle",
        message: "Food is fresh and safe",
      );
    } else if (risk < 0.5) {
      return RiskInfo(
        label: "Moderate",
        color: 0xFFF59E0B, // Yellow/Amber
        icon: "info",
        message: "Claim soon to avoid spoilage",
      );
    } else if (risk < 0.7) {
      return RiskInfo(
        label: "High Risk",
        color: 0xFFF97316, // Orange
        icon: "warning",
        message: "Spoilage risk increasing!",
      );
    } else {
      return RiskInfo(
        label: "Critical",
        color: 0xFFEF4444, // Red
        icon: "error",
        message: "Urgent! Food may spoil soon",
      );
    }
  }
  
  /// Calculate estimated time until spoilage
  static String getTimeUntilSpoilage({
    required double expiryHours,
    required bool coldRequired,
    required DateTime postedTime,
  }) {
    final now = DateTime.now();
    final elapsedMinutes = now.difference(postedTime).inMinutes;
    
    // Effective expiry based on cold storage
    final effectiveExpiryMinutes = coldRequired 
        ? expiryHours * 60 * 2.5  // Cold storage extends life 2.5x
        : expiryHours * 60;
    
    final remainingMinutes = effectiveExpiryMinutes - elapsedMinutes;
    
    if (remainingMinutes <= 0) {
      return "Likely spoiled";
    } else if (remainingMinutes < 60) {
      return "${remainingMinutes.round()} min left";
    } else {
      final hours = (remainingMinutes / 60).round();
      return "~$hours hours left";
    }
  }
  
  /// Get temperature recommendation
  static String getTemperatureRecommendation(bool coldRequired) {
    return coldRequired 
        ? "Keep refrigerated at 0-4°C"
        : "Store at room temperature 15-25°C";
  }
}

class RiskInfo {
  final String label;
  final int color;
  final String icon;
  final String message;
  
  RiskInfo({
    required this.label,
    required this.color,
    required this.icon,
    required this.message,
  });
}
