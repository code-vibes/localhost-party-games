// Standalone LAN host for web join demos (browsers cannot bind sockets).
// Usage: dart run tool/lan_host.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const port = 7423;

Future<void> main() async {
  final code = _code();
  final ip = await _ip();
  final players = <Map<String, dynamic>>[
    {'id': 'host', 'displayName': 'CLI Host', 'isHost': true, 'isReady': true},
  ];
  String? selectedGame;
  final sockets = <WebSocketChannel>[];

  Map<String, dynamic> lobby() => {
        'sessionCode': code,
        'hostName': 'CLI Host',
        'players': players,
        'selectedGame': selectedGame,
        'phase': 'lobby',
        'hostIp': ip,
        'port': port,
      };

  void broadcast(Map<String, dynamic> msg) {
    final raw = jsonEncode(msg);
    for (final s in List<WebSocketChannel>.from(sockets)) {
      try {
        s.sink.add(raw);
      } catch (_) {}
    }
  }

  final router = Router()
    ..get('/health', (_) => Response.ok('ok'))
    ..get('/ws', webSocketHandler((WebSocketChannel socket) {
      sockets.add(socket);
      socket.sink.add(jsonEncode({'type': 'lobby', 'payload': lobby()}));
      socket.stream.listen((data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        if (msg['type'] == 'hello') {
          final p = Map<String, dynamic>.from(msg['payload'] as Map);
          if (!players.any((e) => e['id'] == p['id'])) players.add(p);
          broadcast({'type': 'lobby', 'payload': lobby()});
        }
      }, onDone: () => sockets.remove(socket));
    }));

  final server = await shelf_io.serve(router.call, InternetAddress.anyIPv4, port);
  stdout.writeln('Local Host CLI');
  stdout.writeln('Code: $code');
  stdout.writeln('IP:   $ip');
  stdout.writeln('WS:   ws://$ip:$port/ws');
  stdout.writeln('QR:   localhostparty://join?code=$code&ip=$ip&port=$port&name=CLI%20Host');
  stdout.writeln('Press Ctrl+C to stop. Web/app clients can Join with code+IP.');
  await ProcessSignal.sigint.watch().first;
  await server.close(force: true);
}

String _code() {
  const a = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random();
  return List.generate(4, (_) => a[r.nextInt(a.length)]).join();
}

Future<String> _ip() async {
  try {
    for (final iface in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
  } catch (_) {}
  return '127.0.0.1';
}
