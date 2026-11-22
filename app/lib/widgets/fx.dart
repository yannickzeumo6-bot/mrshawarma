import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

/// Délai en cascade pour les listes : 0, 55 ms, 110 ms... (plafonné).
Duration stagger(int i, {int ms = 55, int max = 9}) => Duration(milliseconds: math.min(i < 0 ? 0 : i, max) * ms);

// ---------------------------------------------------------------- Apparition
/// Apparition en fondu + glissement (effet « cascade » avec delay).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.14),
    this.duration = const Duration(milliseconds: 560),
  });
  final Widget child;
  final Duration delay, duration;
  final Offset offset;
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: SlideTransition(position: Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(_a), child: widget.child),
      );
}

// ---------------------------------------------------------------- Toucher
/// Rétrécit légèrement au toucher + vibration légère (effet « bouton vivant »).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.93, this.haptic = true});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(scale: _down ? widget.scale : 1, duration: const Duration(milliseconds: 110), curve: Curves.easeOut, child: widget.child),
      );
}

// ---------------------------------------------------------------- Nombres
/// Compteur animé : le nombre « monte » vers sa valeur (et se met à jour en douceur).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.format, this.style});
  final int value;
  final String Function(int) format;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text(format(v.round()), style: style),
      );
}

/// « Pop » élastique à chaque changement de `trigger` (badge du panier, barre panier...).
class Pop extends StatelessWidget {
  const Pop({super.key, required this.trigger, required this.child});
  final Object trigger;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(trigger),
        tween: Tween<double>(begin: 1.22, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
        builder: (_, s, c) => Transform.scale(scale: s, child: c),
        child: child,
      );
}

// ---------------------------------------------------------------- Boucles
/// Légère respiration (agrandissement/rétrécissement en boucle).
class Breathe extends StatefulWidget {
  const Breathe({super.key, required this.child, this.active = true, this.amount = 0.12});
  final Widget child;
  final bool active;
  final double amount;
  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, c) => Transform.scale(scale: 1 + widget.amount * Curves.easeInOut.transform(_c.value), child: c),
      child: widget.child,
    );
  }
}

/// Flottement vertical doux (logo).
class Floating extends StatefulWidget {
  const Floating({super.key, required this.child, this.amplitude = 6});
  final Widget child;
  final double amplitude;
  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, c) => Transform.translate(offset: Offset(0, widget.amplitude * (Curves.easeInOut.transform(_c.value) - 0.5) * 2), child: c),
        child: widget.child,
      );
}

/// Zoom lent et continu sur une photo (effet « Ken Burns »).
class KenBurns extends StatefulWidget {
  const KenBurns({super.key, required this.child});
  final Widget child;
  @override
  State<KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<KenBurns> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, c) {
            final t = Curves.easeInOut.transform(_c.value);
            return Transform.translate(offset: Offset(-14 * t, -6 * t), child: Transform.scale(scale: 1.04 + 0.11 * t, child: c));
          },
          child: widget.child,
        ),
      );
}

/// Point qui « pulse » (nouvelle commande, livraison en cours).
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = Brand.flame, this.size = 10});
  final Color color;
  final double size;
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size * 2.4,
        height: widget.size * 2.4,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            Container(
              width: widget.size * (1 + 1.4 * _c.value),
              height: widget.size * (1 + 1.4 * _c.value),
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.45 * (1 - _c.value))),
            ),
            Container(width: widget.size, height: widget.size, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
          ]),
        ),
      );
}

/// Reflet lumineux qui balaie un élément doré de temps en temps.
class Shine extends StatefulWidget {
  const Shine({super.key, required this.child, this.period = const Duration(milliseconds: 3600)});
  final Widget child;
  final Duration period;
  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = (_c.value / 0.45).clamp(0.0, 1.0); // balayage sur 45 % du cycle, puis pause
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment(-2.0 + 4.0 * t, -0.4),
              end: Alignment(-1.0 + 4.0 * t, 0.4),
              colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.5), Colors.white.withOpacity(0)],
            ).createShader(r),
            child: child,
          );
        },
        child: widget.child,
      );
}

