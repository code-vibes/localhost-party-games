import 'dart:math';

import 'package:flutter/material.dart';

/// Slingshot mapping (NotchBasket ShotController — physics inspiration only).
class ShotController {
  static const minDrag = 12.0;
  static const maxDrag = 155.0;
  static const powerMult = 14.5;
  static const maxSpeed = 2800.0;

  static Offset clampedDrag(Offset pull) {
    final len = pull.distance;
    if (len <= maxDrag || len == 0) return pull;
    return pull * (maxDrag / len);
  }

  /// Returns world-space launch (vx, vy, vz) and spin impulse.
  static ({double vx, double vy, double vz, double spin}) launchVelocity(
    Offset pull,
    Offset flickPxPerSec,
  ) {
    var drag = clampedDrag(pull);
    if (drag.distance < minDrag && flickPxPerSec.distance < 60) {
      return (vx: 0, vy: 0, vz: 0, spin: 0);
    }

    var launch = Offset(-drag.dx, -drag.dy);
    if (flickPxPerSec.distance > 80) {
      launch += Offset(flickPxPerSec.dx, flickPxPerSec.dy) * 0.028;
    }
  final len = launch.distance;
    if (len < 1) return (vx: 0, vy: 0, vz: 0, spin: 0);
    if (len > maxSpeed) launch *= maxSpeed / len;

    final power = (len / (maxDrag * powerMult)).clamp(0.25, 1.35);
    final vx = launch.dx * 0.0042 * powerMult * power;
    final vz = 7.8 + power * 7.2 + max(0, launch.dy) * 0.006;
    final vy = 4.8 + power * 5.6 + launch.dy * 0.0038;
    final spin = len * 0.00035 + flickPxPerSec.distance * 0.00012;
    return (vx: vx, vy: vy, vz: vz, spin: spin);
  }
}