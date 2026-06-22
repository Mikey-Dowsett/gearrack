import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/gear_item.dart';
import '../models/category.dart';
import '../database/category_dao.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/info_card.dart';
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

  @override
  void initState() {
    super.initState();
    _gear = widget.gear;
    _loadCategory();
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
      });
      _loadCategory();
    }
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          _isLoadingCategory ? 'Loading...' : categoryName,
          style: AppTextStyles.bodyLarge,
        ),
        backgroundColor: colors.background,
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.pen, size: 16.sp),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 160.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: const Alignment(-0.9, -0.9),
                        stops: [0.0, 0.5, 0.5, 1.0],
                        colors: [
                          colors.surfaceRaised,
                          colors.surfaceRaised,
                          colors.surfaceSunken,
                          colors.surfaceSunken,
                        ],
                        tileMode: TileMode.repeated,
                      ),
                    ),
                  ),
                  FaIcon(
                    IconRegistry.resolve(categoryIconKey),
                    size: 56.sp,
                    color: _category != null
                        ? AppColors.parseHex(_category!.color)
                        : colors.primary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoCard(
                    icon: FontAwesomeIcons.shop,
                    title: gear.brand ?? 'No brand',
                    value: gear.name,
                  ),
                  if (gear.isPack && gear.capacityLiters != null)
                    InfoCard(
                      icon: FontAwesomeIcons.boxOpen,
                      title: 'Capacity',
                      value: '${gear.capacityLiters!.toStringAsFixed(0)} L',
                    ),
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
                  InfoCard(
                    icon: FontAwesomeIcons.certificate,
                    title: 'Condition',
                    value: gear.condition,
                  ),
                  if (gear.notes != null && gear.notes!.isNotEmpty)
                    InfoCard(
                      icon: FontAwesomeIcons.solidNoteSticky,
                      title: 'Notes',
                      value: gear.notes!,
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
