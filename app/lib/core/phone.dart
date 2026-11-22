/// Numéros camerounais : stockés à 9 chiffres (ex. 690000000).

/// "6 90 00 00 00"
String prettyPhone(String national) {
  final d = national.replaceAll(RegExp(r'\D'), '');
  if (d.length != 9) return national;
  final rest = d.substring(1);
  final groups = [for (var i = 0; i < rest.length; i += 2) rest.substring(i, i + 2)];
  return '${d[0]} ${groups.join(' ')}';
}

/// Lien d'appel : tel:+237690000000
Uri dialUri(String national) {
  final d = national.replaceAll(RegExp(r'\D'), '');
  return Uri.parse('tel:${d.length == 9 ? '+237$d' : d}');
}
