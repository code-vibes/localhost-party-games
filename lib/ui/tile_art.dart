import 'package:flutter/material.dart';

import '../core/game_registry.dart';
import '../theme.dart';

class GameTileArt extends StatelessWidget {
  const GameTileArt({super.key, required this.gameId});
  final GameId gameId;

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(gameId);
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(size: const Size(100, 100), painter: _BlobPainter(gameId)),
        Icon(icon, size: 52, color: _accent(gameId)),
      ],
    );
  }

  IconData _iconFor(GameId id) => switch (id) {
        GameId.cupPong => Icons.sports_bar,
        GameId.wheelie => Icons.two_wheeler,
        GameId.animalStack => Icons.pets,
        GameId.basketballHoops => Icons.sports_basketball,
        GameId.brainrotStack => Icons.auto_awesome,
        GameId.archery => Icons.gps_fixed,
        GameId.farkle => Icons.casino,
        GameId.triple => Icons.grid_3x3,
        GameId.guessPerson => Icons.groups,
        GameId.guessAnimal => Icons.cruelty_free,
        GameId.snakes => Icons.timeline,
        GameId.nutsBolts => Icons.build_circle,
        GameId.gravityRun => Icons.rocket_launch,
        GameId.seaBattle => Icons.sailing,
        GameId.darts => Icons.adjust,
        GameId.wrestle => Icons.sports_martial_arts,
        GameId.ballPhysics => Icons.sports_soccer,
        GameId.brokenTiles => Icons.grid_off,
        GameId.ludo => Icons.casino_outlined,
        GameId.yazy => Icons.edit_note,
        GameId.solitaire => Icons.style,
      };

  Color _accent(GameId id) => switch (id) {
        GameId.cupPong => Colors.red.shade700,
        GameId.wheelie => PartyTheme.redPlayer,
        GameId.animalStack => Colors.orange.shade800,
        GameId.basketballHoops => Colors.deepOrange,
        GameId.brainrotStack => Colors.deepPurple,
        GameId.archery => Colors.green.shade800,
        GameId.farkle => Colors.green.shade900,
        GameId.triple => Colors.purple,
        GameId.guessPerson => Colors.brown,
        GameId.guessAnimal => Colors.teal,
        GameId.snakes => Colors.lightBlue,
        GameId.nutsBolts => Colors.redAccent,
        GameId.gravityRun => Colors.indigo,
        GameId.seaBattle => Colors.blueGrey,
        GameId.darts => Colors.purple.shade900,
        GameId.wrestle => Colors.blue.shade900,
        GameId.ballPhysics => Colors.lightGreen.shade900,
        GameId.brokenTiles => Colors.cyan.shade900,
        GameId.ludo => Colors.blue,
        GameId.yazy => Colors.brown.shade800,
        GameId.solitaire => Colors.green.shade900,
      };
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.id);
  final GameId id;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.35);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.4), 28, paint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.55), 22, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}