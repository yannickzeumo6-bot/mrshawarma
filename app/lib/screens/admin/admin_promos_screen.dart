import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common.dart';
import 'promo_form_screen.dart';

class AdminPromosScreen extends StatelessWidget {
  const AdminPromosScreen({super.key});

  void _open(BuildContext context, [Promotion? p]) {
    final admin = context.read<AdminProvider>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(value: admin, child: PromoFormScreen(promo: p)),
    ));
  }

  Color _color(String s) => switch (s) {
        'En cours' => Brand.ok,
        'Programmée' => Brand.gold,
        _ => Brand.dim,
      };

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!admin.promosLoaded) return const SkeletonList(count: 3);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Brand.gold,
        foregroundColor: Brand.ink,
        onPressed: () => _open(context),
        icon: const Icon(Icons.campaign),
        label: const Text('Nouvelle promo', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: Brand.gold,
        onRefresh: admin.loadPromos,
        child: admin.promos.isEmpty
            ? ListView(children: [const SizedBox(height: 90), EmptyState(emoji: '🎁', title: admin.error ?? 'Aucune promotion', subtitle: 'Crée une promo : les clients seront notifiés.')])
            : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
                for (final p in admin.promos)
                  Panel(
                    enterIndex: admin.promos.indexOf(p),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _open(context, p),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Pill(p.badge, filled: true),
                          const SizedBox(width: 8),
                          Pill(p.statusLabel, color: _color(p.statusLabel)),
                          const Spacer(),
                          Switch(
                            value: p.active,
                            onChanged: (_) async {
                              try {
                                await admin.togglePromo(p);
                              } catch (e) {
                                if (context.mounted) snack(context, e.toString());
                              }
                            },
                          ),
                        ]),
                        Text(p.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        if (p.description.isNotEmpty) Text(p.description, style: const TextStyle(color: Brand.dim, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (p.startsAt != null) 'Début : ${dateTimeFr(p.startsAt!)}',
                            if (p.endsAt != null) 'Fin : ${dateTimeFr(p.endsAt!)}',
                          ].join('  ·  '),
                          style: const TextStyle(color: Brand.dim, fontSize: 12),
                        ),
                      ]),
                    ),
                  ),
              ]),
      ),
    );
  }
}
