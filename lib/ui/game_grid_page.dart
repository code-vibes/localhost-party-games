import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/game_registry.dart';
import '../core/play_mode.dart';
import '../games/game_router.dart';
import '../theme.dart';
import 'tile_art.dart';

class GameGridPage extends StatelessWidget {
  const GameGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final games = GameRegistry.forMode(app.playMode);
    final title = switch (app.playMode) {
      PlayMode.solo => 'SOLO ARCADE',
      PlayMode.duo => 'DUO GAMES',
      PlayMode.trio => 'TRIO GAMES',
      PlayMode.quad => 'SQUAD GAMES',
      PlayMode.team2v2 => 'TEAM SHOWDOWN',
      PlayMode.party => 'PARTY GRID',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          if (app.playMode.isTeam)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(child: _TeamPill(label: 'TEAM A', score: app.teamScore(0), colors: [PartyTheme.redPlayer, PartyTheme.orangePlayer])),
                  const SizedBox(width: 10),
                  Expanded(child: _TeamPill(label: 'TEAM B', score: app.teamScore(1), colors: [PartyTheme.bluePlayer, PartyTheme.greenPlayer])),
                ],
              ),
            ),
          if (app.playMode.isParty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Party picks first — then the full library.', style: TextStyle(color: PartyTheme.mutedInk, fontWeight: FontWeight.w600)),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return _GameTile(
                  game: game,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GameRouter(gameId: game.id)),
                  ),
                );
              },
            ),
          ),
          _ScoreBar(app: app),
        ],
      ),
    );
  }
}

class _TeamPill extends StatelessWidget {
  const _TeamPill({required this.label, required this.score, required this.colors});
  final String label;
  final int score;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Row(
        children: [
          for (final c in colors)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
          Text('$score', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: game.artBackground,
                        child: Center(child: GameTileArt(gameId: game.id)),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      color: game.bannerColor,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                      child: Text(
                        game.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
                if (game.isNew)
                  Positioned(
                    right: -2,
                    top: 6,
                    child: Transform.rotate(
                      angle: 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: const Color(0xFFFF9F43),
                        child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
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

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.app});
  final AppState app;

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
          for (var i = 0; i < app.playerCount; i++)
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: PartyTheme.playerColor(i),
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 6),
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white,
                    child: Text('${app.scores[i]}', style: const TextStyle(fontWeight: FontWeight.w900, color: PartyTheme.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}