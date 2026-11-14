import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/game_registry.dart';
import '../games/game_router.dart';
import '../theme.dart';

class GameGridPage extends StatelessWidget {
  const GameGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final title = '${app.playerCount} PLAYER GAMES';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
              ),
              itemCount: GameRegistry.all.length,
              itemBuilder: (context, index) {
                final game = GameRegistry.all[index];
                return _GameTile(
                  game: game,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GameRouter(gameId: game.id)),
                  ),
                );
              },
            ),
          ),
          _ScoreBar(playerCount: app.playerCount, scores: app.scores),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.onTap});
  final GameDefinition game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: game.artBackground,
                    child: Center(child: _TileArt(gameId: game.id)),
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: game.bannerColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    game.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileArt extends StatelessWidget {
  const _TileArt({required this.gameId});
  final GameId gameId;

  @override
  Widget build(BuildContext context) {
    switch (gameId) {
      case GameId.cupPong:
        return const Icon(Icons.sports_bar, size: 56, color: Colors.red);
      case GameId.wheelie:
        return const Icon(Icons.two_wheeler, size: 56, color: PartyTheme.redPlayer);
      case GameId.animalStack:
        return const Icon(Icons.pets, size: 56, color: Colors.orange);
      case GameId.basketballHoops:
        return const Icon(Icons.sports_basketball, size: 56, color: Colors.deepOrange);
      case GameId.brainrotStack:
        return const Icon(Icons.auto_awesome, size: 56, color: Colors.purple);
      case GameId.archery:
        return const Icon(Icons.gps_fixed, size: 56, color: Colors.green);
    }
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.playerCount, required this.scores});
  final int playerCount;
  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          for (var i = 0; i < playerCount; i++)
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: PartyTheme.playerColor(i),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white,
                    child: Text(
                      '${scores[i]}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: PartyTheme.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
