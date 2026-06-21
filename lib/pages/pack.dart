import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../models/pack.dart';
import '../models/pack_item.dart';
import '../models/gear_item.dart';
import '../database/pack_item_dao.dart';
import '../database/gear_item_dao.dart';
import '../database/category_dao.dart';
import '../models/category.dart';
import '../utils/icon_registry.dart';

class PackPage extends StatefulWidget {
  final Pack pack;

  const PackPage({super.key, required this.pack});

  @override
  State<PackPage> createState() => _PackPageState();
}

class _PackPageState extends State<PackPage>
    with SingleTickerProviderStateMixin {
  late Pack _pack;
  late TabController _tabController;

  List<PackItemWithGear> _packItems = [];
  List<CategoryWeight> _categoryWeights = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  double _totalWeight = 0;
  GearItem? _bagGear;

  @override
  void initState() {
    super.initState();
    _pack = widget.pack;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final packItemDao = await PackItemDao.create();
      final categoryDao = await CategoryDao.create();

      final gearDao = await GearItemDao.create();
      final items = await packItemDao.getByPackWithGear(_pack.id);
      final categoryWeights = await packItemDao.getWeightByCategory(_pack.id);
      final totalWeight = await packItemDao.getTotalWeightByPack(_pack.id);
      final categories = await categoryDao.getAll();

      GearItem? bagGear;
      if (_pack.bagId != null) {
        bagGear = await gearDao.getById(_pack.bagId!);
      }

      // Inject the bag's weight into the category breakdown so it appears
      // in both the total and the progress bar.
      final adjustedCategoryWeights = List<CategoryWeight>.from(
        categoryWeights,
      );
      if (bagGear != null) {
        final bag = bagGear;
        final bagCategory = categories.firstWhere(
          (c) => c.id == bag.categoryId,
          orElse: () => categories.first,
        );
        final existingIdx = adjustedCategoryWeights.indexWhere(
          (cw) => cw.categoryId == bag.categoryId,
        );
        if (existingIdx >= 0) {
          final existing = adjustedCategoryWeights[existingIdx];
          adjustedCategoryWeights[existingIdx] = CategoryWeight(
            categoryId: existing.categoryId,
            categoryName: existing.categoryName,
            icon: existing.icon,
            color: existing.color,
            totalWeightGrams: existing.totalWeightGrams + bag.weightGrams,
          );
        } else {
          adjustedCategoryWeights.add(
            CategoryWeight(
              categoryId: bagCategory.id,
              categoryName: bagCategory.name,
              icon: bagCategory.icon,
              color: bagCategory.color,
              totalWeightGrams: bag.weightGrams,
            ),
          );
          adjustedCategoryWeights.sort(
            (a, b) => b.totalWeightGrams.compareTo(a.totalWeightGrams),
          );
        }
      }

      setState(() {
        _packItems = items;
        _categoryWeights = adjustedCategoryWeights;
        _totalWeight = totalWeight + (bagGear?.weightGrams ?? 0);
        _categories = categories;
        _bagGear = bagGear;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load pack: $e')));
      }
    }
  }

  Future<void> _removeGearItem(String packItemId) async {
    try {
      final dao = await PackItemDao.create();
      await dao.delete(packItemId);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
      }
    }
  }

  Future<void> _addGearItem(String gearItemId) async {
    try {
      final dao = await PackItemDao.create();
      final packItem = PackItem(
        id: const Uuid().v4(),
        packId: _pack.id,
        gearItemId: gearItemId,
        quantityInPack: 1,
        sortOrder: _packItems.length,
      );
      await dao.insert(packItem);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
      }
    }
  }

  /// IDs of gear items already in the pack.
  Set<String> get _gearIdsInPack =>
      _packItems.map((p) => p.gearItem.id).toSet();

  String _categoryIcon(String categoryId) {
    final cat = _categories.where((c) => c.id == categoryId).firstOrNull;
    return cat?.icon ?? 'box';
  }

  void _showAddGearSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGearBottomSheet(
        excludeGearIds: _gearIdsInPack,
        onGearSelected: (gearItemId) {
          Navigator.of(ctx).pop();
          _addGearItem(gearItemId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_pack.name, style: AppTextStyles.bodyLarge),
        backgroundColor: colors.background,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          tabs: const [
            Tab(text: 'Build'),
            Tab(text: 'Checklist'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total weight
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.sp,
                    horizontal: 16.sp,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _totalWeight >= 1000
                            ? '${(_totalWeight / 1000).toStringAsFixed(2)} kg'
                            : '${_totalWeight.toStringAsFixed(0)} g',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 28.sp,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.sp),
                      // Progress bar by category
                      _buildWeightProgressBar(colors),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBuildTab(colors),
                      // Checklist tab placeholder
                      Center(
                        child: Text(
                          'Checklist coming soon',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
          borderRadius: BorderRadius.circular(6.sp),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6.sp),
      child: SizedBox(
        height: 12.sp,
        child: Row(
          children: _categoryWeights.map((cw) {
            final fraction = cw.totalWeightGrams / _totalWeight;
            return Expanded(
              flex: (fraction * 1000).round().clamp(1, 1000),
              child: Container(color: _categoryColor(cw.color)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _categoryColor(String hex) {
    return parseCategoryColor(hex);
  }

  Widget _buildBuildTab(AppColorPalette colors) {
    return Column(
      children: [
        Expanded(
          child: _packItems.isEmpty
              ? Center(
                  child: Text(
                    'No gear added yet.\nTap + to add gear.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _packItems.length + (_bagGear != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show bag first if present
                    if (_bagGear != null && index == 0) {
                      final iconKey = _categoryIcon(_bagGear!.categoryId);
                      return _buildBagCard(colors, _bagGear!, iconKey);
                    }

                    final adjusted = _bagGear != null ? index - 1 : index;
                    final pwg = _packItems[adjusted];
                    final gear = pwg.gearItem;
                    final iconKey = _categoryIcon(gear.categoryId);

                    return _buildMinimalGearCard(
                      colors,
                      gear,
                      iconKey,
                      pwg.packItem.id,
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(12.sp),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddGearSheet,
                icon: FaIcon(FontAwesomeIcons.plus, size: 16.sp),
                label: Text(
                  'Add Gear to Pack',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 14.sp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.sp),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _categoryColorById(String categoryId, Color fallback) {
    final cat = _categories.where((c) => c.id == categoryId).firstOrNull;
    return cat != null ? parseCategoryColor(cat.color) : fallback;
  }

  Widget _buildBagCard(AppColorPalette colors, GearItem bag, String iconKey) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
      child: Card.filled(
        color: colors.primaryContainer,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.sp),
          side: BorderSide(color: colors.primary, width: 1.5),
        ),
        child: SizedBox(
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
                    color: _categoryColorById(bag.categoryId, colors.primary),
                  ),
                ),
              ),
              // Name, brand
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bag.name,
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 13.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bag.brand != null)
                      Text(
                        bag.brand!,
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // "Bag" badge + weight
              Padding(
                padding: EdgeInsets.only(right: 8.sp),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bag.weightGrams.toStringAsFixed(0),
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 13.sp),
                    ),
                    Text('g', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalGearCard(
    AppColorPalette colors,
    GearItem gear,
    String iconKey,
    String packItemId,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
      child: Card.filled(
        color: colors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.sp),
          side: BorderSide(color: colors.border, width: 1.5),
        ),
        child: SizedBox(
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
                    color: _categoryColorById(gear.categoryId, colors.primary),
                  ),
                ),
              ),
              // Name, brand
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      gear.name,
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 13.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gear.brand != null)
                      Text(
                        gear.brand!,
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Weight
              Padding(
                padding: EdgeInsets.only(right: 8.sp),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      gear.weightGrams.toStringAsFixed(0),
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 13.sp),
                    ),
                    Text('g', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              // Remove button
              SizedBox(
                width: 36.sp,
                child: IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.xmark,
                    size: 14.sp,
                    color: colors.textSecondary,
                  ),
                  onPressed: () => _removeGearItem(packItemId),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 36.sp,
                    minHeight: 36.sp,
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

// ---------------------------------------------------------------------------
// Bottom sheet for adding gear to a pack
// ---------------------------------------------------------------------------
class _AddGearBottomSheet extends StatefulWidget {
  final Set<String> excludeGearIds;
  final ValueChanged<String> onGearSelected;

  const _AddGearBottomSheet({
    required this.excludeGearIds,
    required this.onGearSelected,
  });

  @override
  State<_AddGearBottomSheet> createState() => _AddGearBottomSheetState();
}

class _AddGearBottomSheetState extends State<_AddGearBottomSheet> {
  List<GearItem> _filteredGear = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGear();
  }

  Future<void> _loadGear() async {
    try {
      final gearDao = await GearItemDao.create();
      final categoryDao = await CategoryDao.create();
      final allGear = await gearDao.getAll();
      final categories = await categoryDao.getAll();

      // Exclude items already in the pack and items that are packs/bags themselves
      final filtered = allGear
          .where((g) => !widget.excludeGearIds.contains(g.id) && !g.isPack)
          .toList();

      setState(() {
        _filteredGear = filtered;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getIconKey(String categoryId) {
    final cat = _categories.where((c) => c.id == categoryId).firstOrNull;
    return cat?.icon ?? 'box';
  }

  Color _categoryColorById(String categoryId, Color fallback) {
    final cat = _categories.where((c) => c.id == categoryId).firstOrNull;
    return cat != null ? parseCategoryColor(cat.color) : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: EdgeInsets.only(top: 8.sp, bottom: 4.sp),
            child: Container(
              width: 40.sp,
              height: 4.sp,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(2.sp),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.sp),
            child: Text('Add Gear to Pack', style: AppTextStyles.titleLarge),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredGear.isEmpty
                ? Center(
                    child: Text(
                      'All gear is already in the pack\nor no gear available.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredGear.length,
                    itemBuilder: (context, index) {
                      final gear = _filteredGear[index];
                      final iconKey = _getIconKey(gear.categoryId);

                      return ListTile(
                        leading: FaIcon(
                          IconRegistry.resolve(iconKey),
                          size: 20.sp,
                          color: _categoryColorById(
                            gear.categoryId,
                            colors.primary,
                          ),
                        ),
                        title: Text(gear.name, style: AppTextStyles.bodyLarge),
                        subtitle: gear.brand != null
                            ? Text(gear.brand!, style: AppTextStyles.bodySmall)
                            : null,
                        trailing: Text(
                          '${gear.weightGrams.toStringAsFixed(0)} g',
                          style: AppTextStyles.bodyMedium,
                        ),
                        onTap: () => widget.onGearSelected(gear.id),
                      );
                    },
                  ),
          ),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

/// Parse a hex color string like `#385A41` or `385A41` into a Flutter [Color].
Color parseCategoryColor(String hex) {
  final stripped = hex.replaceFirst('#', '');
  final fullHex = stripped.length == 6 ? 'FF$stripped' : stripped;
  return Color(int.parse(fullHex, radix: 16));
}
