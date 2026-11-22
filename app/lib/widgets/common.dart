import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import 'fx.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.emoji, this.url, this.asset, this.size = 80, this.width, this.height, this.radius = 18, this.dim = false});
  final String emoji;
  final String? url, asset;
  final double size, radius;
  final double? width, height;
  final bool dim;

  double get _w => width ?? size;
  double get _h => height ?? size;

  Widget _emojiBox() => Container(
        width: _w,
        height: _h,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF2E241A), Color(0xFF15100B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Text(emoji, style: TextStyle(fontSize: _h * 0.42)),
      );

  Widget _assetOrEmoji() => asset == null
      ? _emojiBox()
      : Image.asset(asset!, width: _w, height: _h, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _emojiBox());

  @override
  Widget build(BuildContext context) {
    Widget img = (url != null && url!.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: url!,
            width: _w,
            height: _h,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) => _assetOrEmoji(),
            errorWidget: (_, __, ___) => _assetOrEmoji(),
          )
        : _assetOrEmoji();
    if (dim) {
      img = Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: img,
        ),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: SizedBox(width: _w, height: _h, child: img));
  }
}

/// Badge de prix doré, comme sur l'affiche.
class PriceBadge extends StatelessWidget {
  const PriceBadge(this.price, {super.key, this.muted = false});
  final int price;
  final bool muted;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          gradient: muted ? null : Brand.goldGradient,
          color: muted ? Brand.line : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: spaced(price), style: Brand.display(17, color: muted ? Brand.dim : Brand.ink, spacing: 0.3)),
          TextSpan(text: ' FCFA', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: muted ? Brand.dim : Brand.ink)),
        ])),
      );
}

/// Bouton principal doré : dégradé, ombre, reflet qui balaie, effet de pression.
class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: onPressed == null && !busy ? 0.5 : 1,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        scale: 0.97,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Brand.gold.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 7))],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Shine(child: Container(decoration: const BoxDecoration(gradient: Brand.goldGradient))),
              ),
            ),
            busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: Brand.ink))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) ...[Icon(icon, color: Brand.ink, size: 20), const SizedBox(width: 8)],
                    Text(label, style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w800, fontSize: 15.5)),
                  ]),
          ]),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color = Brand.gold, this.filled = false});
  final String label;
  final Color color;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: filled ? Brand.ink : color)),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle, this.action});
  final String emoji, title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: Brand.dim)),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ]),
        ),
      );
}

/// Carte de contenu standard.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin = const EdgeInsets.only(bottom: 12), this.highlight = false, this.enterIndex});
  final Widget child;
  final EdgeInsets padding, margin;
  final bool highlight;

  /// Si renseigné, la carte apparaît en cascade (délai selon sa position dans la liste).
  final int? enterIndex;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Brand.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: highlight ? Brand.gold.withOpacity(0.6) : Brand.line),
        boxShadow: highlight ? [BoxShadow(color: Brand.gold.withOpacity(0.08), blurRadius: 16)] : null,
      ),
      child: child,
    );
    return enterIndex == null ? box : FadeSlideIn(delay: stagger(enterIndex!), child: box);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(children: [
          Container(width: 4, height: 20, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(gradient: Brand.goldGradient, borderRadius: BorderRadius.circular(2))),
          Expanded(child: Text(text.toUpperCase(), style: Brand.display(18, spacing: 0.8))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Squelette animé pendant le chargement.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 5});
  final int count;
  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            for (var i = 0; i < widget.count; i++)
              Container(
                height: 104,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Color.lerp(Brand.card, Brand.line, _c.value),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
          ],
        ),
      );
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDialog(BuildContext context, String title, String body, {String ok = 'Confirmer'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Brand.surface,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(ok)),
      ],
    ),
  );
  return r ?? false;
}
