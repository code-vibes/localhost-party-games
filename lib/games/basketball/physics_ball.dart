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
  FlyingBall._flying(this.id) : live = true;

  static int _nextId = 0;

  final int id;
  double x = CourtWorld.spawn.x;
  double y = CourtWorld.spawn.y;
  double z = CourtWorld.spawn.z;
  double vx = 0;
  double vy = 0;
  double vz = 0;
  bool live = false;
  int rimHits = 0;
  bool scored = false;
  bool counted = false;
  final rotation = BallRotation();
  double _wx = 0;
  double _wy = 0;
  double _wz = 0;

  static FlyingBall spawnFlying(
    Offset flick,
    double startX, {
    double hoopX = 0,
    bool aimAssist = false,
  }) {
    final b = FlyingBall._flying(_nextId++);
    final imp = ShotController.fromFlick(flick, startX, hoopX: hoopX, aimAssist: aimAssist);
    if (imp.vz <= 0) return b..live = false;

    b.x = startX;
    b.y = CourtWorld.spawn.y;
    b.z = CourtWorld.spawn.z;
    b.vx = imp.vx;
    b.vy = imp.vy;
    b.vz = imp.vz;
    b.live = true;
    b.rimHits = 0;
    b.scored = false;
    b.counted = false;
    b._wx = imp.vx * 1.8;
    b._wy = imp.spin;
    b._wz = imp.vz * 0.35;
    return b;
  }

  /// null = still flying, true = basket, false = dead miss
  bool? step(double hoopX, void Function(Vec3 pos, double radius) netHit) {
    if (!live) return scored ? true : false;

    const substeps = 3;
    for (var s = 0; s < substeps; s++) {
      vy -= CourtWorld.gravity * CourtWorld.fixedDt;
      final drag = pow(0.999, CourtWorld.fixedDt * 60);
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
      if (vy < -0.35) {
        vy = -vy * 0.52;
        vx *= 0.74;
        vz *= 0.8;
        _wy += 3;
        netHit(Vec3(x, y, z), CourtWorld.rimR * 0.7);
      } else {
        live = false;
        return scored ? true : false;
      }
    }

    final atRimPlane = z >= CourtWorld.rimZ - 0.08 && z <= CourtWorld.rimZ + 0.5;
    if (atRimPlane) {
      final dx = x - hoopX;
      final dy = y - CourtWorld.rimY;
      final dist = sqrt(dx * dx + dy * dy);
      final outer = CourtWorld.rimR + 0.28;

      if (dist < outer) {
        final inCylinder = dist < CourtWorld.rimR * 0.78 && dy.abs() < 0.85;
        final descending = vy < 2.5;
        if (inCylinder && descending && rimHits < 4) {
          scored = true;
          live = false;
          netHit(Vec3(x, CourtWorld.rimY, CourtWorld.rimZ), CourtWorld.rimR * 0.5);
          return true;
        }
        if (dist < outer && rimHits < 6) {
          rimHits++;
          final n = max(dist, 0.001);
          final nx = dx / n;
          final ny = dy / n;
          const rest = 0.58;
          final vd = vx * nx + vy * ny;
          vx = (vx - 2 * vd * nx) * rest;
          vy = (vy - 2 * vd * ny) * rest;
          if (z > CourtWorld.rimZ) vz = -vz.abs() * 0.25;
          z = min(z, CourtWorld.rimZ - 0.15);
          _wy += 5;
          netHit(Vec3(x, CourtWorld.rimY, CourtWorld.rimZ), CourtWorld.rimR * 0.5);
        } else if (z > CourtWorld.rimZ + 0.3) {
          live = false;
          return false;
        }
      }
    }

    if (z > 11.5 || x.abs() > 7.5 || y < -2) {
      live = false;
      return scored ? true : false;
    }
    return null;
  }
}