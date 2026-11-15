import 'dart:convert';

import '../core/game_registry.dart';

const localHostPort = 7423;
const joinScheme = 'localhostparty';

class LobbyPlayer {
  LobbyPlayer({
    required this.id,
    required this.displayName,
    this.isHost = false,
    this.isReady = false,
  });

  final String id;
  String displayName;
  bool isHost;
  bool isReady;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'isHost': isHost,
        'isReady': isReady,
      };

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) => LobbyPlayer(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? 'Player',
        isHost: json['isHost'] as bool? ?? false,
        isReady: json['isReady'] as bool? ?? false,
      );
}

enum LobbyPhase { lobby, playing, results }

class GameLobbyState {
  GameLobbyState({
    required this.sessionCode,
    required this.hostName,
    List<LobbyPlayer>? players,
    this.selectedGame,
    this.phase = LobbyPhase.lobby,
    this.hostIp,
    this.port = localHostPort,
  }) : players = players ?? [];

  String sessionCode;
  String hostName;
  List<LobbyPlayer> players;
  GameId? selectedGame;
  LobbyPhase phase;
  String? hostIp;
  int port;

  Map<String, dynamic> toJson() => {
        'sessionCode': sessionCode,
        'hostName': hostName,
        'players': players.map((p) => p.toJson()).toList(),
        'selectedGame': selectedGame?.wireName,
        'phase': phase.name,
        'hostIp': hostIp,
        'port': port,
      };

  factory GameLobbyState.fromJson(Map<String, dynamic> json) => GameLobbyState(
        sessionCode: json['sessionCode'] as String? ?? '',
        hostName: json['hostName'] as String? ?? '',
        players: (json['players'] as List<dynamic>? ?? [])
            .map((e) => LobbyPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        selectedGame: GameIdX.fromWire(json['selectedGame'] as String?),
        phase: LobbyPhase.values.firstWhere(
          (p) => p.name == json['phase'],
          orElse: () => LobbyPhase.lobby,
        ),
        hostIp: json['hostIp'] as String?,
        port: json['port'] as int? ?? localHostPort,
      );

  String get qrPayload {
    final ip = hostIp ?? '127.0.0.1';
    return '$joinScheme://join?code=$sessionCode&ip=$ip&port=$port&name=${Uri.encodeComponent(hostName)}';
  }

  static GameLobbyState? parseJoin(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    if (uri.scheme != joinScheme || uri.host != 'join') {
      // Also accept bare codes or ws urls
      if (RegExp(r'^[A-Z0-9]{4}$').hasMatch(raw.trim().toUpperCase())) {
        return GameLobbyState(sessionCode: raw.trim().toUpperCase(), hostName: 'Host');
      }
      return null;
    }
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) return null;
    return GameLobbyState(
      sessionCode: code.toUpperCase(),
      hostName: uri.queryParameters['name'] ?? 'Host',
      hostIp: uri.queryParameters['ip'],
      port: int.tryParse(uri.queryParameters['port'] ?? '') ?? localHostPort,
    );
  }
}

class WireMessage {
  WireMessage(this.type, [this.payload = const {}]);

  final String type;
  final Map<String, dynamic> payload;

  String encode() => jsonEncode({'type': type, 'payload': payload});

  factory WireMessage.decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return WireMessage(
      map['type'] as String,
      Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
    );
  }

  static WireMessage hello(LobbyPlayer player) =>
      WireMessage('hello', player.toJson());

  static WireMessage lobby(GameLobbyState state) =>
      WireMessage('lobby', state.toJson());

  static WireMessage selectGame(GameId id) =>
      WireMessage('selectGame', {'gameId': id.wireName});

  static WireMessage startGame(GameId id) =>
      WireMessage('startGame', {'gameId': id.wireName});

  static WireMessage ready(String playerId) =>
      WireMessage('ready', {'playerId': playerId});

  static WireMessage gameEvent(GameId id, String event, [Map<String, dynamic>? data]) =>
      WireMessage('gameEvent', {
        'gameId': id.wireName,
        'event': event,
        ...?data,
      });
}
