import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Fixed-step friendly game loop (~60fps) for smoother web play.
mixin GameTickMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool tickPaused = false;

  void onGameTick(double dt);

  void startTick() {
    _ticker ??= createTicker(_onTick)..start();
    _last = Duration.zero;
  }

  void stopTick() {
    _ticker?.stop();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || tickPaused) {
      _last = elapsed;
      return;
    }
    final raw = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final dt = raw.clamp(0.0, 1 / 30);
    onGameTick(dt);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}