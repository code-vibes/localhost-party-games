import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Lightweight Verlet net (inspired by NotchBasket NetClothSimulation — 2D slice).
class NetMesh {
  NetMesh({this.rows = 9, this.cols = 13}) {
    _knots = [];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final u = c / (cols - 1);
        final v = r / (rows - 1);
        final halfW = lerpDouble(38, 22, v)!;
        final x = (u - 0.5) * halfW * 2;
        final y = 4 + v * 34;
        final k = _Knot(x, y, pinned: r == 0);
        k.px = x;
        k.py = y;
        _knots.add(k);
      }
    }
    _links = [];
    void add(int a, int b, {double stiff = 0.92}) {
      final ka = _knots[a];
      final kb = _knots[b];
      final rest = sqrt(pow(ka.x - kb.x, 2) + pow(ka.y - kb.y, 2));
      _links.add(_Link(a, b, rest, stiff));
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final i = r * cols + c;
        if (c + 1 < cols) add(i, i + 1);
        if (r + 1 < rows) add(i, i + cols);
        if (r + 1 < rows && c + 1 < cols) add(i, i + cols + 1, stiff: 0.8);
      }
    }
  }

  final int rows;
  final int cols;
  late final List<_Knot> _knots;
  late final List<_Link> _links;

  void pinToHoop(Offset rimCenter, double rimHalfW) {
    for (var c = 0; c < cols; c++) {
      final u = c / (cols - 1);
      final k = _knots[c];
      k.x = rimCenter.dx + (u - 0.5) * rimHalfW * 2;
      k.y = rimCenter.dy + 3;
      k.px = k.x;
      k.py = k.y;
    }
  }

  void impulseAt(Offset onRim, double strength) {
    for (final k in _knots) {
      final d = Offset(k.x - onRim.dx, k.y - onRim.dy).distance;
      if (d < 30) {
        final f = (1 - d / 30) * strength;
        k.vyImpulse -= f;
      }
    }
  }

  void step(double dt, List<Offset> ballScreenContacts) {
    const grav = 220.0;
    for (final k in _knots) {
      if (k.pinned) continue;
      final vx = (k.x - k.px) * 0.982;
      var vy = (k.y - k.py) * 0.982 + grav * dt * dt;
      vy += k.vyImpulse;
      k.vyImpulse = 0;
      k.px = k.x;
      k.py = k.y;
      k.x += vx;
      k.y += vy;
    }
    for (final b in ballScreenContacts) {
      for (final k in _knots) {
        if (k.pinned) continue;
        final dx = k.x - b.dx;
        final dy = k.y - b.dy;
        final d = sqrt(dx * dx + dy * dy);
        if (d < 16 && d > 0.1) {
          final push = (16 - d) * 0.42;
          k.x += dx / d * push;
          k.y += dy / d * push;
        }
      }
    }
    for (var pass = 0; pass < 5; pass++) {
      for (final l in _links) {
        final a = _knots[l.a];
        final b = _knots[l.b];
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final d = sqrt(dx * dx + dy * dy);
        if (d < 0.001) continue;
        final diff = (d - l.rest) / d * 0.48 * l.stiff;
        if (!a.pinned) {
          a.x += dx * diff;
          a.y += dy * diff;
        }
        if (!b.pinned) {
          b.x -= dx * diff;
          b.y -= dy * diff;
        }
      }
    }
  }

  void paint(Canvas canvas, Paint cord) {
    for (final l in _links) {
      final a = _knots[l.a];
      final b = _knots[l.b];
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), cord);
    }
  }
}

class _Knot {
  _Knot(this.x, this.y, {this.pinned = false});
  double x;
  double y;
  double px = 0;
  double py = 0;
  double vyImpulse = 0;
  final bool pinned;
}

class _Link {
  _Link(this.a, this.b, this.rest, this.stiff);
  final int a;
  final int b;
  final double rest;
  final double stiff;
}