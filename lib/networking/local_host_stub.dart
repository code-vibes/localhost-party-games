import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/game_registry.dart';
import 'protocol.dart';

/// Web-safe controller: can join via WebSocket, cannot bind a LAN host socket.
class LocalHostController {
  LocalHostController();

  final _uuid = const Uuid();
  WebSocketChannel? _client;
  late LobbyPlayer _me;
  GameLobbyState lobby = GameLobbyState(sessionCode: '', hostName: '');
  bool get isHosting => false;
  bool get isClient => _client != null;
  bool get canHost => false;
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
    lastError =
        'Web browsers cannot host LAN sockets. Host from the Android/iOS app, or run `dart run tool/lan_host.dart` on this machine.';
    _setStatus(lastError!);
  }

  void selectGame(GameId id) {}

  void startSelectedGame() {}

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
        if (msg.type == 'lobby') {
          lobby = GameLobbyState.fromJson(msg.payload);
          _lobbyCtrl.add(lobby);
          _setStatus('Lobby ${lobby.sessionCode} · ${lobby.players.length} players');
        } else if (msg.type == 'selectGame') {
          lobby.selectedGame = GameIdX.fromWire(msg.payload['gameId'] as String?);
          _lobbyCtrl.add(lobby);
        } else if (msg.type == 'startGame') {
          lobby.selectedGame = GameIdX.fromWire(msg.payload['gameId'] as String?);
          lobby.phase = LobbyPhase.playing;
          _lobbyCtrl.add(lobby);
        }
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

  void setReady() {
    _client?.sink.add(WireMessage.ready(_me.id).encode());
  }

  Future<void> leave() async {
    await _client?.sink.close();
    _client = null;
    lobby = GameLobbyState(sessionCode: '', hostName: '');
    _setStatus('Left session');
  }

  void dispose() {
    leave();
    _lobbyCtrl.close();
    _statusCtrl.close();
  }
}
