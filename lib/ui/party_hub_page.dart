import 'dart:math';

import 'package:flutter/material.dart';

import '../core/game_registry.dart';
import '../games/game_router.dart';
import '../theme.dart';
import 'game_grid_page.dart';
import 'tile_art.dart';

class PartyHubPage extends StatefulWidget {
  const PartyHubPage({super.key});

  @override
  State<PartyHubPage> createState() => _PartyHubPageState();
}

class _PartyHubPageState extends State<PartyHubPage> {
  final rng = Random();
  late List<GameDefinition> spotlight;

  @override
  void initState() {
    super.initState();
    _reshuffle();
  }

  void _reshuffle() {
    final pool = [...GameRegistry.partyHighlights()];
    pool.shuffle(rng);
    spotlight = pool.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Party mix')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Tonight\'s lineup', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PartyTheme.ink)),
          const SizedBox(height: 8),
          const Text(
            'Curated picks for groups — inspired by party-game menus, with Local Host flair.',
            style: TextStyle(color: PartyTheme.mutedInk, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          for (final game in spotlight)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: SizedBox(width: 56, height: 56, child: GameTileArt(gameId: game.id)),
                title: Text(game.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(game.blurb),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GameRouter(gameId: game.id)),
                ),
              ),
            ),
          FilledButton.icon(
            onPressed: () => setState(_reshuffle),
            icon: const Icon(Icons.shuffle),
            label: const Text('Shuffle lineup'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameGridPage())),
            child: const Text('Browse full party grid'),
          ),
        ],
      ),
    );
  }
}