import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../theme/ui_constants.dart';
import '../widgets/info_card.dart';
import '../models/trip.dart';
import '../models/trip_item.dart';
import '../database/trip_dao.dart';
import '../utils/icon_registry.dart';
import '../utils/weight_formatter.dart';
import 'log_trip_page.dart';

class TripDetailPage extends StatefulWidget {
  final String tripId;

  const TripDetailPage({super.key, required this.tripId});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  Trip? _trip;
  List<TripItemWithDetails> _items = [];
  List<TripCategoryWeight> _categoryWeights = [];
  bool _isLoading = true;
  double _totalWeight = 0;
  List<TripItem> _tripItems = []; // raw items for editing

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dao = await TripDao.create();
      final trip = await dao.getById(widget.tripId);
      final items = await dao.getItemsByTripWithDetails(widget.tripId);
      final categoryWeights = await dao.getWeightByCategory(widget.tripId);
      final totalWeight = await dao.getTotalWeightByTrip(widget.tripId);
      final rawItems = await dao.getItemsByTrip(widget.tripId);

      setState(() {
        _trip = trip;
        _items = items;
        _categoryWeights = categoryWeights;
        _totalWeight = totalWeight;
        _tripItems = rawItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load trip: $e')));
      }
    }
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Trip', style: AppTextStyles.titleMedium),
        content: Text(
          'Delete "${_trip?.name}"? This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.of(context).error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final dao = await TripDao.create();
        await dao.delete(widget.tripId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Trip deleted')));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Future<void> _editTrip() async {
    if (_trip == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogTripPage(trip: _trip, tripItems: _tripItems),
      ),
    );
    if (result == true && mounted) {
      _loadData();
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
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _trip?.name ?? 'Trip Detail',
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onBackground),
        ),
        backgroundColor: colors.background,
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.pen, size: 16.sp),
            onPressed: _editTrip,
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.trash, size: 16.sp),
            onPressed: _deleteTrip,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trip == null
          ? Center(
              child: Text(
                'Trip not found',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onBackground,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Weight header with progress bar (like pack detail)
                  _buildWeightHeader(colors),

                  // Trip info cards
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.sp,
                      vertical: 4.sp,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoCard(
                          icon: FontAwesomeIcons.calendarDays,
                          title: 'Date',
                          value: _formatDateRange(_trip!),
                        ),
                        if (_trip!.activityType != null)
                          InfoCard(
                            icon: FontAwesomeIcons.tag,
                            title: 'Activity',
                            value: _trip!.activityType!,
                          ),
                        if (_trip!.location != null &&
                            _trip!.location!.isNotEmpty)
                          InfoCard(
                            icon: FontAwesomeIcons.locationDot,
                            title: 'Location',
                            value: _trip!.location!,
                          ),
                        if (_trip!.conditions != null &&
                            _trip!.conditions!.isNotEmpty)
                          InfoCard(
                            icon: FontAwesomeIcons.cloudSun,
                            title: 'Conditions',
                            value: _trip!.conditions!,
                          ),
                        if (_trip!.notes != null && _trip!.notes!.isNotEmpty)
                          InfoCard(
                            icon: FontAwesomeIcons.solidNoteSticky,
                            title: 'Notes',
                            value: _trip!.notes!,
                          ),
                      ],
                    ),
                  ),

                  // Items section
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.sp,
                      vertical: 8.sp,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Items Taken (${_items.length})',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: colors.onBackground,
                        ),
                      ),
                    ),
                  ),
                  if (_items.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(20.sp),
                      child: Text(
                        'No items recorded for this trip.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ..._items.map((item) => _buildItemCard(colors, item)),
                  SizedBox(height: 24.sp),
                ],
              ),
            ),
    );
  }

  Widget _buildWeightHeader(AppColorPalette colors) {
    final wp = formatWeightParts(_totalWeight);

    return Container(
      color: colors.primary,
      padding: EdgeInsets.symmetric(vertical: 16.sp, horizontal: 16.sp),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 25.sp,
                height: 25.sp,
                decoration: BoxDecoration(
                  color: colors.primaryMuted,
                  borderRadius: BorderRadius.all(
                    Radius.circular(UiConstants.compactCardRadius.sp),
                  ),
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  FontAwesomeIcons.clipboardList,
                  size: 15.sp,
                  color: colors.onPrimary,
                ),
              ),
              SizedBox(width: 5.sp),
              Text(
                'TOTAL TRIP WEIGHT',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.onPrimary,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                wp.value,
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: 25.sp,
                  color: colors.onPrimary,
                ),
              ),
              SizedBox(width: 2.sp),
              Text(
                wp.unit,
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.onPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          // Progress bar by category
          _buildWeightProgressBar(colors),
        ],
      ),
    );
  }

  Widget _buildWeightProgressBar(AppColorPalette colors) {
    if (_categoryWeights.isEmpty || _totalWeight == 0) {
      return Container(
        height: 12.sp,
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(UiConstants.compactCardRadius.sp),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(UiConstants.compactCardRadius.sp),
      child: SizedBox(
        height: 12.sp,
        child: Row(
          children: _categoryWeights.map((cw) {
            final fraction = cw.totalWeightGrams / _totalWeight;
            return Expanded(
              flex: (fraction * 1000).round().clamp(1, 1000),
              child: Container(color: AppColors.parseHex(cw.color)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildItemCard(AppColorPalette colors, TripItemWithDetails item) {
    final wp = formatWeightParts(item.tripItem.weightGrams);
    final iconKey = item.categoryIcon ?? 'box';
    final catColor = item.categoryColor != null
        ? AppColors.parseHex(item.categoryColor!)
        : colors.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
      child: Card.filled(
        color: colors.surface,
        elevation: UiConstants.cardElevation,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.compactCardRadius.sp),
          side: BorderSide(color: colors.border, width: UiConstants.borderWidth),
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56.sp,
                child: Row(
                  children: [
                    // Icon area
                    SizedBox(
                      width: 44.sp,
                      child: Center(
                        child: FaIcon(
                          IconRegistry.resolve(iconKey),
                          size: 20.sp,
                          color: catColor,
                        ),
                      ),
                    ),
                    // Name, brand, category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.tripItem.itemName,
                            style: AppTextStyles.titleLarge.copyWith(fontSize: 13.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              if (item.brand != null)
                                Text(
                                  '${item.brand} \u2022 ',
                                  style: AppTextStyles.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (item.categoryName != null)
                                Text(
                                  item.categoryName!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quantity badge
                    if (item.tripItem.quantity > 1)
                      Padding(
                        padding: EdgeInsets.only(right: 4.sp),
                        child: Text(
                          '\u00d7${item.tripItem.quantity}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    // Weight
                    Padding(
                      padding: EdgeInsets.only(right: 8.sp),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                wp.value,
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: 13.sp,
                                ),
                              ),
                              Text(wp.unit, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }

  }
