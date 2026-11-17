import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class GuessPersonGame extends StatefulWidget {
  const GuessPersonGame({super.key});
  @override State<GuessPersonGame> createState() => _GuessPersonGameState();
}

class _GuessPersonGameState extends State<GuessPersonGame> with PassAndPlayMixin {
  final rng = Random();
  final scores = <int>[];
  final people = [
    ('Glasses + purple hair', 'Luna'),
    ('Red cap + freckles', 'Sam'),
    ('Blue hoodie + beanie', 'Rio'),
    ('Gold earrings + braids', 'Nia'),
  ];
  late (String, String) clue;

  @override
  void initState() { super.initState(); clue = people[rng.nextInt(people.length)]; }
  @override void onRoundReset() { scores.clear(); clue = people[rng.nextInt(people.length)]; }

  void _answer(String name) {
    while (scores.length <= currentPlayer) scores.add(0);
    if (name == clue.$2) scores[currentPlayer]++;
    if (scores[currentPlayer] >= 3) finishMatch(currentPlayer, detail: 'Spotted three friends');
    else { nextPlayer(); clue = people[rng.nextInt(people.length)]; }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (scores.length < pc) scores.add(0);
    final options = people.map((e) => e.$2).toList()..shuffle(rng);
    return Scaffold(
      appBar: AppBar(title: const Text('Guess the Person')),
      body: Stack(children: [
        Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          turnBanner('Clue: ${clue.$1}'),
          const SizedBox(height: 20),
          for (final n in options) Padding(padding: const EdgeInsets.only(bottom: 8), child: ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(n, style: const TextStyle(fontWeight: FontWeight.w900)),
            onTap: () => _answer(n),
          )),
        ])),
        if (resultOverlay(() { clue = people[rng.nextInt(people.length)]; }) != null) resultOverlay(() { clue = people[rng.nextInt(people.length)]; })!,
      ]),
    );
  }
}
