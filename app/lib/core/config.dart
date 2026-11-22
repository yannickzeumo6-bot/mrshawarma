class AppConfig {
  /// Adresse du backend Laravel.
  /// - Émulateur Android : http://10.0.2.2:8000 (défaut)
  /// - Téléphone réel   : --dart-define=API_BASE=http://192.168.x.x:8000
  /// - Production       : --dart-define=API_BASE=https://ton-domaine.com
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:8000');

  static const promoPollSeconds = 60;
  static const ordersPollSeconds = 20;

  /// Fidélité (miroir du serveur) : 1 shawarma offert tous les N.
  static const promoQtyPerFree = 10;

  /// Une promo n'est annoncée par notification locale que si elle est récente.
  static const freshPromoMinutes = 5;
}
