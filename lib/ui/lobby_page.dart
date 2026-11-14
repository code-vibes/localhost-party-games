import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_state.dart';
import '../core/game_registry.dart';
import '../games/game_router.dart';
import '../theme.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool started = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final host = app.localHost;

    return Scaffold(
      appBar: AppBar(title: const Text('Local Host')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Host a Local Session',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: PartyTheme.ink)),
          const SizedBox(height: 8),
          const Text(
            'Creates an HTTP + WebSocket lobby on your Wi‑Fi or personal hotspot. Friends scan the QR or enter the code — no internet required.',
            style: TextStyle(color: PartyTheme.mutedInk),
          ),
          const SizedBox(height: 16),
          if (!host.canHost)
            Card(
              color: const Color(0xFFFFF3CD),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  host.lastError ??
                      'This platform cannot bind LAN sockets. Use Android/iOS to host, or run `dart run tool/lan_host.dart` then join from web.',
                  style: const TextStyle(color: PartyTheme.ink),
                ),
              ),
            ),
          if (!started)
            FilledButton(
              onPressed: host.canHost
                  ? () async {
                      await app.hostLocal();
                      setState(() => started = true);
                    }
                  : () async {
                      await app.hostLocal();
                      setState(() {});
                    },
              style: FilledButton.styleFrom(
                backgroundColor: PartyTheme.ink,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('START HOSTING', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Session code', style: TextStyle(color: PartyTheme.mutedInk, fontWeight: FontWeight.w700)),
                        Text(host.lobby.sessionCode,
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 6)),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(host.lobby.players.length > 1 ? 'LIVE' : 'WAITING'),
                    backgroundColor: host.lobby.players.length > 1 ? PartyTheme.greenPlayer : PartyTheme.mutedInk,
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (host.lobby.qrPayload.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(data: host.lobby.qrPayload, size: 220),
                ),
              ),
            const SizedBox(height: 8),
            SelectableText(host.lobby.qrPayload, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            const SizedBox(height: 16),
            Text('Players (${host.lobby.players.length}/4)',
                style: const TextStyle(fontWeight: FontWeight.w800, color: PartyTheme.ink)),
            for (final p in host.lobby.players)
              ListTile(
                leading: CircleAvatar(backgroundColor: p.isHost ? PartyTheme.redPlayer : PartyTheme.bluePlayer),
                title: Text('${p.displayName}${p.isHost ? ' (host)' : ''}'),
                trailing: Text(p.isReady ? 'READY' : '…',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: p.isReady ? PartyTheme.greenPlayer : PartyTheme.mutedInk,
                    )),
              ),
            Text(host.status, style: const TextStyle(color: PartyTheme.mutedInk, fontSize: 12)),
            const SizedBox(height: 12),
            const Text('Pick a game', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in GameRegistry.all)
                  ChoiceChip(
                    selected: host.lobby.selectedGame == g.id,
                    label: Text(g.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    selectedColor: g.bannerColor,
                    labelStyle: TextStyle(
                      color: host.lobby.selectedGame == g.id ? Colors.white : PartyTheme.ink,
                    ),
                    onSelected: (_) {
                      host.selectGame(g.id);
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (host.lobby.selectedGame != null)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: PartyTheme.redPlayer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  host.startSelectedGame();
                  final count = host.lobby.players.length.clamp(2, 4);
                  app.setPlayerCount(count);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GameRouter(gameId: host.lobby.selectedGame!)),
                  );
                },
                child: Text(
                  'PLAY ${GameRegistry.byId(host.lobby.selectedGame!).title}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            TextButton(
              onPressed: () async {
                await host.leave();
                setState(() => started = false);
              },
              child: const Text('Stop hosting'),
            ),
          ],
        ],
      ),
    );
  }
}
