import 'dart:math';

import 'package:flutter/material.dart';

import 'world.dart';

/// Launch inferred only from release flick (no pull-back aim).
class ShotController {
  static const minFlick = 90.0;

  static ({double vx, double vy, double vz, double spin}) fromFlick(
    Offset flickPxPerSec,
    double startX, {
    double hoopX = 0,
    bool aimAssist = false,
  }) {
    final speed = flickPxPerSec.distance;
    if (speed < minFlick || flickPxPerSec.dy > -35) {
      return (vx: 0, vy: 0, vz: 0, spin: 0);
    }

    final power = (speed / 1300).clamp(0.45, 1.12);
    final up = (-flickPxPerSec.dy / speed).clamp(0.35, 1.0);
    final nx = flickPxPerSec.dx / speed;

    // Depth speed scales with flick power; vy chosen so arc meets rim height near z=rimZ.
    final vz = 8.4 + power * up * 2.6;
    final flightT = CourtWorld.rimZ / vz;
    var vy = (CourtWorld.rimY - CourtWorld.spawn.y + 0.5 * CourtWorld.gravity * flightT * flightT) / flightT;
    vy *= 0.94 + power * 0.08;

    var vx = nx * 5.5 * power;

    if (aimAssist) {
      vx += (hoopX - startX).clamp(-1.8, 1.8) * 0.85;
    } else {
      vx += startX * 0.08;
    }

    final spin = speed * 0.00012;
    return (vx: vx, vy: vy, vz: vz, spin: spin);
  }
}