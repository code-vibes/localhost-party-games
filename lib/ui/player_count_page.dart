import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'game_grid_page.dart';

class PlayerCountPage extends StatelessWidget {
  const PlayerCountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = {
      1: 'Solo practice on this device',
      2: 'Pass-and-play party classics',
      3: 'Same device or Local Host',
      4: 'Same device or Local Host',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Players')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How many players?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: PartyTheme.ink)),
            const SizedBox(height: 8),
            const Text(
              'Pick a count for pass-and-play. Local Host works for 2–4 devices on the same Wi‑Fi/hotspot.',
              style: TextStyle(color: PartyTheme.mutedInk),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  for (final n in [1, 2, 3, 4])
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        context.read<AppState>().setPlayerCount(n);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GameGridPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$n',
                                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: PartyTheme.ink)),
                            Text('$n PLAYER${n == 1 ? '' : 'S'}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: PartyTheme.ink)),
                            const SizedBox(height: 6),
                            Text(labels[n]!, style: const TextStyle(fontSize: 12, color: PartyTheme.mutedInk)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
