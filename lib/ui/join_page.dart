import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/game_registry.dart';
import '../games/game_router.dart';
import '../networking/protocol.dart';
import '../theme.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final codeCtrl = TextEditingController();
  final ipCtrl = TextEditingController(text: '127.0.0.1');
  bool joined = false;

  @override
  void dispose() {
    codeCtrl.dispose();
    ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinFromPayload(String raw) async {
    final app = context.read<AppState>();
    final parsed = GameLobbyState.parseJoin(raw);
    if (parsed != null && parsed.hostIp != null) {
      await app.joinLocal(code: parsed.sessionCode, ip: parsed.hostIp, port: parsed.port);
    } else if (parsed != null) {
      await app.joinLocal(code: parsed.sessionCode, ip: ipCtrl.text.trim());
    } else if (raw.trim().length == 4) {
      await app.joinLocal(code: raw.trim(), ip: ipCtrl.text.trim());
    }
    setState(() => joined = true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final host = app.localHost;

    return Scaffold(
      appBar: AppBar(title: const Text('Join')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Join Local Host',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: PartyTheme.ink)),
          const SizedBox(height: 8),
          const Text(
            'Connect to the same Wi‑Fi or the host’s hotspot, then scan their QR or type the 4-letter code + host IP.',
            style: TextStyle(color: PartyTheme.mutedInk),
          ),
          const SizedBox(height: 16),
          if (!kIsWeb)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: PartyTheme.bluePlayer, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () async {
                final result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const _ScanPage()),
                );
                if (result != null) await _joinFromPayload(result);
              },
              child: const Text('SCAN QR CODE', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          else
            const Text('QR camera scan is on mobile builds. On web, paste the QR payload or enter code + host IP.',
                style: TextStyle(color: PartyTheme.mutedInk)),
          const SizedBox(height: 12),
          TextField(
            controller: ipCtrl,
            decoration: const InputDecoration(labelText: 'Host LAN IP', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'CODE', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _joinFromPayload(codeCtrl.text),
                child: const Text('JOIN'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Or paste full QR payload',
              border: OutlineInputBorder(),
            ),
            onSubmitted: _joinFromPayload,
          ),
          if (joined) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(host.status, style: const TextStyle(fontWeight: FontWeight.w700)),
                    for (final p in host.lobby.players) Text('• ${p.displayName}'),
                    if (host.lobby.phase == LobbyPhase.playing && host.lobby.selectedGame != null)
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => GameRouter(gameId: host.lobby.selectedGame!)),
                          );
                        },
                        child: Text('Open ${GameRegistry.byId(host.lobby.selectedGame!).title}'),
                      ),
                    TextButton(
                      onPressed: () async {
                        await host.leave();
                        setState(() => joined = false);
                      },
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanPage extends StatelessWidget {
  const _ScanPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final value = barcodes.first.rawValue;
          if (value != null) Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
