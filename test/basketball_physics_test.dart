import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localhost_party_games/games/basketball/physics_ball.dart';
import 'package:localhost_party_games/games/basketball/world.dart';

void main() {
  test('Easy upward flick scores from center', () {
    const hoopX = 0.0;
    var scored = 0;
    for (var i = 0; i < 20; i++) {
      final flick = Offset((i - 10) * 40.0, -900 - i * 20.0);
      final b = FlyingBall.spawnFlying(flick, 0, hoopX: hoopX, aimAssist: true);
      if (!b.live) continue;
      for (var s = 0; s < 8000; s++) {
        final r = b.step(hoopX, (_, __) {});
        if (r == true) {
          scored++;
          break;
        }
        if (r == false) break;
      }
    }
    expect(scored, greaterThanOrEqualTo(4));
  });
}