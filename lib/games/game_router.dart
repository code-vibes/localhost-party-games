import 'package:flutter/material.dart';

import '../core/game_registry.dart';
import '../theme.dart';
import 'animal_stack.dart';
import 'archery.dart';
import 'ball_physics.dart';
import 'basketball.dart';
import 'brainrot_stack.dart';
import 'broken_tiles.dart';
import 'cup_pong.dart';
import 'darts_game.dart';
import 'farkle.dart';
import 'gravity_run.dart';
import 'guess_animal.dart';
import 'guess_person.dart';
import 'ludo_race.dart';
import 'nuts_bolts.dart';
import 'sea_battle.dart';
import 'snakes.dart';
import 'solitaire_lite.dart';
import 'triple_match.dart';
import 'wheelie.dart';
import 'wrestle.dart';
import 'yazy.dart';

class GameRouter extends StatelessWidget {
  const GameRouter({super.key, required this.gameId});
  final GameId gameId;

  @override
  Widget build(BuildContext context) {
    return switch (gameId) {
      GameId.cupPong => const CupPongGame(),
      GameId.wheelie => const WheelieGame(),
      GameId.animalStack => const AnimalStackGame(),
      GameId.basketballHoops => const BasketballGame(),
      GameId.brainrotStack => const BrainrotStackGame(),
      GameId.archery => const ArcheryGame(),
      GameId.farkle => const FarkleGame(),
      GameId.triple => const TripleMatchGame(),
      GameId.guessPerson => const GuessPersonGame(),
      GameId.guessAnimal => const GuessAnimalGame(),
      GameId.snakes => const SnakesGame(),
      GameId.nutsBolts => const NutsBoltsGame(),
      GameId.gravityRun => const GravityRunGame(),
      GameId.seaBattle => const SeaBattleGame(),
      GameId.darts => const DartsGame(),
      GameId.wrestle => const WrestleGame(),
      GameId.ballPhysics => const BallPhysicsGame(),
      GameId.brokenTiles => const BrokenTilesGame(),
      GameId.ludo => const LudoRaceGame(),
      GameId.yazy => const YazyGame(),
      GameId.solitaire => const SolitaireLiteGame(),
    };
  }
}

class TurnBanner extends StatelessWidget {
  const TurnBanner({super.key, required this.playerIndex, required this.message});
  final int playerIndex;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white.withOpacity(0.92),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(radius: 9, backgroundColor: PartyTheme.playerColor(playerIndex)),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.title,
    required this.detail,
    required this.onAgain,
    required this.onDone,
  });

  final String title;
  final String detail;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(detail, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(onPressed: onAgain, child: const Text('Again')),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: onDone, child: const Text('Done')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}