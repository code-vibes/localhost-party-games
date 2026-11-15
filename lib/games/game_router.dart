import 'package:flutter/material.dart';

import '../core/game_registry.dart';
import '../theme.dart';
import 'archery.dart';
import 'animal_stack.dart';
import 'basketball.dart';
import 'brainrot_stack.dart';
import 'cup_pong.dart';
import 'wheelie.dart';

class GameRouter extends StatelessWidget {
  const GameRouter({super.key, required this.gameId});
  final GameId gameId;

  @override
  Widget build(BuildContext context) {
    switch (gameId) {
      case GameId.cupPong:
        return const CupPongGame();
      case GameId.wheelie:
        return const WheelieGame();
      case GameId.animalStack:
        return const AnimalStackGame();
      case GameId.basketballHoops:
        return const BasketballGame();
      case GameId.brainrotStack:
        return const BrainrotStackGame();
      case GameId.archery:
        return const ArcheryGame();
    }
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
