import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';

mixin PassAndPlayMixin<T extends StatefulWidget> on State<T> {
  int currentPlayer = 0;
  bool showResult = false;
  String? resultTitle;
  String? resultDetail;

  int get playerCount => context.read<AppState>().playerCount;

  void award(int winner) {
    context.read<AppState>().awardWin(winner);
  }

  void nextPlayer() {
    setState(() => currentPlayer = (currentPlayer + 1) % playerCount);
  }

  void finishMatch(int winner, {String? detail}) {
    award(winner);
    setState(() {
      showResult = true;
      resultTitle = '${PartyTheme.playerName(winner)} wins!';
      resultDetail = detail ?? 'Nice round.';
    });
  }

  void restartRound() {
    setState(() {
      currentPlayer = 0;
      showResult = false;
      resultTitle = null;
      resultDetail = null;
    });
    onRoundReset();
  }

  void onRoundReset();

  Widget turnBanner(String message) => TurnBanner(playerIndex: currentPlayer, message: message);

  Widget? resultOverlay(VoidCallback onAgain) {
    if (!showResult) return null;
    return ResultOverlay(
      title: resultTitle ?? 'Done',
      detail: resultDetail ?? '',
      onAgain: () {
        restartRound();
        onAgain();
      },
      onDone: () => Navigator.of(context).pop(),
    );
  }
}