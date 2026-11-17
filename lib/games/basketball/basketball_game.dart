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

  Offset _dragStart = Offset.zero;
  Offset _dragPull = Offset.zero;
  bool _dragging = false;
  List<Vec3> _preview = const [];
  Offset _lastPtr = Offset.zero;
  DateTime? _lastPtrAt;
  Offset _ptrVel = Offset.zero;

  final _ready = Vec3(CourtWorld.spawn.x, CourtWorld.spawn.y, CourtWorld.spawn.z);
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
          if (r == false && _popup == null) _popup = null;
        }
        if (r != null) break;
      }
      if (b.live) {
        contacts.add(CourtWorld.project(Vec3(b.x, b.y, b.z), _viewSize));
      }
    }
    _net.step(dt, contacts);

    if (_dragging) {
      final flick = _ptrVel;
      final ghost = FlyingBall.spawnFlying(_dragPull, flick);
      _preview = ghost.live ? ghost.predictArc(_dragPull, flick, _hoopX) : const [];
    }

    if (mounted) setState(() {});
  }

  void _endRound() {
    _ended = true;
    _playing = false;
    if (_baskets > _best) _best = _baskets;
    setState(() {});
  }

  void _shoot() {
    if (!_playing || _ended) return;
    final flick = _ptrVel;
    final ball = FlyingBall.spawnFlying(_dragPull, flick);
    if (ball.live) {
      _flying.add(ball);
    }
    _dragging = false;
    _dragPull = Offset.zero;
    _preview = const [];
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF6BB5E8),
      appBar: AppBar(
        title: const Text('BASKETBLAST · 60s'),
        actions: [
          if (_best > 0) Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: Text('BEST $_best', style: const TextStyle(fontWeight: FontWeight.w800)))),
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
                  message: '${_difficulty!.label} · ${_difficulty!.hint} · swipe up to shoot · queue enabled',
                ),
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) {
                      if (!_playing || _ended) return;
                      _dragStart = e.localPosition;
                      _lastPtr = e.localPosition;
                      _lastPtrAt = DateTime.now();
                      _ptrVel = Offset.zero;
                      _dragging = true;
                      _dragPull = Offset.zero;
                    },
                    onPointerMove: (e) {
                      if (!_dragging) return;
                      final now = DateTime.now();
                      if (_lastPtrAt != null) {
                        final dt = now.difference(_lastPtrAt!).inMicroseconds / 1e6;
                        if (dt > 0.001) _ptrVel = (e.localPosition - _lastPtr) / dt;
                      }
                      _lastPtr = e.localPosition;
                      _lastPtrAt = now;
                      _dragPull = e.localPosition - _dragStart;
                    },
                    onPointerUp: (_) {
                      if (_dragging) _shoot();
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
                          previewArc: _preview,
                          net: _net,
                          aimPull: _dragging ? _dragPull : null,
                          dragging: _dragging,
                        ),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (_dragging)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_dragPull.distance / 140).clamp(0, 1),
                        minHeight: 10,
                        color: const Color(0xFFE53935),
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
            const Text('Make as many baskets as you can. Balls queue instantly — keep flicking!'),
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