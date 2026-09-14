import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/gear_item.dart';
import '../models/category.dart';
import '../database/category_dao.dart';
import '../database/trip_dao.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ui_constants.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';
import '../utils/icon_registry.dart';
import 'add_gear.dart';
import '../utils/weight_formatter.dart';

class GearPage extends StatefulWidget {
  final GearItem gear;

  const GearPage({super.key, required this.gear});

  @override
  State<GearPage> createState() => _GearPageState();
}

class _GearPageState extends State<GearPage> {
  late GearItem _gear;
  Category? _category;
  bool _isLoadingCategory = true;
  GearUsageStats? _usageStats;
  bool _isLoadingUsage = true;
  bool _wasEdited = false;

  @override
  void initState() {
    super.initState();
    _gear = widget.gear;
    _loadCategory();
    _loadUsageStats();
  }

  Future<void> _loadUsageStats() async {
    try {
      final dao = await TripDao.create();
      final stats = await dao.getUsageStats(_gear.id);
      setState(() {
        _usageStats = stats;
        _isLoadingUsage = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsage = false);
    }
  }

  Future<void> _loadCategory() async {
    try {
      final dao = await CategoryDao.create();
      final cat = await dao.getById(_gear.categoryId);
      setState(() {
        _category = cat;
        _isLoadingCategory = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategory = false);
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<GearItem>(
      context,
      MaterialPageRoute(builder: (_) => AddGearPage(gear: _gear)),
    );

    if (result != null && mounted) {
      setState(() {
        _gear = result;
        _isLoadingCategory = true;
        _wasEdited = true;
      });
      _loadCategory();
    }
  }

  void _handleBack() {
    Navigator.of(context).pop(_wasEdited ? _gear : null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gear = _gear;
    final age = gear.purchaseYear != null
        ? DateTime.now().year - gear.purchaseYear!
        : 0;

    final categoryName = _category?.name ?? gear.categoryId;
    final categoryIconKey = _category?.icon ?? 'box';
    final wp = formatWeightParts(gear.weightGrams);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        title: Text(
          _isLoadingCategory ? 'Loading...' : categoryName,
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onBackground),
        ),
        backgroundColor: colors.background,
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.pen, size: 16.sp, color: colors.onBackground),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Green hero — mirrors pack page weight banner
            Container(
              width: double.infinity,
              color: colors.primary,
              padding: EdgeInsets.symmetric(
                vertical: 16.sp,
                horizontal: 16.sp,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 25.sp,
                        height: 25.sp,
                        decoration: BoxDecoration(
                          color: colors.primaryMuted,
                          borderRadius: BorderRadius.all(
                            Radius.circular(
                              UiConstants.compactCardRadius.sp,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: FaIcon(
                          IconRegistry.resolve(categoryIconKey),
                          size: 15.sp,
                          color: colors.onPrimary,
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      Expanded(
                        child: Text(
                          _isLoadingCategory
                              ? 'LOADING…'
                              : categoryName.toUpperCase(),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: colors.onPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.sp,
                          vertical: 2.sp,
                        ),
                        decoration: BoxDecoration(
                          color: colors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3.sp),
                        ),
                        child: Text(
                          gear.condition.toUpperCase(),
                          style: AppTextStyles.specSmall.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.sp),
                  Text(
                    gear.name,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 25.sp,
                      color: colors.onPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    '${gear.brand ?? 'No brand'} · ${wp.value} ${wp.unit}',
                    style: AppTextStyles.specMedium.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.sp),
                  Text(
                    '${gear.price != null ? '\$${gear.price!.toStringAsFixed(2)}' : '—'} · x${gear.quantity} · ${age} yrs',
                    style: AppTextStyles.specSmall.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Specifications'),
                  SizedBox(height: 8.sp),
                  Row(
                    children: [
                      Flexible(
                        child: InfoCard(
                          icon: FontAwesomeIcons.scaleBalanced,
                          title: 'Weight',
                          value: formatWeight(gear.weightGrams),
                        ),
                      ),
                      Flexible(
                        child: InfoCard(
                          icon: FontAwesomeIcons.tag,
                          title: 'Price',
                          value: gear.price != null
                              ? '\$${gear.price!.toStringAsFixed(2)}'
                              : '—',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: InfoCard(
                          icon: FontAwesomeIcons.box,
                          title: 'Quantity',
                          value: 'x${gear.quantity}',
                        ),
                      ),
                      Flexible(
                        child: InfoCard(
                          icon: FontAwesomeIcons.clock,
                          title: 'Age',
                          value: '${age} yrs',
                        ),
                      ),
                    ],
                  ),
                  if (gear.isPack && gear.capacityLiters != null)
                    InfoCard(
                      icon: FontAwesomeIcons.boxOpen,
                      title: 'Capacity',
                      value: '${gear.capacityLiters!.toStringAsFixed(0)} L',
                    ),
                  SizedBox(height: 8.sp),
                  const SectionHeader(title: 'Condition & Kit'),
                  SizedBox(height: 8.sp),
                  InfoCard(
                    icon: FontAwesomeIcons.certificate,
                    title: 'Condition',
                    value: gear.condition,
                  ),
                  InfoCard(
                    icon: FontAwesomeIcons.shop,
                    title: 'Category',
                    value: _isLoadingCategory ? '…' : categoryName,
                  ),
                  if (gear.notes != null && gear.notes!.isNotEmpty) ...[
                    SizedBox(height: 8.sp),
                    const SectionHeader(title: 'Field Notes'),
                    SizedBox(height: 8.sp),
                    InfoCard(
                      icon: FontAwesomeIcons.solidNoteSticky,
                      title: 'Notes',
                      value: gear.notes!,
                      maxLines: 6,
                    ),
                  ],
                  if (!_isLoadingUsage && _usageStats != null) ...[
                    SizedBox(height: 8.sp),
                    const SectionHeader(title: 'Trail Use'),
                    SizedBox(height: 8.sp),
                    Row(
                      children: [
                        Flexible(
                          child: InfoCard(
                            icon: FontAwesomeIcons.personHiking,
                            title: 'Times Used',
                            value:
                                '${_usageStats!.timesUsed} trip${_usageStats!.timesUsed != 1 ? 's' : ''}',
                          ),
                        ),
                        Flexible(
                          child: InfoCard(
                            icon: FontAwesomeIcons.clock,
                            title: 'Last Used',
                            value: _usageStats!.lastUsedDate != null
                                ? '${_usageStats!.lastUsedDate!.month}/${_usageStats!.lastUsedDate!.day}/${_usageStats!.lastUsedDate!.year}'
                                : 'Never',
                          ),
                        ),
                      ],
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
  }
}
