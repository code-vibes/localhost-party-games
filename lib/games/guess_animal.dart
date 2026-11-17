import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class GuessAnimalGame extends StatefulWidget {
  const GuessAnimalGame({super.key});
  @override State<GuessAnimalGame> createState() => _GuessAnimalGameState();
}

class _GuessAnimalGameState extends State<GuessAnimalGame> with PassAndPlayMixin {
  final rng = Random();
  final rounds = <int>[];
  final data = [
    ('🐼', 'Panda', ['Panda', 'Parrot', 'Camel', 'Crab']),
    ('🦜', 'Parrot', ['Parrot', 'Panda', 'Fox', 'Frog']),
    ('🐫', 'Camel', ['Camel', 'Crab', 'Penguin', 'Panda']),
    ('🦀', 'Crab', ['Crab', 'Camel', 'Tiger', 'Toad']),
  ];
  late var round;

  @override
  void initState() { super.initState(); round = data[rng.nextInt(data.length)]; }

  @override void onRoundReset() { rounds.clear(); round = data[rng.nextInt(data.length)]; }

  void _pick(String v) {
    while (rounds.length <= currentPlayer) rounds.add(0);
    if (v == round.$2) rounds[currentPlayer]++;
    if (rounds[currentPlayer] >= 3) finishMatch(currentPlayer, detail: '3 correct critters');
    else { nextPlayer(); round = data[rng.nextInt(data.length)]; }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (rounds.length < pc) rounds.add(0);
    final choices = List<String>.from(round.$3)..shuffle(rng);
    return Scaffold(
      appBar: AppBar(title: const Text('Guess the Animal')),
      body: Stack(children: [
        Column(children: [
          turnBanner('What critter is this?'),
          Text(round.$1, style: const TextStyle(fontSize: 96)),
          for (final c in choices) ListTile(title: Text(c, style: const TextStyle(fontWeight: FontWeight.w800)), onTap: () => _pick(c)),
        ]),
        if (resultOverlay(() { round = data[rng.nextInt(data.length)]; }) != null) resultOverlay(() { round = data[rng.nextInt(data.length)]; })!,
      ]),
    );
  }
}
