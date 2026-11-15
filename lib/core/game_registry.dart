import 'package:flutter/material.dart';

import 'play_mode.dart';

enum GameId {
  cupPong,
  wheelie,
  animalStack,
  basketballHoops,
  brainrotStack,
  archery,
  farkle,
  triple,
  guessPerson,
  guessAnimal,
  snakes,
  nutsBolts,
  gravityRun,
  seaBattle,
  darts,
  wrestle,
  ballPhysics,
  brokenTiles,
  ludo,
  yazy,
  solitaire,
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
    this.minPlayers = 1,
    this.maxPlayers = 4,
    this.partyPick = false,
    this.teamFriendly = true,
    this.supportsLiveSync = false,
    this.isNew = false,
  });

  final GameId id;
  final String title;
  final Color bannerColor;
  final Color artBackground;
  final String blurb;
  final int minPlayers;
  final int maxPlayers;
  final bool partyPick;
  final bool teamFriendly;
  final bool supportsLiveSync;
  final bool isNew;

  bool supportsPlayerCount(int count) => count >= minPlayers && count <= maxPlayers;

  bool supportsMode(PlayMode mode) {
    if (mode.isTeam && !teamFriendly) return false;
    return supportsPlayerCount(mode.playerCount);
  }
}

class GameRegistry {
  static const all = <GameDefinition>[
    GameDefinition(
      id: GameId.cupPong,
      title: 'CUP PONG',
      bannerColor: Color(0xFF1A736B),
      artBackground: Color(0xFFEDF7F2),
      blurb: 'Flick into cups. Clear the triangle.',
      minPlayers: 2,
      partyPick: true,
      supportsLiveSync: true,
    ),
    GameDefinition(
      id: GameId.wheelie,
      title: 'WHEELIE',
      bannerColor: Color(0xFF14141A),
      artBackground: Color(0xFFC7E6FA),
      blurb: 'Balance in the green zone.',
      minPlayers: 2,
    ),
    GameDefinition(
      id: GameId.animalStack,
      title: 'ANIMAL STACK',
      bannerColor: Color(0xFF2E8CF2),
      artBackground: Color(0xFFE6F5FF),
      blurb: "Stack animals. Don't wobble.",
      minPlayers: 2,
      partyPick: true,
      supportsLiveSync: true,
    ),
    GameDefinition(
      id: GameId.basketballHoops,
      title: 'BASKETBALL',
      bannerColor: Color(0xFF337ACF),
      artBackground: Color(0xFFF0F7FF),
      blurb: 'Swipe shots before the buzzer.',
      minPlayers: 1,
      partyPick: true,
    ),
    GameDefinition(
      id: GameId.brainrotStack,
      title: 'BRAINROT STACK',
      bannerColor: Color(0xFF142961),
      artBackground: Color(0xFFEDF2FF),
      blurb: 'Drop chaotic objects higher.',
      minPlayers: 1,
      isNew: true,
    ),
    GameDefinition(
      id: GameId.archery,
      title: 'ARCHERY',
      bannerColor: Color(0xFF738538),
      artBackground: Color(0xFFE6F2D1),
      blurb: 'Aim for bullseyes.',
      minPlayers: 1,
    ),
    GameDefinition(
      id: GameId.farkle,
      title: 'FARKLE',
      bannerColor: Color(0xFF1F6B3A),
      artBackground: Color(0xFFE2F6E8),
      blurb: 'Roll hot dice — bank or bust.',
      minPlayers: 1,
      isNew: true,
    ),
    GameDefinition(
      id: GameId.triple,
      title: 'TRIPLE',
      bannerColor: Color(0xFF5E2D91),
      artBackground: Color(0xFFF3E9FF),
      blurb: 'Tap three alike symbols.',
      minPlayers: 1,
      isNew: true,
    ),
    GameDefinition(
      id: GameId.guessPerson,
      title: 'GUESS PERSON',
      bannerColor: Color(0xFF4D4035),
      artBackground: Color(0xFFF8EFE8),
      blurb: 'Who is hiding behind the clues?',
      minPlayers: 2,
      partyPick: true,
    ),
    GameDefinition(
      id: GameId.guessAnimal,
      title: 'GUESS ANIMAL',
      bannerColor: Color(0xFF1F7A6B),
      artBackground: Color(0xFFE7FAF4),
      blurb: 'Emoji hints → pick the critter.',
      minPlayers: 1,
      isNew: true,
    ),
    GameDefinition(
      id: GameId.snakes,
      title: 'SNAKES',
      bannerColor: Color(0xFF1C2F4E),
      artBackground: Color(0xFFD9ECFF),
      blurb: 'Tap to slither. Avoid walls.',
      minPlayers: 2,
    ),
    GameDefinition(
      id: GameId.nutsBolts,
      title: 'NUTS & BOLTS',
      bannerColor: Color(0xFF4A1E63),
      artBackground: Color(0xFFF1E6FA),
      blurb: 'Match colored nuts to bolts.',
      minPlayers: 1,
    ),
    GameDefinition(
      id: GameId.gravityRun,
      title: 'GRAVITY RUN',
      bannerColor: Color(0xFF6B4A2E),
      artBackground: Color(0xFFFFF1E0),
      blurb: 'Hold to float, drop through gaps.',
      minPlayers: 1,
      isNew: true,
    ),
    GameDefinition(
      id: GameId.seaBattle,
      title: 'SEA BATTLE',
      bannerColor: Color(0xFF123C5A),
      artBackground: Color(0xFFD7F0FF),
      blurb: 'Mini naval grid skirmish.',
      minPlayers: 2,
      teamFriendly: true,
      partyPick: true,
    ),
    GameDefinition(
      id: GameId.darts,
      title: 'DARTS',
      bannerColor: Color(0xFF3E2B6E),
      artBackground: Color(0xFFEDE8FF),
      blurb: 'Drag and release at the board.',
      minPlayers: 1,
    ),
    GameDefinition(
      id: GameId.wrestle,
      title: 'WRESTLE',
      bannerColor: Color(0xFF1B2B6B),
      artBackground: Color(0xFFE2E9FF),
      blurb: 'Mash taps to pin your rival.',
      minPlayers: 2,
      partyPick: true,
    ),
    GameDefinition(
      id: GameId.ballPhysics,
      title: 'BALL PHYSICS',
      bannerColor: Color(0xFF3F7A1E),
      artBackground: Color(0xFFE8FFD8),
      blurb: 'Flick soccer shots past keeper.',
      minPlayers: 2,
    ),
    GameDefinition(
      id: GameId.brokenTiles,
      title: 'BROKEN TILES',
      bannerColor: Color(0xFF15648A),
      artBackground: Color(0xFFE0F6FF),
      blurb: 'Tap tiles before they crack away.',
      minPlayers: 1,
    ),
    GameDefinition(
      id: GameId.ludo,
      title: 'LUDO RACE',
      bannerColor: Color(0xFF2A8FBA),
      artBackground: Color(0xFFE5F7FF),
      blurb: 'Roll and race around the loop.',
      minPlayers: 2,
      maxPlayers: 4,
      partyPick: true,
    ),
    GameDefinition(
      id: GameId.yazy,
      title: 'YAZY',
      bannerColor: Color(0xFF6A462B),
      artBackground: Color(0xFFFFF3E6),
      blurb: 'Dice poker — fill your score sheet.',
      minPlayers: 1,
    ),
    GameDefinition(
      id: GameId.solitaire,
      title: 'SOLITAIRE',
      bannerColor: Color(0xFF1D5A32),
      artBackground: Color(0xFFE4F5E8),
      blurb: 'Match pairs before the timer ends.',
      minPlayers: 1,
    ),
  ];

  static GameDefinition byId(GameId id) => all.firstWhere((g) => g.id == id);

  static List<GameDefinition> forMode(PlayMode mode) {
  final list = all.where((g) => g.supportsMode(mode)).toList();
    if (mode.isParty) {
      final picks = list.where((g) => g.partyPick).toList();
      final rest = list.where((g) => !g.partyPick).toList();
      return [...picks, ...rest];
    }
    return list;
  }

  static List<GameDefinition> partyHighlights() =>
      all.where((g) => g.partyPick).toList();
}