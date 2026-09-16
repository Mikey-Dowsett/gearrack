import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:gearrack/database/app_settings_dao.dart';
import 'package:gearrack/models/app_settings.dart';
import 'package:gearrack/services/backup_service.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/theme/ui_constants.dart';
import 'package:gearrack/pages/category_management_page.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  final Future<void> Function()? onImport;

  const SettingsPage({super.key, this.onThemeChanged, this.onImport});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  bool _isBusy = false;

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
        backgroundColor: colors.background,
        title: Text(
          'Settings',
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onBackground),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: UiConstants.spacingM.sp),
              children: [
                _sectionHeader(colors, 'PREFERENCES'),
                SizedBox(height: 8.sp),
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
                _buildExportTile(colors),
                _buildImportTile(colors),
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

  Widget _buildWeightUnitSelector(AppColorPalette colors) {
    return _settingCard(
      colors,
      icon: PhosphorIconsFill.scales,
      label: 'Show weight in lbs',
      trailing: Switch(
        value: _settings.showLbs,
        activeColor: colors.primary,
        onChanged: (val) {
          _updateSettings(_settings.copyWith(showLbs: val));
        },
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
      icon: PhosphorIconsFill.coins,
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
      icon: PhosphorIconsFill.crown,
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
      icon: PhosphorIconsFill.tag,
      label: 'Manage Categories',
      trailing: PhosphorIcon(
        PhosphorIconsFill.caretRight,
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

  Widget _buildExportTile(AppColorPalette colors) {
    final lastExport = _settings.lastExportAt;
    return _settingCard(
      colors,
      icon: PhosphorIconsFill.export,
      label: 'Export Data',
      trailing: _isBusy
          ? SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              lastExport != null
                  ? '${lastExport.month}/${lastExport.day}/${lastExport.year}'
                  : 'Backup',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
      onTap: _isBusy ? null : _exportData,
    );
  }

  Widget _buildImportTile(AppColorPalette colors) {
    return _settingCard(
      colors,
      icon: PhosphorIconsFill.downloadSimple,
      label: 'Import Data',
      trailing: _isBusy
          ? SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : PhosphorIcon(
              PhosphorIconsFill.caretRight,
              size: 14.sp,
              color: colors.textSecondary,
            ),
      onTap: _isBusy ? null : _importData,
    );
  }

  Future<void> _exportData() async {
    setState(() => _isBusy = true);
    try {
      final backup = await BackupService.exportAll();
      final json = BackupService.encode(backup);
      final fileName =
          'gearrack-backup-${DateTime.now().toIso8601String().split('T').first}.json';

      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save GearRack backup',
        fileName: fileName,
        bytes: utf8.encode(json),
        mimeType: 'application/json',
      );
      // Null means the user cancelled the dialog.
      if (saved == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export cancelled')),
          );
        }
        return;
      }
      await BackupService.stampExport();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to $saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Import Data', style: AppTextStyles.titleMedium),
        content: Text(
          'Importing a backup replaces all current data. This cannot be undone. Continue?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Import', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Choose GearRack backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null) return;

      final String json;
      if (picked.path != null) {
        json = await File(picked.path!).readAsString();
      } else {
        json = utf8.decode(await picked.readAsBytes());
      }

      await BackupService.importAll(BackupService.decode(json));
      await _loadSettings();
      widget.onThemeChanged?.call();
      if (widget.onImport != null) await widget.onImport!.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Widget _buildAboutSection(AppColorPalette colors) {
    return _settingCard(
      colors,
      icon: PhosphorIconsFill.info,
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
    required IconData icon,
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
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.border, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: UiConstants.spacingM.sp,
                    vertical: 14.sp,
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(icon, size: 16.sp, color: colors.primary),
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
            ],
          ),
        ),
      ),
    );
  }
}
