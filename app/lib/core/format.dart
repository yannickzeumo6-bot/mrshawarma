String fcfa(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}$b FCFA';
}

/// "1 000" (sans l'unité)
String spaced(num v) => fcfa(v).replaceAll(' FCFA', '');

String two(int n) => n.toString().padLeft(2, '0');

String dateFr(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
String dateTimeFr(DateTime d) => '${dateFr(d)} ${two(d.hour)}:${two(d.minute)}';

String categoryLabel(String c) => switch (c) {
      'shawarma' => 'Shawarmas',
      'boissons' => 'Boissons',
      _ => c.isEmpty ? c : c[0].toUpperCase() + c.substring(1),
    };
