import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/play_mode.dart';
import '../theme.dart';
import 'game_grid_page.dart';
import 'join_page.dart';
import 'lobby_page.dart';
import 'party_hub_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _modes = [
    (PlayMode.solo, Color(0xFFE85D4A), '1'),
    (PlayMode.duo, Color(0xFF4BA3F5), '2'),
    (PlayMode.trio, Color(0xFF5BCB73), '3'),
    (PlayMode.quad, Color(0xFFF5B731), '4'),
    (PlayMode.team2v2, Color(0xFF9B6BF2), '2v2'),
    (PlayMode.party, Color(0xFFEE6FA0), '★'),
  ];

  void _openMode(BuildContext context, PlayMode mode) {
    context.read<AppState>().setPlayMode(mode);
    if (mode.isParty) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartyHubPage()));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameGridPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF6EE), PartyTheme.background, Color(0xFFE9E5FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded, color: PartyTheme.mutedInk),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: PartyTheme.ink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('LAN PARTY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFFE85D4A), Color(0xFF4BA3F5), Color(0xFF5BCB73), Color(0xFFF5B731)],
                ).createShader(rect),
                child: const Text(
                  'LOCAL HOST',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3),
                ),
              ),
              const Text(
                'PARTY PAD',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: PartyTheme.ink, height: 1.05),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your couch. Your hotspot. Our playful spins on classic quick games.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PartyTheme.mutedInk, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 22),
              for (var row = 0; row < 3; row++) ...[
                Row(
                  children: [
                    for (var col = 0; col < 2; col++) ...[
                      Expanded(child: _ModeCard(
                        accent: _modes[row * 2 + col].$2,
                        badge: _modes[row * 2 + col].$3,
                        mode: _modes[row * 2 + col].$1,
                        onTap: () => _openMode(context, _modes[row * 2 + col].$1),
                      )),
                      if (col == 0) const SizedBox(width: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _LanChip(
                      icon: Icons.wifi_tethering,
                      label: 'Host session',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LobbyPage())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LanChip(
                      icon: Icons.qr_code_scanner,
                      label: 'Join LAN',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinPage())),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.accent,
    required this.badge,
    required this.mode,
    required this.onTap,
  });

  final Color accent;
  final String badge;
  final PlayMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isParty = mode.isParty;
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: accent.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge,
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: accent, height: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(mode.label, style: const TextStyle(fontWeight: FontWeight.w900, color: PartyTheme.ink, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(mode.subtitle, style: const TextStyle(fontSize: 11, color: PartyTheme.mutedInk, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (isParty)
                Positioned(
                  right: -4,
                  top: 8,
                  child: Transform.rotate(
                    angle: 0.35,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: const Color(0xFFFFB347),
                      child: const Text('MIX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanChip extends StatelessWidget {
  const _LanChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}