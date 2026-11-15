import 'package:flutter/foundation.dart';

import '../networking/local_host.dart';
import 'game_registry.dart';

class AppState extends ChangeNotifier {
  AppState() {
    localHost.lobbyStream.listen((_) => notifyListeners());
    localHost.statusStream.listen((_) => notifyListeners());
  }

  int playerCount = 2;
  final scores = <int>[0, 0, 0, 0];
  final localHost = LocalHostController();

  void setPlayerCount(int count) {
    playerCount = count.clamp(1, 4);
    for (var i = 0; i < 4; i++) {
      scores[i] = 0;
    }
    notifyListeners();
  }

  void awardWin(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= playerCount) return;
    scores[playerIndex] += 1;
    notifyListeners();
  }

  Future<void> hostLocal({String name = 'Host'}) => localHost.hostSession(displayName: name);

  Future<void> joinLocal({
    required String code,
    String? ip,
    int port = 7423,
    String name = 'Player',
  }) =>
      localHost.joinSession(code: code, hostIp: ip, port: port, displayName: name);

  GameDefinition? get selectedLobbyGame {
    final id = localHost.lobby.selectedGame;
    return id == null ? null : GameRegistry.byId(id);
  }

  @override
  void dispose() {
    localHost.dispose();
    super.dispose();
  }
}
