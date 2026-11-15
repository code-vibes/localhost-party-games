import 'package:flutter/material.dart';

class PartyTheme {
  static const background = Color(0xFFEDF2F7);
  static const ink = Color(0xFF2E333D);
  static const mutedInk = Color(0xFF667080);
  static const redPlayer = Color(0xFFEB3847);
  static const bluePlayer = Color(0xFF2E73F2);
  static const greenPlayer = Color(0xFF29B86B);
  static const orangePlayer = Color(0xFFFA8C29);

  static Color playerColor(int index) {
    const colors = [redPlayer, bluePlayer, greenPlayer, orangePlayer];
    return colors[index % colors.length];
  }

  static String playerName(int index) => 'P${index + 1}';

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: bluePlayer,
        brightness: Brightness.light,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w900, color: ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: ink),
        bodyMedium: TextStyle(fontWeight: FontWeight.w500, color: mutedInk),
      ),
    );
  }
}
