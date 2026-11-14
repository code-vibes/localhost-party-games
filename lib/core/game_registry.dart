import 'package:flutter/material.dart';

enum GameId {
  cupPong,
  wheelie,
  animalStack,
  basketballHoops,
  brainrotStack,
  archery,
}

extension GameIdX on GameId {
  String get wireName => name;
  static GameId? fromWire(String? value) {
    if (value == null) return null;
    for (final g in GameId.values) {
      if (g.name == value) return g;
    }
    return null;
  }
}

class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.bannerColor,
    required this.artBackground,
    required this.blurb,
    this.supportsLiveSync = false,
  });

  final GameId id;
  final String title;
  final Color bannerColor;
  final Color artBackground;
  final String blurb;
  final bool supportsLiveSync;
}

class GameRegistry {
  static const all = <GameDefinition>[
    GameDefinition(
      id: GameId.cupPong,
      title: 'CUP PONG',
      bannerColor: Color(0xFF1A736B),
      artBackground: Color(0xFFEDF7F2),
      blurb: 'Flick the ball into the cups. First to clear the triangle wins.',
      supportsLiveSync: true,
    ),
    GameDefinition(
      id: GameId.wheelie,
      title: 'WHEELIE',
      bannerColor: Color(0xFF14141A),
      artBackground: Color(0xFFC7E6FA),
      blurb: 'Hold the balance in the green zone. Survive the longest.',
    ),
    GameDefinition(
      id: GameId.animalStack,
      title: 'ANIMAL STACK',
      bannerColor: Color(0xFF2E8CF2),
      artBackground: Color(0xFFE6F5FF),
      blurb: "Drop animals onto the stack. Don't topple the tower.",
      supportsLiveSync: true,
    ),
    GameDefinition(
      id: GameId.basketballHoops,
      title: 'BASKETBALL HOOPS',
      bannerColor: Color(0xFF337ACF),
      artBackground: Color(0xFFF0F7FF),
      blurb: 'Swipe to shoot. Most baskets before time runs out wins.',
    ),
    GameDefinition(
      id: GameId.brainrotStack,
      title: 'BRAINROT STACK',
      bannerColor: Color(0xFF142961),
      artBackground: Color(0xFFEDF2FF),
      blurb: 'Tap to drop chaotic meme objects. Build the tallest stack.',
    ),
    GameDefinition(
      id: GameId.archery,
      title: 'ARCHERY',
      bannerColor: Color(0xFF738538),
      artBackground: Color(0xFFE6F2D1),
      blurb: 'Aim and release. Closest to the bullseye scores.',
    ),
  ];

  static GameDefinition byId(GameId id) => all.firstWhere((g) => g.id == id);
}
