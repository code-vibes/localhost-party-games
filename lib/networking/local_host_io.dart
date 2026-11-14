import 'dart:async';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/game_registry.dart';
import 'protocol.dart';

class LocalHostController {
  LocalHostController();

  final _uuid = const Uuid();
  HttpServer? _server;
  WebSocketChannel? _client;
  final _sockets = <WebSocketChannel>[];
  late LobbyPlayer _me;
  GameLobbyState lobby = GameLobbyState(sessionCode: '', hostName: '');
  bool get isHosting => _server != null;
  bool get isClient => _client != null;
  bool get canHost => true;
  String status = 'Idle';
  String? lastError;

  final _lobbyCtrl = StreamController<GameLobbyState>.broadcast();
  final _statusCtrl = StreamController<String>.broadcast();
  Stream<GameLobbyState> get lobbyStream => _lobbyCtrl.stream;
  Stream<String> get statusStream => _statusCtrl.stream;

  void _setStatus(String value) {
    status = value;
    _statusCtrl.add(value);
  }

  Future<void> hostSession({String displayName = 'Host'}) async {
    await leave();
    final code = _makeCode();
    _me = LobbyPlayer(id: _uuid.v4(), displayName: displayName, isHost: true, isReady: true);
    final ip = await _lanIp();
    lobby = GameLobbyState(
      sessionCode: code,
      hostName: displayName,
      players: [_me],
      hostIp: ip,
      port: localHostPort,
    );

    final router = Router()
      ..get('/health', (Request req) => Response.ok('ok'))
      ..get('/ws', webSocketHandler(_onHostSocket));

    try {
      _server = await shelf_io.serve(router.call, InternetAddress.anyIPv4, localHostPort);
      _setStatus('Hosting $code on ${ip ?? "0.0.0.0"}:$localHostPort');
      _lobbyCtrl.add(lobby);
    } catch (e) {
      lastError = e.toString();
      _setStatus('Host failed: $e');
    }
  }

  void _onHostSocket(WebSocketChannel socket) {
    _sockets.add(socket);
    socket.stream.listen((data) {
      final msg = WireMessage.decode(data as String);
      _handleHostMessage(msg);
    }, onDone: () => _sockets.remove(socket), onError: (_) => _sockets.remove(socket));
    socket.sink.add(WireMessage.lobby(lobby).encode());
  }

  void _handleHostMessage(WireMessage msg) {
    switch (msg.type) {
      case 'hello':
        final player = LobbyPlayer.fromJson(msg.payload);
        if (!lobby.players.any((p) => p.id == player.id)) {
          lobby.players.add(player);
        }
        _broadcastLobby();
        break;
      case 'ready':
        final id = msg.payload['playerId'] as String?;
        final idx = lobby.players.indexWhere((p) => p.id == id);
        if (idx >= 0) lobby.players[idx].isReady = true;
        _broadcastLobby();
        break;
      default:
        _broadcast(msg);
    }
  }

  void selectGame(GameId id) {
    if (!isHosting) return;
    lobby.selectedGame = id;
    _broadcast(WireMessage.selectGame(id));
    _broadcastLobby();
  }

  void startSelectedGame() {
    if (!isHosting || lobby.selectedGame == null) return;
    lobby.phase = LobbyPhase.playing;
    _broadcast(WireMessage.startGame(lobby.selectedGame!));
    _broadcastLobby();
  }

  Future<void> joinSession({
    required String code,
    String? hostIp,
    int port = localHostPort,
    String displayName = 'Player',
  }) async {
    await leave();
    final ip = hostIp ?? '127.0.0.1';
    _me = LobbyPlayer(id: _uuid.v4(), displayName: displayName);
    lobby = GameLobbyState(sessionCode: code.toUpperCase(), hostName: 'Host', hostIp: ip, port: port);
    final uri = Uri.parse('ws://$ip:$port/ws');
    try {
      _client = WebSocketChannel.connect(uri);
      _setStatus('Connecting to $ip:$port …');
      _client!.stream.listen((data) {
        final msg = WireMessage.decode(data as String);
        _handleClientMessage(msg);
      }, onError: (e) {
        lastError = e.toString();
        _setStatus('Join error: $e');
      }, onDone: () => _setStatus('Disconnected from host'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _client?.sink.add(WireMessage.hello(_me).encode());
      _setStatus('Joined $code @ $ip');
    } catch (e) {
      lastError = e.toString();
      _setStatus('Join failed: $e');
    }
  }

  void _handleClientMessage(WireMessage msg) {
    switch (msg.type) {
      case 'lobby':
        lobby = GameLobbyState.fromJson(msg.payload);
        _lobbyCtrl.add(lobby);
        _setStatus('Lobby ${lobby.sessionCode} · ${lobby.players.length} players');
        break;
      case 'selectGame':
        lobby.selectedGame = GameIdX.fromWire(msg.payload['gameId'] as String?);
        _lobbyCtrl.add(lobby);
        break;
      case 'startGame':
        lobby.selectedGame = GameIdX.fromWire(msg.payload['gameId'] as String?);
        lobby.phase = LobbyPhase.playing;
        _lobbyCtrl.add(lobby);
        break;
    }
  }

  void setReady() {
    if (isHosting) {
      final idx = lobby.players.indexWhere((p) => p.id == _me.id);
      if (idx >= 0) lobby.players[idx].isReady = true;
      _broadcastLobby();
    } else {
      _client?.sink.add(WireMessage.ready(_me.id).encode());
    }
  }

  void _broadcastLobby() {
    _lobbyCtrl.add(lobby);
    _broadcast(WireMessage.lobby(lobby));
  }

  void _broadcast(WireMessage msg) {
    final encoded = msg.encode();
    for (final s in List<WebSocketChannel>.from(_sockets)) {
      try {
        s.sink.add(encoded);
      } catch (_) {}
    }
  }

  Future<void> leave() async {
    for (final s in _sockets) {
      await s.sink.close();
    }
    _sockets.clear();
    await _client?.sink.close();
    _client = null;
    await _server?.close(force: true);
    _server = null;
    lobby = GameLobbyState(sessionCode: '', hostName: '');
    _setStatus('Left session');
  }

  Future<String?> _lanIp() async {
    try {
      return await NetworkInfo().getWifiIP();
    } catch (_) {
      try {
        for (final iface in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) return addr.address;
          }
        }
      } catch (_) {}
      return null;
    }
  }

  static String _makeCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = DateTime.now().microsecondsSinceEpoch;
    return List.generate(4, (i) => alphabet[(r + i * 17) % alphabet.length]).join();
  }

  void dispose() {
    leave();
    _lobbyCtrl.close();
    _statusCtrl.close();
  }
}
