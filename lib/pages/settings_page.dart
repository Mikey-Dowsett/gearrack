import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gearrack/database/app_settings_dao.dart';
import 'package:gearrack/models/app_settings.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/theme/ui_constants.dart';
import 'package:gearrack/pages/category_management_page.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const SettingsPage({super.key, this.onThemeChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final dao = await AppSettingsDao.create();
      final settings = await dao.get();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    }
  }

  Future<void> _updateSettings(AppSettings updated) async {
    try {
      final dao = await AppSettingsDao.create();
      await dao.update(updated);
      setState(() => _settings = updated);
      widget.onThemeChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surfaceRaised,
        title: Text(
          'Settings',
          style: AppTextStyles.titleMedium.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: UiConstants.spacingM.sp),
              children: [
                _sectionHeader(colors, 'PREFERENCES'),
                SizedBox(height: 8.sp),
                _buildThemeSelector(colors),
                _buildWeightUnitSelector(colors),
                _buildCurrencySelector(colors),
                SizedBox(height: 24.sp),
                _sectionHeader(colors, 'ACCOUNT'),
                SizedBox(height: 8.sp),
                _buildProModeSection(colors),
                SizedBox(height: 24.sp),
                _sectionHeader(colors, 'DATA'),
                SizedBox(height: 8.sp),
                _buildManageCategoriesTile(colors),
                SizedBox(height: 24.sp),
                _sectionHeader(colors, 'ABOUT'),
                SizedBox(height: 8.sp),
                _buildAboutSection(colors),
              ],
            ),
    );
  }

  Widget _sectionHeader(AppColorPalette colors, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: UiConstants.spacingL.sp),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          color: colors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(AppColorPalette colors) {
    final themeOptions = ['light', 'dark', 'system'];
    final labels = ['Light', 'Dark', 'System'];
    final icons = [
      FontAwesomeIcons.sun,
      FontAwesomeIcons.moon,
      FontAwesomeIcons.display,
    ];
    final currentIndex = themeOptions.indexOf(_settings.theme).clamp(0, 2);

    return _settingCard(
      colors,
      icon: FontAwesomeIcons.palette,
      label: 'Theme',
      trailing: DropdownButton<int>(
        value: currentIndex,
        underline: const SizedBox(),
        dropdownColor: colors.surfaceRaised,
        style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
        items: List.generate(themeOptions.length, (i) {
          return DropdownMenuItem(
            value: i,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(icons[i], size: 14.sp, color: colors.onSurface),
                SizedBox(width: 6.sp),
                Text(labels[i]),
              ],
            ),
          );
        }),
        onChanged: (value) {
          if (value != null) {
            _updateSettings(_settings.copyWith(theme: themeOptions[value]));
          }
        },
      ),
    );
  }

  Widget _buildWeightUnitSelector(AppColorPalette colors) {
    final isGrams = _settings.weightUnit == 'grams';

    return _settingCard(
      colors,
      icon: FontAwesomeIcons.scaleBalanced,
      label: 'Weight Unit',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'g',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isGrams ? colors.primary : colors.textSecondary,
              fontWeight: isGrams ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(width: 6.sp),
          Switch(
            value: isGrams,
            activeColor: colors.primary,
            onChanged: (val) {
              _updateSettings(_settings.copyWith(weightUnit: val ? 'grams' : 'pounds'));
            },
          ),
          SizedBox(width: 6.sp),
          Text(
            'lb',
            style: AppTextStyles.bodyMedium.copyWith(
              color: !isGrams ? colors.primary : colors.textSecondary,
              fontWeight: !isGrams ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static const _currencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD',
    'AUD', 'CHF', 'CNY', 'INR', 'BRL',
  ];

  Widget _buildCurrencySelector(AppColorPalette colors) {
    const currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CHF': 'CHF',
      'CNY': '¥',
      'INR': '₹',
      'BRL': 'R\$',
    };
    const currencyNames = {
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'JPY': 'Japanese Yen',
      'CAD': 'Canadian Dollar',
      'AUD': 'Australian Dollar',
      'CHF': 'Swiss Franc',
      'CNY': 'Chinese Yuan',
      'INR': 'Indian Rupee',
      'BRL': 'Brazilian Real',
    };

    return _settingCard(
      colors,
      icon: FontAwesomeIcons.coins,
      label: 'Currency',
      trailing: DropdownButton<String>(
        value: _settings.currency,
        underline: const SizedBox(),
        dropdownColor: colors.surfaceRaised,
        style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
        items: _currencies.map((code) {
          return DropdownMenuItem(
            value: code,
            child: Text('${currencySymbols[code]}  $code — ${currencyNames[code]}'),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _updateSettings(_settings.copyWith(currency: value));
          }
        },
      ),
    );
  }

  Widget _buildProModeSection(AppColorPalette colors) {
    return _settingCard(
      colors,
      icon: FontAwesomeIcons.crown,
      label: 'PRO Mode',
      trailing: Switch(
        value: _settings.proMode,
        activeColor: colors.primary,
        onChanged: (value) {
          _updateSettings(_settings.copyWith(proMode: value));
        },
      ),
    );
  }

  Widget _buildManageCategoriesTile(AppColorPalette colors) {
    return _settingCard(
      colors,
      icon: FontAwesomeIcons.tags,
      label: 'Manage Categories',
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        size: 14.sp,
        color: colors.textSecondary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoryManagementPage(),
          ),
        );
      },
    );
  }

  Widget _buildAboutSection(AppColorPalette colors) {
    return _settingCard(
      colors,
      icon: FontAwesomeIcons.circleInfo,
      label: 'Version',
      trailing: Text(
        '1.0.0',
        style: AppTextStyles.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _settingCard(
    AppColorPalette colors, {
    required FaIconData icon,
    required String label,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: UiConstants.spacingL.sp,
        vertical: 4.sp,
      ),
      child: Card.filled(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
          side: BorderSide(color: colors.border, width: UiConstants.borderWidth),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: UiConstants.spacingM.sp,
              vertical: 14.sp,
            ),
            child: Row(
              children: [
                FaIcon(icon, size: 16.sp, color: colors.primary),
                SizedBox(width: 12.sp),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
