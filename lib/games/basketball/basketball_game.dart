import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../engine/game_tick.dart';
import '../engine/juice.dart';
import '../game_router.dart';
import 'court_scene.dart';
import 'net_mesh.dart';
import 'physics_ball.dart';
import 'world.dart';

class BasketballGame extends StatefulWidget {
  const BasketballGame({super.key});
  @override
  State<BasketballGame> createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame> with TickerProviderStateMixin, GameTickMixin {
  static const _roundSeconds = 60.0;

  HoopDifficulty? _difficulty;
  bool _playing = false;
  bool _ended = false;
  double _timeLeft = _roundSeconds;
  int _baskets = 0;
  int _best = 0;
  String? _popup;

  double _hoopPhase = 0;
  double _hoopX = 0;
  final _flying = <FlyingBall>[];
  final _net = NetMesh();

  bool _holding = false;
  Vec3 _ready = CourtWorld.spawn;
  Offset _downPtr = Offset.zero;
  Offset _lastPtr = Offset.zero;
  DateTime? _lastPtrAt;
  Offset _ptrVel = Offset.zero;

  Size _viewSize = const Size(400, 700);

  @override
  void initState() {
    super.initState();
    startTick();
  }

  void _startRound(HoopDifficulty d) {
    setState(() {
      _difficulty = d;
      _playing = true;
      _ended = false;
      _timeLeft = _roundSeconds;
      _baskets = 0;
      _flying.clear();
      _popup = null;
      _hoopPhase = 0;
      _ready = CourtWorld.spawn;
    });
  }

  @override
  void onGameTick(double dt) {
    if (!_playing || _ended || _difficulty == null) return;

    _hoopPhase += dt;
    _hoopX = CourtWorld.hoopSway(_hoopPhase, _difficulty!);
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _endRound();
      return;
    }

    final hoopScreen = CourtWorld.project(Vec3(_hoopX, CourtWorld.rimY, CourtWorld.rimZ), _viewSize);
    _net.pinToHoop(hoopScreen, 36);
    final contacts = <Offset>[];
    for (final b in _flying.toList()) {
      for (var i = 0; i < 4; i++) {
        final r = b.step(_hoopX, (_, __) {});
        if (r == true && !b.counted) {
          b.counted = true;
          _baskets++;
          _popup = 'SWISH!';
          Future<void>.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _popup = null);
          });
          final bp = CourtWorld.project(Vec3(b.x, b.y, b.z), _viewSize);
          _net.impulseAt(bp, 18);
        }
        if (r != null && !b.live) {
          _flying.remove(b);
        }
        if (r != null) break;
      }
      if (b.live) {
        contacts.add(CourtWorld.project(Vec3(b.x, b.y, b.z), _viewSize));
      }
    }
    _net.step(dt, contacts);

    if (mounted) setState(() {});
  }

  void _endRound() {
    _ended = true;
    _playing = false;
    if (_baskets > _best) _best = _baskets;
    setState(() {});
  }

  void _shoot() {
    if (!_playing || _ended || _difficulty == null) return;
    final ball = FlyingBall.spawnFlying(
      _ptrVel,
      _ready.x,
      hoopX: _hoopX,
      aimAssist: _difficulty!.aimAssist,
    );
    if (ball.live) {
      _flying.add(ball);
    }
    _holding = false;
    _ready = CourtWorld.spawn;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF6BB5E8),
      appBar: AppBar(
        title: const Text('BASKETBLAST · 60s'),
        actions: [
          if (_best > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: Text('BEST $_best', style: const TextStyle(fontWeight: FontWeight.w800))),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_difficulty == null || (!_playing && !_ended))
            _DifficultyPicker(onPick: _startRound)
          else
            Column(
              children: [
                TurnBanner(
                  playerIndex: 0,
                  message: '${_difficulty!.label} · drag ball sideways · flick up to shoot',
                ),
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) {
                      if (!_playing || _ended) return;
                      _holding = true;
                      _downPtr = e.localPosition;
                      _lastPtr = e.localPosition;
                      _lastPtrAt = DateTime.now();
                      _ptrVel = Offset.zero;
                      _ready = _ready.copyWith(
                        x: CourtWorld.worldXFromScreen(e.localPosition.dx, _viewSize),
                      );
                    },
                    onPointerMove: (e) {
                      if (!_holding) return;
                      final now = DateTime.now();
                      if (_lastPtrAt != null) {
                        final dt = now.difference(_lastPtrAt!).inMicroseconds / 1e6;
                        if (dt > 0.001) _ptrVel = (e.localPosition - _lastPtr) / dt;
                      }
                      _lastPtr = e.localPosition;
                      _lastPtrAt = now;
                      _ready = _ready.copyWith(
                        x: CourtWorld.worldXFromScreen(e.localPosition.dx, _viewSize),
                      );
                    },
                    onPointerUp: (_) {
                      if (!_holding) return;
                      var flick = _ptrVel;
                      final swipe = _lastPtr - _downPtr;
                      if (flick.distance < 140 && swipe.dy < -24) {
                        flick = Offset(swipe.dx * 5.5, swipe.dy * 5.5);
                      }
                      _ptrVel = flick;
                      _shoot();
                    },
                    child: RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          _viewSize = Size(c.maxWidth, c.maxHeight);
                          return CustomPaint(
                            painter: CourtScenePainter(
                              hoopX: _hoopX,
                              timeLeft: _timeLeft,
                              baskets: _baskets,
                              flying: _flying,
                              readyPos: _ready,
                              showReady: _playing && !_ended,
                              net: _net,
                            ),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_popup != null)
            Positioned(
              top: 72,
              left: 0,
              right: 0,
              child: Center(child: FloatingCallout(text: _popup!, color: const Color(0xFFFFB300))),
            ),
          if (_ended)
            ResultOverlay(
              title: 'Time!',
              detail: 'You made $_baskets baskets · Best $_best',
              onAgain: () => _startRound(_difficulty!),
              onDone: () {
                if (_baskets > 0) app.awardWin(0);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.onPick});
  final void Function(HoopDifficulty) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('60 SECOND SHOOTOUT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Drag the ball left or right, then flick up. Keep shooting — balls queue instantly.'),
            const SizedBox(height: 24),
            for (final d in HoopDifficulty.values) ...[
              SizedBox(
                width: double.infinity,
                child: JuiceButton(
                  label: '${d.label} — ${d.hint}',
                  onPressed: () => onPick(d),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}