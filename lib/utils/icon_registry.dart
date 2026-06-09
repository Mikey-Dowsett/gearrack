import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Central registry mapping icon key strings to Font Awesome icons.
///
/// Both [Category] and [GearItem] store their icon as a string key.
/// This registry resolves those keys to concrete [FaIconData] for display.
class IconRegistry {
  IconRegistry._();

  static const Map<String, FaIconData> _icons = {
    // Category icons
    'tent': FontAwesomeIcons.tent,
    'bed': FontAwesomeIcons.bed,
    'shirt': FontAwesomeIcons.shirt,
    'shoe-prints': FontAwesomeIcons.shoePrints,
    'compass': FontAwesomeIcons.compass,
    'lightbulb': FontAwesomeIcons.lightbulb,
    'fire': FontAwesomeIcons.fire,
    'utensils': FontAwesomeIcons.utensils,
    'first-aid': FontAwesomeIcons.kitMedical,
    'wrench': FontAwesomeIcons.wrench,
    'plug': FontAwesomeIcons.plug,
    'suitcase': FontAwesomeIcons.suitcase,
    'person-hiking': FontAwesomeIcons.personHiking,
    'snowflake': FontAwesomeIcons.snowflake,
    'water': FontAwesomeIcons.water,
    'soap': FontAwesomeIcons.soap,
    'shield': FontAwesomeIcons.shield,
    'ellipsis': FontAwesomeIcons.ellipsis,

    // Condition icons
    'check': FontAwesomeIcons.check,
    'rotate': FontAwesomeIcons.rotate,
    'trash': FontAwesomeIcons.trash,

    // Generic / fallback
    'box': FontAwesomeIcons.box,
    'box-open': FontAwesomeIcons.boxOpen,
    'scale-balanced': FontAwesomeIcons.scaleBalanced,
    'tag': FontAwesomeIcons.tag,
    'clock': FontAwesomeIcons.clock,
    'certificate': FontAwesomeIcons.certificate,
    'note-sticky': FontAwesomeIcons.solidNoteSticky,
    'shop': FontAwesomeIcons.shop,
    'xmark': FontAwesomeIcons.xmark,
  };

  /// Resolve an icon key to its [FaIconData].
  ///
  /// Returns a default box icon if the key is not found.
  static FaIconData resolve(String key) {
    return _icons[key] ?? FontAwesomeIcons.box;
  }

  /// All registered icon keys (useful for debugging or pickers).
  static List<String> get keys => _icons.keys.toList();
}
