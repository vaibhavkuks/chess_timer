import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFFF1500);
  static const Color overlayScrim = Color(0xCC000000); // ~black 80%

  // Greys (approximate Material greys used in the app)
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray800 = Color(0xFF424242);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class AppRadii {
  static const double bg = 16.0; // background panel rounded radius
  static const double controls = 40.0; // controls superellipse radius
  static const double dot = 10.0; // small status dot radius
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 800);
}

class AppTextStyles {
  static const TextStyle timeLarge = TextStyle(
    fontSize: 48,
  );

  static const TextStyle moveCounter = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle overlaySmall = TextStyle(
    fontSize: 13,
    color: Color.fromARGB(200, 255, 255, 255),
  );

  static const TextStyle overlayTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
}
