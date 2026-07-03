import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gearrack/database/trip_dao.dart';
import 'package:gearrack/database/app_settings_dao.dart';
import 'package:gearrack/models/trip.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/theme/ui_constants.dart';
import 'package:gearrack/utils/weight_formatter.dart';
import 'package:gearrack/pages/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onSwitchToTrips;
  final VoidCallback? onThemeChanged;

  const ProfilePage({super.key, this.onSwitchToTrips, this.onThemeChanged});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  List<Trip> _trips = [];
  Map<String, double> _totalWeights = {};
  bool _isLoading = true;
  bool _proMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final settingsDao = await AppSettingsDao.create();
      final settings = await settingsDao.get();
      final dao = await TripDao.create();
      final trips = await dao.getAll();

      final Map<String, double> weights = {};
      for (final trip in trips) {
        weights[trip.id] = await dao.getTotalWeightByTrip(trip.id);
      }

      setState(() {
        _trips = trips;
        _totalWeights = weights;
        _proMode = settings.proMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(onThemeChanged: widget.onThemeChanged),
      ),
    );
    // Reload after returning (PRO mode may have changed)
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surfaceRaised,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: AppTextStyles.titleMedium.copyWith(color: colors.onSurface),
        ),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.gear, size: 18.sp, color: colors.onSurface),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    SizedBox(height: 24.sp),
                    CircleAvatar(
                      radius: 40.sp,
                      backgroundColor: colors.surfaceRaised,
                      child: FaIcon(
                        FontAwesomeIcons.user,
                        size: 36.sp,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 16.sp),
                    Text(
                      'User Profile',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 6.sp),
                    Text(
                      'user@example.com',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.sp),
                    _proMode
                        ? _buildProActiveSection(colors)
                        : _buildProUpgradeSection(colors),
                    if (_proMode && _trips.isNotEmpty) ...[
                      SizedBox(height: 16.sp),
                      _buildTripStats(colors),
                    ],
                    SizedBox(height: 24.sp),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProUpgradeSection(AppColorPalette colors) {
    final benefits = [
      ('Full trip history & logging', FontAwesomeIcons.clock),
      ('Gear usage statistics', FontAwesomeIcons.chartSimple),
      ('Weight tracking per trip', FontAwesomeIcons.scaleBalanced),
      ('Activity type logging', FontAwesomeIcons.personHiking),
      ('Trip location tracking', FontAwesomeIcons.locationDot),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: UiConstants.spacingL.sp),
      padding: EdgeInsets.all(UiConstants.spacingM.sp),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.crown, size: 20.sp, color: colors.tertiary),
              SizedBox(width: 8.sp),
              Text(
                'Upgrade to PRO',
                style: AppTextStyles.titleLarge.copyWith(color: colors.onSurface),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          Text(
            'Unlock trip logging, gear usage tracking, and detailed insights for your outdoor adventures.',
            style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: 16.sp),
          ...benefits.map(
            (b) => Padding(
              padding: EdgeInsets.only(bottom: 8.sp),
              child: Row(
                children: [
                  FaIcon(b.$2, size: 14.sp, color: colors.primary),
                  SizedBox(width: 8.sp),
                  Text(
                    b.$1,
                    style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.sp),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openSettings,
              icon: FaIcon(
                FontAwesomeIcons.gear,
                size: 16.sp,
                color: colors.onSurface,
              ),
              label: Text(
                'Enable in Settings',
                style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
                minimumSize: Size(0, 44.sp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UiConstants.buttonRadius.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProActiveSection(AppColorPalette colors) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: UiConstants.spacingL.sp),
      padding: EdgeInsets.all(UiConstants.spacingM.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.accent],
        ),
        borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.crown, size: 20.sp, color: colors.onPrimary),
                  SizedBox(width: 8.sp),
                  Text(
                    'PRO Mode Active',
                    style: AppTextStyles.titleLarge.copyWith(color: colors.onPrimary),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.check, size: 10.sp, color: colors.onPrimary),
                    SizedBox(width: 4.sp),
                    Text(
                      'ACTIVE',
                      style: AppTextStyles.labelSmall.copyWith(color: colors.onPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.sp),
          Row(
            children: [
              FaIcon(FontAwesomeIcons.personHiking, size: 14.sp, color: colors.onPrimary),
              SizedBox(width: 8.sp),
              Text(
                _trips.isEmpty
                    ? 'No trips logged yet'
                    : '${_trips.length} trip${_trips.length != 1 ? 's' : ''} logged',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.sp),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => widget.onSwitchToTrips?.call(),
                  icon: FaIcon(FontAwesomeIcons.personHiking, size: 14.sp, color: colors.onPrimary),
                  label: Text(
                    'Open Trips',
                    style: AppTextStyles.bodyMedium.copyWith(color: colors.onPrimary),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: colors.onPrimary.withValues(alpha: 0.15),
                    foregroundColor: colors.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UiConstants.buttonRadius.sp),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openSettings,
                  icon: FaIcon(FontAwesomeIcons.gear, size: 14.sp, color: colors.onPrimary),
                  label: Text(
                    'Settings',
                    style: AppTextStyles.bodyMedium.copyWith(color: colors.onPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UiConstants.buttonRadius.sp),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripStats(AppColorPalette colors) {
    final totalWeightGrams = _totalWeights.values.fold(0.0, (sum, w) => sum + w);
    final wp = formatWeightParts(totalWeightGrams);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: UiConstants.spacingL.sp),
      padding: EdgeInsets.all(UiConstants.spacingM.sp),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Summary',
            style: AppTextStyles.titleSmall.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: 12.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                colors, 'Trips', _trips.length.toString(),
                FontAwesomeIcons.locationDot, colors.primary,
              ),
              _buildStatItem(
                colors, 'Weight', '${wp.value} ${wp.unit}',
                FontAwesomeIcons.scaleBalanced, colors.tertiary,
              ),
              _buildStatItem(
                colors, 'Last Trip',
                _trips.isNotEmpty
                    ? '${_trips.first.startDate.month}/${_trips.first.startDate.day}'
                    : '—',
                FontAwesomeIcons.clock, colors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    AppColorPalette colors,
    String label,
    String value,
    FaIconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        FaIcon(icon, size: 20.sp, color: iconColor),
        SizedBox(height: 8.sp),
        Text(value, style: AppTextStyles.titleMedium.copyWith(color: colors.onSurface)),
        SizedBox(height: 4.sp),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary)),
      ],
    );
  }
}
