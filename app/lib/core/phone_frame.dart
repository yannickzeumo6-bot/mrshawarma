import 'package:flutter/material.dart';
import 'theme.dart';

/// Sur un grand écran (navigateur de PC), affiche l'app dans un cadre de téléphone centré.
/// Sur un vrai téléphone, ne change rien.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= 600) return child;
    const w = 430.0;
    final h = mq.size.height > 940 ? 900.0 : mq.size.height - 24;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(colors: [Color(0xFF2B1D0D), Color(0xFF060403)], center: Alignment.topCenter, radius: 1.2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Brand.gold.withOpacity(0.4), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 50, spreadRadius: 4)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: MediaQuery(data: mq.copyWith(size: Size(w, h), padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero), child: child),
        ),
      ),
    );
  }
}
