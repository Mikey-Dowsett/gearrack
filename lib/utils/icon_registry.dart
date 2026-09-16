import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

class IconRegistry {
  IconRegistry._();
  static const Map<String, IconData> _icons = {
    'tent': PhosphorIconsFill.tent,
    'bed': PhosphorIconsFill.bed,
    'shirt': PhosphorIconsFill.tShirt,
    'shoe-prints': PhosphorIconsFill.sneaker,
    'compass': PhosphorIconsFill.compass,
    'lightbulb': PhosphorIconsFill.lightbulb,
    'fire': PhosphorIconsFill.fire,
    'utensils': PhosphorIconsFill.forkKnife,
    'first-aid': PhosphorIconsFill.firstAidKit,
    'wrench': PhosphorIconsFill.wrench,
    'plug': PhosphorIconsFill.plug,
    'suitcase': PhosphorIconsFill.backpack,
    'backpack': PhosphorIconsFill.backpack,
    'person-hiking': PhosphorIconsFill.backpack, // legacy alias
    'snowflake': PhosphorIconsFill.snowflake,
    'water': PhosphorIconsFill.drop,
    'mountain': PhosphorIconsFill.mountains,
    'climbing': PhosphorIconsFill.mountains,
    'soap': PhosphorIconsFill.handSoap,
    'shield': PhosphorIconsFill.shield,
    'box': PhosphorIconsFill.package,
    'box-open': PhosphorIconsFill.package,
    'check': PhosphorIconsFill.checkFat,
    'rotate': PhosphorIconsFill.arrowsClockwise,
    'trash': PhosphorIconsFill.trash,
    'ellipsis': PhosphorIconsFill.dotsThree,
  };
  static IconData resolve(String key) =>
      _icons[key] ?? PhosphorIconsFill.package;
  static List<String> get keys => _icons.keys.toList();
  static List<IconEntry> get all =>
      _icons.entries
          .map(
            (e) =>
                IconEntry(key: e.key, name: _formatName(e.key), icon: e.value),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  static List<IconEntry> search(String q) {
    if (q.isEmpty) return all;
    final l = q.toLowerCase();
    return all
        .where((e) => e.name.toLowerCase().contains(l) || e.key.contains(l))
        .toList();
  }

  static String _formatName(String k) => k
      .replaceAll('-', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
      .join(' ');
}

class IconEntry {
  final String key;
  final String name;
  final IconData icon;
  const IconEntry({required this.key, required this.name, required this.icon});
}
