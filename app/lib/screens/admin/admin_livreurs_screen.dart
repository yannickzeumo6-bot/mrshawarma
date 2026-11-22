import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common.dart';

/// Gestion des comptes livreurs : connexion par téléphone, email facultatif.
class AdminLivreursScreen extends StatelessWidget {
  const AdminLivreursScreen({super.key});

  Future<void> _edit(BuildContext context, [Livreur? l]) async {
    final admin = context.read<AdminProvider>();
    final ok = await showDialog<bool>(context: context, builder: (_) => _LivreurDialog(admin: admin, livreur: l));
    if (ok == true && context.mounted) snack(context, l == null ? 'Livreur ajouté.' : 'Livreur modifié.');
  }

  Future<void> _delete(BuildContext context, Livreur l) async {
    final admin = context.read<AdminProvider>();
    if (!await confirmDialog(context, 'Supprimer ${l.name} ?', 'Ce livreur ne pourra plus se connecter.', ok: 'Supprimer')) return;
    try {
      await admin.deleteLivreur(l.id);
    } catch (e) {
      if (context.mounted) snack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!admin.livreursLoaded) return const SkeletonList(count: 3);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Brand.gold,
        foregroundColor: Brand.ink,
        onPressed: () => _edit(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nouveau livreur', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: Brand.gold,
        onRefresh: admin.loadLivreurs,
        child: admin.livreurs.isEmpty
            ? ListView(children: [const SizedBox(height: 90), EmptyState(emoji: '🛵', title: admin.error ?? 'Aucun livreur', subtitle: 'Ajoute un livreur : il se connecte avec son téléphone.')])
            : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
                for (final l in admin.livreurs)
                  Panel(
                    enterIndex: admin.livreurs.indexOf(l),
                    child: Row(children: [
                      const Icon(Icons.two_wheeler, color: Brand.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(l.phone != null ? '📞 ${prettyPhone(l.phone!)}' : '📞 Pas de numéro', style: const TextStyle(color: Brand.dim, fontSize: 13)),
                          if (l.email != null) Text(l.email!, style: const TextStyle(color: Brand.dim, fontSize: 12)),
                        ]),
                      ),
                      PopupMenuButton<String>(
                        color: Brand.surface,
                        onSelected: (v) => v == 'edit' ? _edit(context, l) : _delete(context, l),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Modifier / nouveau mot de passe')),
                          PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                        ],
                      ),
                    ]),
                  ),
              ]),
      ),
    );
  }
}

class _LivreurDialog extends StatefulWidget {
  const _LivreurDialog({required this.admin, this.livreur});
  final AdminProvider admin;
  final Livreur? livreur;
  @override
  State<_LivreurDialog> createState() => _LivreurDialogState();
}

class _LivreurDialogState extends State<_LivreurDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.livreur?.name ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.livreur?.phone ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.livreur?.email ?? '');
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.livreur == null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return setState(() => _error = 'Le nom est requis.');
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 9) return setState(() => _error = 'Numéro de téléphone invalide (ex. 6 90 00 00 00).');
    if (_isNew && _pass.text.length < 8) return setState(() => _error = 'Mot de passe : 8 caractères minimum.');
    if (!_isNew && _pass.text.isNotEmpty && _pass.text.length < 8) return setState(() => _error = 'Mot de passe : 8 caractères minimum.');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.admin.saveLivreur(id: widget.livreur?.id, name: _name.text, phone: _phone.text, email: _email.text, password: _pass.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Brand.surface,
      title: Text(_isNew ? 'Nouveau livreur' : 'Modifier le livreur'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nom')),
          const SizedBox(height: 10),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone (connexion)', hintText: '6 90 00 00 00')),
          const SizedBox(height: 10),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (facultatif)')),
          const SizedBox(height: 10),
          TextField(controller: _pass, decoration: InputDecoration(labelText: _isNew ? 'Mot de passe' : 'Nouveau mot de passe (vide = inchangé)')),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Brand.danger))),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Annuler')),
        TextButton(onPressed: _busy ? null : _save, child: Text(_busy ? '…' : 'Enregistrer')),
      ],
    );
  }
}