// ---------------------------------------------------------------- Onglets
/// IndexedStack avec fondu + léger glissement à chaque changement d'onglet.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;
  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 340), value: 1);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.035, 0), end: Offset.zero).animate(_a),
          child: IndexedStack(index: widget.index, children: widget.children),
        ),
      );
}

// ---------------------------------------------------------------- Confettis
class _Particle {
  _Particle(math.Random r)
      : angle = -math.pi / 2 + (r.nextDouble() - 0.5) * 2.1,
        speed = 380 + r.nextDouble() * 520,
        size = 6 + r.nextDouble() * 7,
        spin = (r.nextDouble() - 0.5) * 14,
        color = const [Brand.gold, Brand.goldSoft, Brand.flame, Brand.cream, Color(0xFFFFB02E)][r.nextInt(5)],
        round = r.nextBool();
  final double angle, speed, size, spin;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.ps);
  final double t;
  final List<_Particle> ps;

  @override
  void paint(Canvas canvas, Size s) {
    final secs = t * 2.4;
    for (final p in ps) {
      final x = s.width / 2 + math.cos(p.angle) * p.speed * secs;
      final y = s.height * 0.62 + math.sin(p.angle) * p.speed * secs + 0.5 * 980 * secs * secs;
      final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
      final paint = Paint()..color = p.color.withOpacity(fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * secs);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55), const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..forward().whenComplete(widget.onDone);
  final _ps = List.generate(90, (_) => _Particle(math.Random()));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_c.value, _ps)),
      );
}

/// Lance une pluie de confettis par-dessus l'écran.
void celebrate(BuildContext context) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => IgnorePointer(child: ConfettiBurst(onDone: () => entry.remove())));
  overlay.insert(entry);
  HapticFeedback.mediumImpact();
}

// ---------------------------------------------------------------- Démarrage
/// Écran d'accueil animé (logo qui apparaît + logotype) qui s'efface sur l'application.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child, this.subtitle, this.travel});
  final Widget child;
  final String? subtitle;

  /// Emoji qui traverse l'écran pendant le démarrage (ex. 🛵 pour le livreur).
  final String? travel;
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300));
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = Tween<double>(begin: 0.4, end: 1).animate(CurvedAnimation(parent: _c, curve: const Interval(0, 0.45, curve: Curves.elasticOut)));
    final logoFade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.2, curve: Curves.easeOut));
    final wordFade = CurvedAnimation(parent: _c, curve: const Interval(0.3, 0.6, curve: Curves.easeOut));
    final outFade = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _c, curve: const Interval(0.8, 1, curve: Curves.easeIn)));

    return Stack(fit: StackFit.expand, children: [
      widget.child,
      if (!_gone)
        IgnorePointer(
        child: FadeTransition(
          opacity: outFade,
          child: Container(
            color: Brand.ink,
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _c,
              builder: (ctx, __) => SizedBox.expand(child: Stack(alignment: Alignment.center, children: [
                if (widget.travel != null)
                  Positioned(
                    bottom: MediaQuery.of(ctx).size.height * 0.16,
                    left: -80 + (MediaQuery.of(ctx).size.width + 160) * Curves.easeInOut.transform(((_c.value - 0.1) / 0.7).clamp(0.0, 1.0).toDouble()),
                    child: Text(widget.travel!, style: const TextStyle(fontSize: 46)),
                  ),
                // halo doré qui grandit
                Container(
                  width: 120 + 380 * _c.value,
                  height: 120 + 380 * _c.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Brand.gold.withOpacity(0.28 * (1 - _c.value * 0.5)), Colors.transparent]),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  FadeTransition(opacity: logoFade, child: ScaleTransition(scale: logoScale, child: Image.asset('assets/images/logo.png', width: 128))),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: wordFade,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(wordFade),
                      child: Image.asset('assets/images/wordmark.png', width: 250),
                    ),
                  ),
                  if (widget.subtitle != null)
                    FadeTransition(opacity: wordFade, child: Text(widget.subtitle!, style: Brand.display(13, color: Brand.gold, spacing: 2.4))),
                ]),
              ])),
            ),
          ),
        ),
      ),
    ]);
  }
}
