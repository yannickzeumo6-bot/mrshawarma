import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common.dart';

class PromoFormScreen extends StatefulWidget {
  const PromoFormScreen({super.key, this.promo});
  final Promotion? promo;
  @override
  State<PromoFormScreen> createState() => _PromoFormScreenState();
}

class _PromoFormScreenState extends State<PromoFormScreen> {
  late final _title = TextEditingController(text: widget.promo?.title ?? '');
  late final _desc = TextEditingController(text: widget.promo?.description ?? '');
  late final _value = TextEditingController(text: (widget.promo?.discountValue ?? 0) > 0 ? '${widget.promo!.discountValue}' : '');
  late String _type = widget.promo?.discountType ?? 'percent';
  late String _scope = widget.promo?.productId != null ? 'product' : (widget.promo?.category != null ? 'category' : 'all');
  late String? _category = widget.promo?.category;
  late String? _productId = widget.promo?.productId;
  late DateTime? _start = widget.promo?.startsAt;
  late DateTime? _end = widget.promo?.endsAt;
  bool _saving = false;

  bool get _editing => widget.promo != null;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime? initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()));
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return snack(context, 'Le titre est requis.');
    final v = int.tryParse(_value.text.trim()) ?? 0;
    if (_type == 'percent' && (v < 1 || v > 100)) return snack(context, 'Pourcentage entre 1 et 100.');
    if (_type == 'fixed' && v < 1) return snack(context, 'Indique le montant de la réduction.');
    if (_scope == 'category' && _category == null) return snack(context, 'Choisis une catégorie.');
    if (_scope == 'product' && _productId == null) return snack(context, 'Choisis un produit.');
    if (_start != null && _end != null && !_end!.isAfter(_start!)) return snack(context, 'La fin doit être après le début.');

    setState(() => _saving = true);
    try {
      await context.read<AdminProvider>().savePromo(widget.promo?.id, {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'discountType': _type,
        'discountValue': _type == 'info' ? 0 : v,
        'productId': _scope == 'product' ? _productId : null,
        'category': _scope == 'category' ? _category : null,
        'startsAt': _start?.millisecondsSinceEpoch,
        'endsAt': _end?.millisecondsSinceEpoch,
      });
      if (mounted) {
        snack(context, _editing ? 'Promotion mise à jour.' : 'Promotion publiée — les clients sont notifiés 🔔');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        snack(context, e.toString());
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Supprimer cette promotion ?', 'Elle disparaîtra chez les clients.', ok: 'Supprimer');
    if (!ok || !mounted) return;
    try {
      await context.read<AdminProvider>().deletePromo(widget.promo!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) snack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final cats = admin.products.map((p) => p.category).toSet().toList();
    final dropStyle = const TextStyle(color: Brand.cream);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier la promotion' : 'Nouvelle promotion'),
        actions: [if (_editing) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline, color: Brand.danger))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _title, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Titre (ex : -20 % ce week-end)')),
        const SizedBox(height: 12),
        TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 16),
        const Text('Type de réduction', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(selectedBackgroundColor: Brand.gold, selectedForegroundColor: Brand.ink, side: const BorderSide(color: Brand.line)),
          segments: const [
            ButtonSegment(value: 'percent', label: Text('Pourcentage')),
            ButtonSegment(value: 'fixed', label: Text('Montant')),
            ButtonSegment(value: 'info', label: Text('Annonce')),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        if (_type != 'info') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: _type == 'percent' ? 'Pourcentage' : 'Montant de la réduction', suffixText: _type == 'percent' ? '%' : 'FCFA'),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text("Une annonce est affichée et notifiée, mais ne change pas le prix.", style: TextStyle(color: Brand.dim, fontSize: 12.5)),
          ),
        if (_type != 'info') ...[
          const SizedBox(height: 16),
          const Text("S'applique à", style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _scope,
            dropdownColor: Brand.surface,
            style: dropStyle,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tout le menu')),
              DropdownMenuItem(value: 'category', child: Text('Une catégorie')),
              DropdownMenuItem(value: 'product', child: Text('Un produit')),
            ],
            onChanged: (v) => setState(() => _scope = v ?? 'all'),
          ),
          if (_scope == 'category') ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: cats.contains(_category) ? _category : null,
              hint: const Text('Catégorie'),
              dropdownColor: Brand.surface,
              style: dropStyle,
              items: [for (final c in cats) DropdownMenuItem(value: c, child: Text(categoryLabel(c)))],
              onChanged: (v) => setState(() => _category = v),
            ),
          ],
          if (_scope == 'product') ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: admin.products.any((p) => p.id == _productId) ? _productId : null,
              hint: const Text('Produit'),
              dropdownColor: Brand.surface,
              style: dropStyle,
              items: [for (final p in admin.products) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _productId = v),
            ),
          ],
        ],
        const SizedBox(height: 16),
        const Text('Période (optionnel)', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final d = await _pick(_start);
                if (d != null) setState(() => _start = d);
              },
              child: Text(_start == null ? 'Début : maintenant' : dateTimeFr(_start!), style: const TextStyle(fontSize: 13)),
            ),
          ),
          if (_start != null) IconButton(onPressed: () => setState(() => _start = null), icon: const Icon(Icons.close, size: 18)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final d = await _pick(_end ?? _start);
                if (d != null) setState(() => _end = d);
              },
              child: Text(_end == null ? 'Fin : jamais' : dateTimeFr(_end!), style: const TextStyle(fontSize: 13)),
            ),
          ),
          if (_end != null) IconButton(onPressed: () => setState(() => _end = null), icon: const Icon(Icons.close, size: 18)),
        ]),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Text('🔔', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _start != null && _start!.isAfter(DateTime.now())
                    ? 'Les clients seront notifiés au début de la promotion.'
                    : 'Les clients seront notifiés dès la publication.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Brand.ink)) : Text(_editing ? 'Enregistrer' : 'Publier la promotion'),
        ),
      ]),
    );
  }
}
