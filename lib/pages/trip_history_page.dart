import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gearrack/database/trip_dao.dart';
import 'package:gearrack/database/pack_dao.dart';
import 'package:gearrack/models/trip.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/theme/ui_constants.dart';
import 'package:gearrack/utils/weight_formatter.dart';
import 'package:gearrack/pages/log_trip_page.dart';
import 'package:gearrack/pages/trip_detail_page.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({super.key});

  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
  List<Trip> _trips = [];
  Map<String, double> _totalWeights = {};
  Map<String, int> _itemCounts = {};
  Map<String, String> _packNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      final dao = await TripDao.create();
      final packDao = await PackDao.create();
      final trips = await dao.getAll();

      final Map<String, double> weights = {};
      final Map<String, int> counts = {};

      for (final trip in trips) {
        weights[trip.id] = await dao.getTotalWeightByTrip(trip.id);
        counts[trip.id] = await dao.getItemCountByTrip(trip.id);
      }

      final packNames = <String, String>{};
      for (final trip in trips) {
        if (trip.packId != null && !packNames.containsKey(trip.packId)) {
          final pack = await packDao.getById(trip.packId!);
          if (pack != null) {
            packNames[trip.packId!] = pack.name;
          }
        }
      }

      setState(() {
        _trips = trips;
        _totalWeights = weights;
        _itemCounts = counts;
        _packNames = packNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load trips: $e')));
      }
    }
  }

  Future<void> _navigateToLogTrip() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LogTripPage()),
    );
    if (result == true && mounted) {
      _loadTrips();
    }
  }

  Future<void> _navigateToTripDetail(Trip trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripDetailPage(tripId: trip.id)),
    );
    if (mounted) {
      _loadTrips();
    }
  }

  String _formatDateRange(Trip trip) {
    final start =
        '${trip.startDate.month}/${trip.startDate.day}/${trip.startDate.year}';
    if (trip.endDate == null) return start;
    final end =
        '${trip.endDate!.month}/${trip.endDate!.day}/${trip.endDate!.year}';
    if (trip.startDate.year == trip.endDate!.year &&
        trip.startDate.month == trip.endDate!.month &&
        trip.startDate.day == trip.endDate!.day) {
      return start;
    }
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12.sp, top: 12.sp, bottom: 8.sp),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Trip History',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: colors.onBackground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${_trips.length} trip${_trips.length != 1 ? 's' : ''}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No trips logged yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to log your first trip',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTrips,
                    child: ListView.builder(
                      itemCount: _trips.length,
                      itemBuilder: (context, index) {
                        final trip = _trips[index];
                        final wp = formatWeightParts(
                          _totalWeights[trip.id] ?? 0,
                        );
                        final itemCount = _itemCounts[trip.id] ?? 0;
                        final packName = trip.packId != null
                            ? _packNames[trip.packId]
                            : null;

                        return Padding(
                          padding: EdgeInsets.only(
                            right: 12.0.w,
                            left: 12.0.w,
                            top: 6.0.h,
                            bottom: 6.0.h,
                          ),
                          child: GestureDetector(
                            onTap: () => _navigateToTripDetail(trip),
                            child: Card.filled(
                              color: colors.surface,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  UiConstants.cardRadius.sp,
                                ),
                                side: BorderSide(
                                  color: colors.border,
                                  width: UiConstants.borderWidth,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Gradient header
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                          UiConstants.cardRadius.sp,
                                        ),
                                        topRight: Radius.circular(
                                          UiConstants.cardRadius.sp,
                                        ),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [colors.primary, colors.accent],
                                      ),
                                    ),
                                    padding: EdgeInsets.all(12.sp),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                trip.name,
                                                style: AppTextStyles.titleLarge
                                                    .copyWith(
                                                      color: colors.onPrimary,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4.sp),
                                              Row(
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons
                                                        .calendarDays,
                                                    size: 12.sp,
                                                    color: colors.onPrimary
                                                        .withValues(alpha: 0.8),
                                                  ),
                                                  SizedBox(width: 4.sp),
                                                  Text(
                                                    _formatDateRange(trip),
                                                    style: AppTextStyles
                                                        .labelMedium
                                                        .copyWith(
                                                          color: colors
                                                              .onPrimary
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              if (trip.location != null &&
                                                  trip.location!.isNotEmpty)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 2.sp,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      FaIcon(
                                                        FontAwesomeIcons
                                                            .locationDot,
                                                        size: 12.sp,
                                                        color: colors.onPrimary
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                      ),
                                                      SizedBox(width: 4.sp),
                                                      Text(
                                                        trip.location!,
                                                        style: AppTextStyles
                                                            .labelMedium
                                                            .copyWith(
                                                              color: colors
                                                                  .onPrimary
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (packName != null)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 2.sp,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      FaIcon(
                                                        FontAwesomeIcons
                                                            .suitcase,
                                                        size: 12.sp,
                                                        color: colors.onPrimary
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                      ),
                                                      SizedBox(width: 4.sp),
                                                      Text(
                                                        packName,
                                                        style: AppTextStyles
                                                            .labelMedium
                                                            .copyWith(
                                                              color: colors
                                                                  .onPrimary
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8.sp),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              wp.value +
                                                  (wp.unit == 'kg'
                                                      ? ' ${wp.unit}'
                                                      : ''),
                                              style: AppTextStyles.titleLarge
                                                  .copyWith(
                                                    color: colors.onPrimary,
                                                  ),
                                            ),
                                            if (wp.unit == 'g')
                                              Text(
                                                wp.unit,
                                                style: AppTextStyles.labelMedium
                                                    .copyWith(
                                                      color: colors.onPrimary
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Footer info
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.sp,
                                      vertical: 10.sp,
                                    ),
                                    child: Row(
                                      children: [
                                        FaIcon(
                                          FontAwesomeIcons.box,
                                          size: 15.sp,
                                          color: colors.textSecondary,
                                        ),
                                        SizedBox(width: 6.sp),
                                        Text(
                                          '$itemCount item${itemCount != 1 ? 's' : ''}',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: colors.textSecondary,
                                              ),
                                        ),
                                        if (trip.activityType != null) ...[
                                          SizedBox(width: 16.sp),
                                          FaIcon(
                                            FontAwesomeIcons.tag,
                                            size: 15.sp,
                                            color: colors.textSecondary,
                                          ),
                                          SizedBox(width: 6.sp),
                                          Text(
                                            trip.activityType!,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: colors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToLogTrip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
