import 'dart:math';

import 'package:flutter/material.dart';

/// Court-space shot simulator (z toward hoop). Inspired by MIT flick basketball
/// (FaridSafi/react-native-basketball) and canvas gravity arc games — not a copy.
class BallSim {
  BallSim({
    this.x = 0,
    this.y = 2.0,
    this.z = 0,
    this.vx = 0,
    this.vy = 0,
    this.vz = 0,
    this.live = false,
  });

  double x;
  double y;
  double z;
  double vx;
  double vy;
  double vz;
  bool live;
  int rimHits = 0;
  double spin = 0;

  static const rimZ = 9.85;
  static const rimY = 3.05;
  static const rimR = 0.42;
  static const gravity = 14.8;
  static const dt = 1 / 120;

  void reset() {
    x = 0;
    y = 2.0;
    z = 0;
    vx = vy = vz = 0;
    live = false;
    rimHits = 0;
    spin = 0;
  }

  /// Pull-back + release flick → launch (slingshot).
  static ({double vx, double vy, double vz, double power}) impulseFromSwipe(
    Offset pull,
    Offset flickPxPerSec,
  ) {
    if (pull.distance < 10 && flickPxPerSec.distance < 90) {
      return (vx: 0, vy: 0, vz: 0, power: 0);
    }
    final power = ((pull.distance / 88) + (flickPxPerSec.distance / 1300)).clamp(0.35, 1.45);

    var dir = Offset.zero;
    if (pull.distance > 8) dir += Offset(-pull.dx, -pull.dy);
    if (flickPxPerSec.distance > 70) dir += Offset(flickPxPerSec.dx, flickPxPerSec.dy) * 0.038;
    if (dir.distance < 12) return (vx: 0, vy: 0, vz: 0, power: 0);
    dir /= dir.distance;

    final vx = dir.dx * 8.2 * power;
    final vz = -dir.dy * 14.5 * power;
    final vy = 5.2 + power * 5.4 + max(0, -dir.dy) * 2.2;
    return (vx: vx, vy: vy, vz: vz, power: power);
  }

  void launchFromSwipe(Offset pull, Offset flickPxPerSec) {
    final imp = impulseFromSwipe(pull, flickPxPerSec);
    if (imp.power <= 0) return;
    x = 0;
    y = 2.0;
    z = 0;
    vx = imp.vx;
    vy = imp.vy;
    vz = imp.vz;
    spin = flickPxPerSec.distance * 0.01;
    live = true;
    rimHits = 0;
  }

  void launchCpu(Random rng, double hoopX) {
    final err = (rng.nextDouble() - 0.5) * 1.2;
    final power = 0.75 + rng.nextDouble() * 0.35;
    x = 0;
    y = 2.0;
    z = 0;
    vx = hoopX * 0.35 + err;
    vz = 11.5 * power;
    vy = 5.8 + power * 4;
    spin = 0;
    live = true;
    rimHits = 0;
  }

  /// Outcome after a step batch (call step() until returns non-null).
  ShotEvent? step(double hoopX) {
    if (!live) return null;

    vy -= gravity * dt;
    final drag = pow(0.9992, dt * 60);
    vx *= drag;
    vz *= drag;
    x += vx * dt;
    y += vy * dt;
    z += vz * dt;
    spin *= 0.995;

    if (y < 0.2) {
      y = 0.2;
      vy = -vy * 0.42;
      vz *= 0.85;
    }

    final nearRim = z >= rimZ - 0.35 && z <= rimZ + 0.45;
    final descending = vy < 0 || rimHits > 0;

    if (nearRim && descending) {
      final dx = x - hoopX;
      final dy = y - rimY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < rimR + 0.12) {
        if (dist < rimR * 0.58 && rimHits < 2 && vy <= 0.5) {
          live = false;
          return ShotEvent.scored(bank: rimHits > 0 || dist > rimR * 0.35);
        }
        if (rimHits < 4) {
          rimHits++;
          final n = max(dist, 0.001);
          final nx = dx / n;
          final ny = dy / n;
          const rest = 0.48;
          final vDot = vx * nx + vy * ny;
          vx = (vx - 2 * vDot * nx) * rest;
          vy = (vy - 2 * vDot * ny) * rest;
          vz = -vz.abs() * 0.2;
          z = rimZ - 0.25;
          return ShotEvent.rim();
        }
        live = false;
        return ShotEvent.miss();
      }
    }

    if (z > 11.5 || y < -1 || x.abs() > 6) {
      live = false;
      return ShotEvent.miss();
    }
    return null;
  }

  List<Vec3> predictArc(Offset pull, Offset flick, double hoopX, {int steps = 28}) {
    final clone = BallSim()
      ..launchFromSwipe(pull, flick);
    if (!clone.live) return [];
    final pts = <Vec3>[];
    for (var i = 0; i < steps; i++) {
      final ev = clone.step(hoopX);
      pts.add(Vec3(clone.x, clone.y, clone.z));
      if (ev != null) break;
    }
    return pts;
  }
}

class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

enum ShotKind { scored, rim, miss }

class ShotEvent {
  const ShotEvent._(this.kind, {this.bank = false});
  final ShotKind kind;
  final bool bank;
  factory ShotEvent.scored({bool bank = false}) => ShotEvent._(ShotKind.scored, bank: bank);
  factory ShotEvent.rim() => ShotEvent._(ShotKind.rim);
  factory ShotEvent.miss() => ShotEvent._(ShotKind.miss);
}