import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _desc = TextEditingController(text: widget.product?.description ?? '');
  late final _price = TextEditingController(text: widget.product?.basePrice.toString() ?? '');
  late final _category = TextEditingController(text: widget.product?.category ?? 'shawarma');
  late final _flavors = TextEditingController(text: widget.product?.flavors.join(', ') ?? '');
  late bool _available = widget.product?.available ?? true;
  Uint8List? _imageBytes;
  String _imageName = 'photo.jpg';
  bool _removeImage = false;
  bool _saving = false;

  bool get _editing => widget.product != null;

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _category, _flavors]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = x.name.isNotEmpty ? x.name : 'photo.jpg';
      _removeImage = false;
    });
  }

  Future<void> _save() async {
    final price = int.tryParse(_price.text.trim());
    if (_name.text.trim().isEmpty) return snack(context, 'Le nom est requis.');
    if (price == null || price < 0) return snack(context, 'Prix invalide.');
    if (_category.text.trim().isEmpty) return snack(context, 'La catégorie est requise.');
    setState(() => _saving = true);
    try {
      await context.read<AdminProvider>().saveProduct(
            id: widget.product?.id,
            name: _name.text.trim(),
            description: _desc.text.trim(),
            category: _category.text.trim(),
            price: price,
            flavors: _flavors.text.trim(),
            available: _available,
            imageBytes: _imageBytes,
            imageName: _imageName,
            removeImage: _removeImage,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        snack(context, e.toString());
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Supprimer ce produit ?', '« ${widget.product!.name} » sera retiré du menu définitivement. (Pour le masquer temporairement, marque-le plutôt Épuisé.)', ok: 'Supprimer');
    if (!ok || !mounted) return;
    try {
      await context.read<AdminProvider>().deleteProduct(widget.product!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) snack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final cats = {'shawarma', 'boissons', ...admin.products.map((p) => p.category)}.toList();
    final existingUrl = _removeImage ? null : widget.product?.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier le produit' : 'Nouveau produit'),
        actions: [if (_editing) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline, color: Brand.danger))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(alignment: Alignment.bottomRight, children: [
              _imageBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.memory(_imageBytes!, width: 150, height: 150, fit: BoxFit.cover))
                  : ProductImage(emoji: '📷', url: existingUrl, asset: widget.product?.assetImage, size: 150, radius: 22),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Brand.gold, shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera, size: 18, color: Brand.ink),
              ),
            ]),
          ),
        ),
        if (_imageBytes != null || existingUrl != null)
          TextButton(
            onPressed: () => setState(() {
              _imageBytes = null;
              _removeImage = true;
            }),
            child: const Text('Retirer la photo', style: TextStyle(color: Brand.danger)),
          ),
        const SizedBox(height: 14),
        TextField(controller: _name, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nom du produit')),
        const SizedBox(height: 12),
        TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (ingrédients…)')),
        const SizedBox(height: 12),
        TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (FCFA)', suffixText: 'FCFA')),
        const SizedBox(height: 12),
        TextField(controller: _category, decoration: const InputDecoration(labelText: 'Catégorie', helperText: 'Choisis ci-dessous ou tape une nouvelle catégorie')),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final c in cats) ActionChip(label: Text(categoryLabel(c)), onPressed: () => setState(() => _category.text = c)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _flavors,
          decoration: const InputDecoration(labelText: 'Saveurs au choix (optionnel)', helperText: 'Sépare par des virgules : Orange, Ananas, Mangue. Vide = pas de choix.'),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Disponible à la commande', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(_available ? 'Les clients peuvent le commander' : 'Affiché « Épuisé », non commandable', style: const TextStyle(color: Brand.dim)),
          value: _available,
          onChanged: (v) => setState(() => _available = v),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Brand.ink)) : Text(_editing ? 'Enregistrer' : 'Ajouter au menu'),
        ),
      ]),
    );
  }
}
