import 'dart:math';

import 'package:flutter/material.dart';

import 'shot_controller.dart';
import 'world.dart';

class BallRotation {
  double yaw = 0;
  double pitch = 0;
  double roll = 0;

  void integrate(double dt, double wx, double wy, double wz) {
    yaw += wx * dt;
    pitch += wy * dt;
    roll += wz * dt;
  }
}

class FlyingBall {
  FlyingBall.spawn()
      : x = CourtWorld.spawn.x,
        y = CourtWorld.spawn.y,
        z = CourtWorld.spawn.z,
        live = false,
        id = _nextId++;

  FlyingBall._flying(this.id)
      : x = CourtWorld.spawn.x,
        y = CourtWorld.spawn.y,
        z = CourtWorld.spawn.z,
        live = true;

  static int _nextId = 0;

  final int id;
  double x;
  double y;
  double z;
  double vx = 0;
  double vy = 0;
  double vz = 0;
  bool live;
  int rimHits = 0;
  bool scored = false;
  bool counted = false;
  final rotation = BallRotation();
  double _wx = 0;
  double _wy = 0;
  double _wz = 0;

  bool get onFloor => !live && y <= CourtWorld.floorY + 0.05;

  void launch(Offset pull, Offset flick) {
    final imp = ShotController.launchVelocity(pull, flick);
    if (imp.vx == 0 && imp.vy == 0 && imp.vz == 0) return;
    x = CourtWorld.spawn.x;
    y = CourtWorld.spawn.y;
    z = CourtWorld.spawn.z;
    vx = imp.vx;
    vy = imp.vy;
    vz = imp.vz;
    live = true;
    rimHits = 0;
    scored = false;
    counted = false;
    _wx = imp.vx * 2.2;
    _wy = imp.spin;
    _wz = imp.vz * 0.4;
  }

  static FlyingBall spawnFlying(Offset pull, Offset flick) {
    final b = FlyingBall._flying(_nextId++);
    b.launch(pull, flick);
    return b;
  }

  /// null = still flying, true = basket, false = dead miss
  bool? step(double hoopX, void Function(Vec3 pos, double radius) netHit) {
    if (!live) return scored ? true : false;

    const substeps = 2;
    for (var s = 0; s < substeps; s++) {
      vy -= CourtWorld.gravity * CourtWorld.fixedDt;
      final drag = pow(0.9988, CourtWorld.fixedDt * 60);
      vx *= drag;
      vz *= drag;
      x += vx * CourtWorld.fixedDt;
      y += vy * CourtWorld.fixedDt;
      z += vz * CourtWorld.fixedDt;
      rotation.integrate(CourtWorld.fixedDt, _wx, _wy, _wz);
      _wy *= 0.998;
    }

    if (y <= CourtWorld.floorY) {
      y = CourtWorld.floorY;
      if (vy < -0.5) {
        vy = -vy * 0.55;
        vx *= 0.72;
        vz *= 0.78;
        _wy += 4;
        netHit(Vec3(x, y, z), CourtWorld.rimR * 0.7);
      } else {
        live = false;
        return scored ? true : false;
      }
    }

    final nearRim = z >= CourtWorld.rimZ - 0.4 && z <= CourtWorld.rimZ + 0.55;
    if (nearRim && vy < 1.2) {
      final dx = x - hoopX;
      final dy = y - CourtWorld.rimY;
      final dist = sqrt(dx * dx + dy * dy);
      final ballR = CourtWorld.rimR * 0.55;
      if (dist < CourtWorld.rimR + ballR * 0.5) {
        if (dist < CourtWorld.rimR * 0.52 && vy < 0.5 && rimHits < 3) {
          scored = true;
          live = false;
          netHit(Vec3(x, CourtWorld.rimY, CourtWorld.rimZ), ballR);
          return true;
        }
        if (rimHits < 5) {
          rimHits++;
          final n = max(dist, 0.001);
          final nx = dx / n;
          final ny = dy / n;
          const rest = 0.52;
          final vd = vx * nx + vy * ny;
          vx = (vx - 2 * vd * nx) * rest;
          vy = (vy - 2 * vd * ny) * rest;
          vz *= 0.15;
          z = CourtWorld.rimZ - 0.3;
          _wy += 6;
          netHit(Vec3(x, CourtWorld.rimY, CourtWorld.rimZ), ballR);
        } else {
          live = false;
          return false;
        }
      }
    }

    if (z > 12 || x.abs() > 7 || y < -2) {
      live = false;
      return scored ? true : false;
    }
    return null;
  }

  List<Vec3> predictArc(Offset pull, Offset flick, double hoopX, {int steps = 32}) {
    final ghost = FlyingBall._flying(-1);
    ghost.launch(pull, flick);
    if (!ghost.live) return [];
    final pts = <Vec3>[];
    for (var i = 0; i < steps; i++) {
      final r = ghost.step(hoopX, (_, __) {});
      pts.add(Vec3(ghost.x, ghost.y, ghost.z));
      if (r != null) break;
    }
    return pts;
  }
}