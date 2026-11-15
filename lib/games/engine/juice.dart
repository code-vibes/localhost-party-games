import 'package:flutter/material.dart';

class HitFlash extends StatefulWidget {
  const HitFlash({super.key, required this.child, required this.trigger});
  final Widget child;
  final int trigger;

  @override
  State<HitFlash> createState() => _HitFlashState();
}

class _HitFlashState extends State<HitFlash> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant HitFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

class FloatingCallout extends StatelessWidget {
  const FloatingCallout({super.key, required this.text, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Opacity(
        opacity: (1 - t).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -36 * t),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: color ?? Colors.white,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }
}

class JuiceButton extends StatefulWidget {
  const JuiceButton({super.key, required this.label, required this.onPressed, this.color});
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  State<JuiceButton> createState() => _JuiceButtonState();
}

class _JuiceButtonState extends State<JuiceButton> with SingleTickerProviderStateMixin {
  late AnimationController _p;

  @override
  void initState() {
    super.initState();
    _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 90), lowerBound: 0.92, upperBound: 1);
    _p.value = 1;
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _p.reverse(),
      onTapUp: (_) {
        _p.forward();
        widget.onPressed?.call();
      },
      onTapCancel: () => _p.forward(),
      child: ScaleTransition(
        scale: _p,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color ?? const Color(0xFF2E333D),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}