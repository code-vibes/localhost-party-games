import 'package:flutter/material.dart';

import '../core/game_registry.dart';
import '../theme.dart';
import 'game_grid_page.dart';
import 'join_page.dart';
import 'lobby_page.dart';
import 'player_count_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDBECFF), PartyTheme.background, Color(0xFFF5EDFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text('LOCAL HOST',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          letterSpacing: 4,
                          fontWeight: FontWeight.w800,
                          color: PartyTheme.mutedInk,
                        )),
                const SizedBox(height: 8),
                const Text('1234',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: PartyTheme.ink,
                      height: 1,
                    )),
                const Text('PARTY GAMES',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: PartyTheme.ink,
                    )),
                const SizedBox(height: 10),
                const Text(
                  'Same-phone chaos or hotspot multiplayer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PartyTheme.mutedInk, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                _PrimaryButton(
                  label: 'PLAY ON THIS DEVICE',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlayerCountPage()),
                  ),
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: 'HOST LOCAL SESSION',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LobbyPage()),
                  ),
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: 'JOIN VIA QR / LAN',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JoinPage()),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < GameRegistry.all.length; i++)
                      Transform.rotate(
                        angle: i.isEven ? -0.1 : 0.1,
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: GameRegistry.all[i].bannerColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GameGridPage()),
                  ),
                  child: const Text('Skip to 2P grid'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: PartyTheme.ink,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: PartyTheme.ink,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.white, width: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
