class AppUser {
  final int id;
  final String name, email, role;
  AppUser({required this.id, required this.name, required this.email, required this.role});
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        role: j['role']?.toString() ?? 'client',
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role};
  String get firstName => name.trim().isEmpty ? '' : name.trim().split(' ').first;
}

class Product {
  final String id, category, name, description;
  final int basePrice;
  final bool hasFlavors, available;
  final List<String> flavors;
  final String? imageUrl;
  Product({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.hasFlavors,
    required this.flavors,
    required this.available,
    this.imageUrl,
  });
  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'].toString(),
        category: j['category']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        basePrice: (j['basePrice'] as num).toInt(),
        hasFlavors: j['hasFlavors'] == true,
        flavors: ((j['flavors'] as List?) ?? []).map((e) => e.toString()).toList(),
        available: j['available'] != false,
        imageUrl: j['imageUrl']?.toString(),
      );
  Product copyWith({bool? available}) => Product(
        id: id,
        category: category,
        name: name,
        description: description,
        basePrice: basePrice,
        hasFlavors: hasFlavors,
        flavors: flavors,
        available: available ?? this.available,
        imageUrl: imageUrl,
      );
  static const _assets = {'sw1', 'sw2', 'sw3', 'sw4', 'sw5', 'dr1', 'dr2', 'dr3', 'dr4'};
  /// Photo du menu officiel embarquée dans l'app (remplacée par la photo de l'admin si elle existe).
  String? get assetImage => _assets.contains(id) ? 'assets/images/products/$id.jpg' : null;
  bool get isDouble => name.toLowerCase().contains('viande');
  String get emoji {
    final n = name.toLowerCase();
    if (category == 'boissons') {
      if (n.contains('eau')) return '💧';
      if (n.contains('bissap')) return '🌺';
      if (n.contains('jus')) return '🍊';
      if (n.contains('kossam')) return '🥛';
      return '🥤';
    }
    if (category == 'shawarma') {
      if (n.contains('plat')) return '🍽️';
      if (n.contains('ordinaire')) return '🥖';
      return '🌯';
    }
    return '🍴';
  }
}

class Promotion {
  final int id;
  final String title, description, badge, discountType;
  final int discountValue;
  final String? productId, category;
  final DateTime? startsAt, endsAt;
  final DateTime createdAt;
  final bool active;
  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.discountType,
    required this.discountValue,
    required this.active,
    required this.createdAt,
    this.productId,
    this.category,
    this.startsAt,
    this.endsAt,
  });
  static DateTime? _ms(dynamic v) => v == null ? null : DateTime.fromMillisecondsSinceEpoch((v as num).toInt());
  factory Promotion.fromJson(Map<String, dynamic> j) => Promotion(
        id: (j['id'] as num).toInt(),
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        badge: j['badge']?.toString() ?? 'PROMO',
        discountType: j['discountType']?.toString() ?? 'info',
        discountValue: (j['discountValue'] as num?)?.toInt() ?? 0,
        productId: j['productId']?.toString(),
        category: j['category']?.toString(),
        startsAt: _ms(j['startsAt']),
        endsAt: _ms(j['endsAt']),
        active: j['active'] != false,
        createdAt: _ms(j['createdAt']) ?? DateTime.now(),
      );

  /// Statut calculé (utilisé par l'admin).
  String get statusLabel {
    final now = DateTime.now();
    if (!active) return 'Désactivée';
    if (endsAt != null && now.isAfter(endsAt!)) return 'Expirée';
    if (startsAt != null && now.isBefore(startsAt!)) return 'Programmée';
    return 'En cours';
  }
}

class DeliveryQuote {
  final double km, lat, lng;
  final int fee;
  final String method;
  final String? label;
  DeliveryQuote({required this.km, required this.fee, required this.method, required this.lat, required this.lng, this.label});
  factory DeliveryQuote.fromJson(Map<String, dynamic> j) => DeliveryQuote(
        km: (j['km'] as num).toDouble(),
        fee: (j['fee'] as num).toInt(),
        method: j['method']?.toString() ?? 'estimate',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        label: j['label']?.toString(),
      );
}

class OrderModel {
  final String ref, status, paymentMethod, address;
  final String? promoTitle, clientName, clientEmail;
  final List<Map<String, dynamic>> items;
  final int subtotal, promoDiscount, promoAmount, deliveryFee, total, placedAt;
  final double? distanceKm, lat, lng;
  OrderModel({
    required this.ref,
    required this.status,
    required this.paymentMethod,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.promoDiscount,
    required this.promoAmount,
    required this.deliveryFee,
    required this.total,
    required this.placedAt,
    this.promoTitle,
    this.clientName,
    this.clientEmail,
    this.distanceKm,
    this.lat,
    this.lng,
  });
  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final c = j['client'] is Map ? j['client'] as Map : null;
    final ac = j['addressCoords'] is Map ? j['addressCoords'] as Map : null;
    return OrderModel(
      ref: j['ref'].toString(),
      status: j['status'].toString(),
      paymentMethod: j['paymentMethod']?.toString() ?? 'cash',
      address: j['address']?.toString() ?? '',
      items: ((j['items'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      subtotal: (j['subtotal'] as num).toInt(),
      promoDiscount: (j['promoDiscount'] as num?)?.toInt() ?? 0,
      promoAmount: (j['promoAmount'] as num?)?.toInt() ?? 0,
      promoTitle: j['promoTitle']?.toString(),
      deliveryFee: (j['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (j['total'] as num).toInt(),
      placedAt: (j['placedAt'] as num).toInt(),
      distanceKm: (j['distanceKm'] as num?)?.toDouble(),
      lat: (ac?['lat'] as num?)?.toDouble(),
      lng: (ac?['lng'] as num?)?.toDouble(),
      clientName: c?['name']?.toString(),
      clientEmail: c?['email']?.toString(),
    );
  }

  static const steps = ['received', 'preparing', 'delivering', 'client_confirmed', 'delivered'];
  static const labels = {
    'received': 'Commande reçue',
    'preparing': 'En préparation',
    'delivering': 'En livraison',
    'client_confirmed': 'Réception confirmée',
    'delivered': 'Terminée',
  };
  String get statusLabel => labels[status] ?? status;
  int get step => steps.indexOf(status);
  DateTime get placed => DateTime.fromMillisecondsSinceEpoch(placedAt);
  String get paymentLabel => switch (paymentMethod) {
        'orange_money' => 'Orange Money',
        'mtn_momo' => 'MTN MoMo',
        _ => 'Espèces',
      };
}

class AdminStats {
  final int totalOrders, totalRevenue, delivered, inProgress, todayOrders, todayRevenue;
  AdminStats.fromJson(Map<String, dynamic> j)
      : totalOrders = (j['totalOrders'] as num?)?.toInt() ?? 0,
        totalRevenue = (j['totalRevenue'] as num?)?.toInt() ?? 0,
        delivered = (j['delivered'] as num?)?.toInt() ?? 0,
        inProgress = (j['inProgress'] as num?)?.toInt() ?? 0,
        todayOrders = (j['todayOrders'] as num?)?.toInt() ?? 0,
        todayRevenue = (j['todayRevenue'] as num?)?.toInt() ?? 0;
}
