import 'dart:math';

import 'package:flutter/material.dart';

/// Shared court constants + perspective projection (pseudo-3D).
class CourtWorld {
  static const rimZ = 9.85;
  static const rimY = 3.05;
  static const rimR = 0.42;
  static const gravity = 15.2;
  static const floorY = 0.18;
  static const spawn = Vec3(0, 2.05, 0);
  static const fixedDt = 1 / 120;

  static Offset project(Vec3 p, Size size) {
    final t = (p.z / 10).clamp(0.0, 1.25);
    final cx = size.width / 2;
    final floor = size.height * 0.86;
    final horizon = size.height * 0.26;
    final depth = 1.0 - t * 0.5;
    return Offset(cx + p.x * 54 * depth, floor + (horizon - floor) * t - p.y * 36 * depth);
  }

  static double ballRadius(Vec3 p) {
    final t = (p.z / 10).clamp(0.0, 1.0);
    return 20 * (0.5 + (1 - t) * 0.65);
  }

  static double hoopSway(double time, HoopDifficulty difficulty) {
    final amp = switch (difficulty) {
      HoopDifficulty.easy => 0.0,
      HoopDifficulty.medium => 0.75,
      HoopDifficulty.hard => 1.35,
    };
    final speed = switch (difficulty) {
      HoopDifficulty.easy => 0.0,
      HoopDifficulty.medium => 0.75,
      HoopDifficulty.hard => 1.45,
    };
    return sin(time * speed) * amp;
  }
}

class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
  Vec3 addVel(double vx, double vy, double vz) => Vec3(x + vx, y + vy, z + vz);
}

enum HoopDifficulty { easy, medium, hard }

extension HoopDifficultyLabel on HoopDifficulty {
  String get label => switch (this) {
        HoopDifficulty.easy => 'EASY',
        HoopDifficulty.medium => 'MEDIUM',
        HoopDifficulty.hard => 'HARD',
      };
  String get hint => switch (this) {
        HoopDifficulty.easy => 'Static hoop',
        HoopDifficulty.medium => 'Slow sway',
        HoopDifficulty.hard => 'Fast sway',
      };
}