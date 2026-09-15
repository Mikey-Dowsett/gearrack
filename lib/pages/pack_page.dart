import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../models/pack.dart';
import '../models/pack_item.dart';
import '../models/gear_item.dart';
import '../database/pack_dao.dart';
import '../database/pack_item_dao.dart';
import '../database/gear_item_dao.dart';
import '../database/category_dao.dart';
import '../database/app_settings_dao.dart';
import '../models/category.dart';
import '../utils/icon_registry.dart';
import '../theme/ui_constants.dart';
import '../utils/weight_formatter.dart';
import '../widgets/section_header.dart';
import '../widgets/patch_chip.dart';
import 'log_trip_page.dart';
import 'add_pack.dart';

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
  double _totalValue = 0;
  String _currencySymbol = '\$';
  bool _showLbs = false;
  GearItem? _bagGear;
  bool _bagChecked = false;

  int get _gearCount {
    final itemCount = _packItems.fold<int>(
      0,
      (sum, pwg) => sum + pwg.packItem.quantityInPack,
    );
    return itemCount + (_bagGear != null ? 1 : 0);
  }

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
    await _refreshSilent();
    if (mounted) setState(() => _isLoading = false);
  }

  /// Reload pack items + derived totals without showing the full-screen
  /// spinner. Used for add/remove so the list doesn't flash.
  Future<void> _refreshSilent() async {
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

      final settingsDao = await AppSettingsDao.create();
      final settings = await settingsDao.get();

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
        _totalValue =
            items.fold<double>(
              0,
              (sum, pwg) =>
                  sum +
                  (pwg.gearItem.price ?? 0) * pwg.packItem.quantityInPack,
            ) +
            (bagGear?.price ?? 0);
        _currencySymbol = _currencySymbolFor(settings.currency);
        _showLbs = settings.showLbs;
        _categories = categories;
        _bagGear = bagGear;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load pack: $e')));
      }
    }
  }

  /// Recompute weight/value/category breakdown from in-memory items.
  /// Used for optimistic add/remove so the header updates instantly.
  void _recalculateTotals() {
    double itemsWeight = 0;
    double itemsValue = 0;
    final Map<String, double> weightByCat = {};
    final Map<String, CategoryWeight> metaByCat = {};
    for (final cw in _categoryWeights) {
      metaByCat[cw.categoryId] = cw;
    }
    for (final pwg in _packItems) {
      final w = pwg.gearItem.weightGrams * pwg.packItem.quantityInPack;
      itemsWeight += w;
      itemsValue += (pwg.gearItem.price ?? 0) * pwg.packItem.quantityInPack;
      weightByCat.update(
        pwg.gearItem.categoryId,
        (v) => v + w,
        ifAbsent: () => w,
      );
    }
    final bagW = _bagGear?.weightGrams ?? 0;
    final bagV = _bagGear?.price ?? 0;
    if (_bagGear != null) {
      weightByCat.update(
        _bagGear!.categoryId,
        (v) => v + bagW,
        ifAbsent: () => bagW,
      );
    }
    final weights = <CategoryWeight>[];
    for (final entry in weightByCat.entries) {
      final existing = metaByCat[entry.key];
      if (existing != null) {
        weights.add(
          CategoryWeight(
            categoryId: existing.categoryId,
            categoryName: existing.categoryName,
            icon: existing.icon,
            color: existing.color,
            totalWeightGrams: entry.value,
          ),
        );
      } else {
        final cat = _categories.where((c) => c.id == entry.key).firstOrNull;
        weights.add(
          CategoryWeight(
            categoryId: entry.key,
            categoryName: cat?.name ?? entry.key,
            icon: cat?.icon ?? 'box',
            color: cat?.color ?? '#888888',
            totalWeightGrams: entry.value,
          ),
        );
      }
    }
    weights.sort((a, b) => b.totalWeightGrams.compareTo(a.totalWeightGrams));
    _categoryWeights = weights;
    _totalWeight = itemsWeight + bagW;
    _totalValue = itemsValue + bagV;
  }

  Future<void> _updateQuantity(PackItemWithGear pwg, int qty) async {
    final max = pwg.gearItem.quantity.clamp(1, 1 << 30);
    final clamped = qty.clamp(1, max);
    final idx = _packItems.indexWhere((p) => p.packItem.id == pwg.packItem.id);
    if (idx < 0 || _packItems[idx].packItem.quantityInPack == clamped) return;
    final old = _packItems[idx];
    setState(() {
      _packItems[idx] = PackItemWithGear(
        packItem: old.packItem.copyWith(quantityInPack: clamped),
        gearItem: old.gearItem,
      );
      _recalculateTotals();
    });
    try {
      final dao = await PackItemDao.create();
      await dao.update(_packItems[idx].packItem);
      await _refreshSilent();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _packItems[idx] = old);
        _recalculateTotals();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  Future<void> _showQuantitySheet(PackItemWithGear pwg) async {
    final max = pwg.gearItem.quantity.clamp(1, 1 << 30);
    if (max <= 1) return;
    var selected = pwg.packItem.quantityInPack.clamp(1, max);
    final colors = AppColors.of(context);
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
          ),
          padding: EdgeInsets.fromLTRB(16.sp, 8.sp, 16.sp, 24.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.sp,
                height: 4.sp,
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(2.sp),
                ),
              ),
              SizedBox(height: 12.sp),
              Text(pwg.gearItem.name, style: AppTextStyles.titleLarge),
              Text(
                'Owned: $max — how many to take?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 12.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: PhosphorIcon(PhosphorIconsFill.caretUp, size: 24.sp),
                    onPressed: selected >= max
                        ? null
                        : () => setSheetState(() => selected++),
                    tooltip: 'Increase',
                  ),
                  Container(
                    constraints: BoxConstraints(minWidth: 56.sp),
                    alignment: Alignment.center,
                    child: Text(
                      '$selected',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 24.sp),
                    ),
                  ),
                  IconButton(
                    icon: PhosphorIcon(PhosphorIconsFill.caretDown, size: 24.sp),
                    onPressed: selected <= 1
                        ? null
                        : () => setSheetState(() => selected--),
                    tooltip: 'Decrease',
                  ),
                ],
              ),
              SizedBox(height: 4.sp),
              Text(
                '×$selected · ${formatWeight(pwg.gearItem.weightGrams * selected)} total',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 12.sp),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        UiConstants.buttonRadius.sp,
                      ),
                    ),
                  ),
                  child: Text('Save', style: AppTextStyles.bodyLarge.copyWith(
                    color: colors.onPrimary,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) await _updateQuantity(pwg, result);
  }

  Future<void> _removeGearItem(String packItemId) async {
    final removedIdx = _packItems.indexWhere((p) => p.packItem.id == packItemId);
    final removed = removedIdx >= 0 ? _packItems[removedIdx] : null;
    // Optimistic: update UI instantly without the full-screen spinner.
    if (removed != null) {
      setState(() {
        _packItems.removeAt(removedIdx);
        _recalculateTotals();
      });
    }
    try {
      final dao = await PackItemDao.create();
      await dao.delete(packItemId);
      await _refreshSilent();
      if (mounted) setState(() {});
    } catch (e) {
      // Roll back on failure.
      if (removed != null && mounted) {
        setState(() {
          _packItems.insert(
            removedIdx.clamp(0, _packItems.length),
            removed,
          );
          _recalculateTotals();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
      }
    }
  }

  Future<void> _addGearItem(String gearItemId) async {
    try {
      final dao = await PackItemDao.create();
      final gearDao = await GearItemDao.create();
      final gear = await gearDao.getById(gearItemId);
      final defaultQty = (gear?.quantity ?? 1).clamp(1, 1 << 30);
      final packItem = PackItem(
        id: const Uuid().v4(),
        packId: _pack.id,
        gearItemId: gearItemId,
        quantityInPack: defaultQty,
        sortOrder: _packItems.length,
      );
      await dao.insert(packItem);
      // Optimistic: append instantly if we have the gear details.
      if (gear != null && mounted) {
        setState(() {
          _packItems.add(PackItemWithGear(packItem: packItem, gearItem: gear));
          _recalculateTotals();
        });
      }
      await _refreshSilent();
      if (mounted) setState(() {});
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

  static const _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF ',
    'CNY': '¥',
    'INR': '₹',
    'BRL': 'R\$',
  };

  String _currencySymbolFor(String code) => _currencySymbols[code] ?? '$code ';

  String get _formattedTotalValue =>
      '$_currencySymbol${_totalValue.toStringAsFixed(2)}';

  void _showAddGearSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGearBottomSheet(
        excludeGearIds: _gearIdsInPack,
        onGearSelected: (gearItemId) {
          // Stay open to allow adding more items.
          _addGearItem(gearItemId);
        },
      ),
    ).then((_) async {
      await _refreshSilent();
      if (mounted) setState(() {});
    });
  }

  Future<void> _logTripFromPack() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LogTripPage(pack: _pack)),
    );
  }

  Future<void> _navigateToEditPack() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddPackPage(pack: _pack)),
    );
    if (result == true && mounted) {
      try {
        final dao = await PackDao.create();
        final updated = await dao.getById(_pack.id);
        if (updated != null) {
          setState(() => _pack = updated);
        }
      } catch (_) {
        // Best-effort refresh; fall through to silent refresh.
      }
      await _refreshSilent();
      if (mounted) setState(() {});
    }
  }

  Future<void> _deletePack() async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Pack', style: AppTextStyles.titleMedium),
        content: Text(
          'Delete "${_pack.name}"? This will also remove all items from the pack. This cannot be undone.',
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
              style: AppTextStyles.bodyMedium.copyWith(color: colors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final dao = await PackDao.create();
        await dao.delete(_pack.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Pack deleted')));
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final _totalWp = formatWeightParts(_totalWeight);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: false,
        title: Text(_pack.name, style: AppTextStyles.bodyMedium),
        backgroundColor: colors.background,
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIconsFill.backpack, size: 20.sp),
            onPressed: _logTripFromPack,
            tooltip: 'Log Trip from Pack',
          ),
          IconButton(
            icon: PhosphorIcon(PhosphorIconsFill.pen, size: 20.sp),
            onPressed: _navigateToEditPack,
            tooltip: 'Edit Pack',
          ),
          IconButton(
            icon: PhosphorIcon(PhosphorIconsFill.trash, size: 20.sp),
            onPressed: _deletePack,
            tooltip: 'Delete Pack',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total weight
                Container(
                  color: colors.primary,
                  padding: EdgeInsets.symmetric(
                    vertical: 16.sp,
                    horizontal: 16.sp,
                  ),
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
                                Radius.circular(
                                  UiConstants.compactCardRadius.sp,
                                ),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: PhosphorIcon(
                              PhosphorIconsFill.clipboardText,
                              size: 15.sp,
                              color: colors.onPrimary,
                            ),
                          ),
                          SizedBox(width: 5.sp),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TOTAL PACK WEIGHT",
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: colors.onPrimary,
                                ),
                              ),
                              Text(
                                "${_bagGear?.name} \u2219 ${_bagGear?.capacityLiters}",
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: colors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _totalWp.value,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 25.sp,
                              color: colors.onPrimary,
                            ),
                          ),
                          SizedBox(width: 2.sp),
                          Text(
                            _totalWp.unit,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                          if (_showLbs) ...[
                            SizedBox(width: 8.sp),
                            Text(
                              '(${formatLbs(_totalWeight)})',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: colors.onPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formattedTotalValue,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.sp),
                      // Progress bar by category
                      _buildWeightProgressBar(colors),
                    ],
                  ),
                ),
                // Tabs below weight
                TabBar(
                  controller: _tabController,
                  indicatorColor: colors.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: AppTextStyles.bodyMedium,
                  unselectedLabelStyle: AppTextStyles.bodyMedium,
                  labelPadding: EdgeInsets.symmetric(
                    vertical: 4.sp,
                    horizontal: 16.sp,
                  ),
                  tabs: [
                    Tab(text: 'Build ∙ $_gearCount'),
                    const Tab(text: 'Checklist'),
                  ],
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBuildTab(colors),
                      _buildChecklistTab(colors),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWeightProgressBar(AppColorPalette colors) {
    if (_categoryWeights.isEmpty || _totalWeight == 0) {
      return Container(height: 12.sp, decoration: BoxDecoration());
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
              child: Container(color: _categoryColor(cw.color)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _categoryColor(String hex) {
    return AppColors.parseHex(hex);
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
              : ListView(
                  children: [
                    if (_bagGear != null)
                      _buildBagCard(
                        colors,
                        _bagGear!,
                        _categoryIcon(_bagGear!.categoryId),
                      ),
                    ..._buildCategoryGroups(colors),
                  ],
                ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(12.sp),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddGearSheet,
                icon: PhosphorIcon(PhosphorIconsFill.plus, size: 16.sp),
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
                    borderRadius: BorderRadius.circular(
                      UiConstants.buttonRadius.sp,
                    ),
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
    return cat != null ? AppColors.parseHex(cat.color) : fallback;
  }

  /// Grouped category sections for the Build tab — one trailhead-style
  /// header per category (icon + name + item count · weight), then rows.
  List<Widget> _buildCategoryGroups(AppColorPalette colors) {
    final groups = <String, List<PackItemWithGear>>{};
    for (final pwg in _packItems) {
      groups.putIfAbsent(pwg.gearItem.categoryId, () => []).add(pwg);
    }
    if (groups.isEmpty) return [];

    // Master category order first, unknown ids last.
    final order = {
      for (var i = 0; i < _categories.length; i++) _categories[i].id: i,
    };
    final ids = groups.keys.toList()
      ..sort((a, b) => (order[a] ?? 1 << 30).compareTo(order[b] ?? 1 << 30));

    final widgets = <Widget>[];
    for (final id in ids) {
      final items = groups[id]!;
      final cat = _categories.where((c) => c.id == id).firstOrNull;
      final name = cat?.name ?? items.first.gearItem.categoryId;
      final weight = items.fold<double>(
        0,
        (sum, pwg) =>
            sum + pwg.gearItem.weightGrams * pwg.packItem.quantityInPack,
      );
      final count = items.fold<int>(
        0,
        (sum, pwg) => sum + pwg.packItem.quantityInPack,
      );
      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(12.sp, 10.sp, 12.sp, 2.sp),
          child: SectionHeader(
            title: name,
            spec: '$count · ${formatWeight(weight)}',
            icon: IconRegistry.resolve(cat?.icon ?? 'box'),
            iconColor: cat != null
                ? AppColors.parseHex(cat.color)
                : colors.textSecondary,
          ),
        ),
      );
      for (final pwg in items) {
        widgets.add(
          _buildMinimalGearCard(
            colors,
            pwg,
            _categoryIcon(pwg.gearItem.categoryId),
          ),
        );
      }
    }
    return widgets;
  }

  Future<void> _toggleCheck(PackItemWithGear pwg, bool? value) async {
    final newValue = value ?? !pwg.packItem.isChecked;
    final idx = _packItems.indexWhere((p) => p.packItem.id == pwg.packItem.id);
    if (idx < 0) return;
    final old = _packItems[idx];
    setState(() {
      _packItems[idx] = PackItemWithGear(
        packItem: old.packItem.copyWith(isChecked: newValue),
        gearItem: old.gearItem,
      );
    });
    try {
      final dao = await PackItemDao.create();
      await dao.update(_packItems[idx].packItem);
    } catch (e) {
      if (mounted) {
        setState(() => _packItems[idx] = old);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  /// Checklist tab — same category sections as Build, but each row is a
  /// checkbox with no weight and no add/remove actions.
  Widget _buildChecklistTab(AppColorPalette colors) {
    if (_packItems.isEmpty && _bagGear == null) {
      return Center(
        child: Text(
          'No gear added yet.\nAdd gear in the Build tab.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }
    final groups = <String, List<PackItemWithGear>>{};
    for (final pwg in _packItems) {
      groups.putIfAbsent(pwg.gearItem.categoryId, () => []).add(pwg);
    }
    final order = {
      for (var i = 0; i < _categories.length; i++) _categories[i].id: i,
    };
    final ids = groups.keys.toList()
      ..sort((a, b) => (order[a] ?? 1 << 30).compareTo(order[b] ?? 1 << 30));

    return ListView(
      children: [
        if (_bagGear != null)
          _buildChecklistSection(
            colors,
            name: _categories
                    .where((c) => c.id == _bagGear!.categoryId)
                    .firstOrNull
                    ?.name ??
                'Bag',
            iconKey: _categoryIcon(_bagGear!.categoryId),
            iconColor: _categoryColorById(
              _bagGear!.categoryId,
              colors.primary,
            ),
            checkedCount: _bagChecked ? 1 : 0,
            totalCount: 1,
            rows: [
              _buildChecklistRow(
                colors,
                name: _bagGear!.name,
                brand: _bagGear!.brand,
                checked: _bagChecked,
                onChanged: (v) =>
                    setState(() => _bagChecked = v ?? !_bagChecked),
              ),
            ],
          ),
        for (final id in ids)
          _buildChecklistSection(
            colors,
            name: _categories.where((c) => c.id == id).firstOrNull?.name ?? id,
            iconKey: _categoryIcon(id),
            iconColor: _categoryColorById(id, colors.textSecondary),
            checkedCount: groups[id]!
                .where((pwg) => pwg.packItem.isChecked)
                .length,
            totalCount: groups[id]!.length,
            rows: [
              for (final pwg in groups[id]!)
                _buildChecklistRow(
                  colors,
                  name: pwg.gearItem.name,
                  brand: pwg.gearItem.brand,
                  quantity: pwg.packItem.quantityInPack,
                  checked: pwg.packItem.isChecked,
                  onChanged: (v) => _toggleCheck(pwg, v),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildChecklistSection(
    AppColorPalette colors, {
    required String name,
    required String iconKey,
    required Color iconColor,
    required int checkedCount,
    required int totalCount,
    required List<Widget> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.sp, 10.sp, 12.sp, 2.sp),
          child: SectionHeader(
            title: name,
            spec: '$checkedCount/$totalCount',
            icon: IconRegistry.resolve(iconKey),
            iconColor: iconColor,
          ),
        ),
        ...rows,
      ],
    );
  }

  Widget _buildChecklistRow(
    AppColorPalette colors, {
    required String name,
    String? brand,
    int quantity = 1,
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
      child: Card.filled(
        color: colors.surface,
        elevation: UiConstants.cardElevation,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.compactCardRadius.sp),
          side: BorderSide(
            color: checked ? AppColors.statusGood : colors.border,
            width: checked
                ? UiConstants.borderWidth + 0.5
                : UiConstants.borderWidth,
          ),
        ),
        child: SizedBox(
          height: 56.sp,
          child: Row(
            children: [
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 13.sp,
                        decoration: checked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (brand != null || quantity > 1)
                      Text(
                        [
                          if (brand case final b) b,
                          if (quantity > 1) '×$quantity',
                        ].join(' · '),
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Checkbox(
                value: checked,
                onChanged: onChanged,
                activeColor: AppColors.statusGood,
              ),
              SizedBox(width: 8.sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBagCard(AppColorPalette colors, GearItem bag, String iconKey) {
    final _bagWp = formatWeightParts(bag.weightGrams);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
      child: Card.filled(
        color: colors.primaryContainer,
        elevation: UiConstants.cardElevation,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.compactCardRadius.sp),
          side: BorderSide(color: colors.primary, width: UiConstants.borderWidth),
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
                        child: PhosphorIcon(
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
                          Column(
                            children: [
                              Text(
                                _bagWp.value,
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: 13.sp,
                                ),
                              ),
                              Text(_bagWp.unit, style: AppTextStyles.bodySmall),
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

  Widget _buildMinimalGearCard(
    AppColorPalette colors,
    PackItemWithGear pwg,
    String iconKey,
  ) {
    final gear = pwg.gearItem;
    final qty = pwg.packItem.quantityInPack;
    final maxQty = gear.quantity;
    final adjustable = maxQty > 1;
    // Total weight for the taken quantity.
    final _gwp = formatWeightParts(gear.weightGrams * qty);
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
        child: InkWell(
          onTap: adjustable ? () => _showQuantitySheet(pwg) : null,
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
                        child: PhosphorIcon(
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
                          Text(
                            [
                              if (gear.brand != null) gear.brand!,
                              if (adjustable) '×$qty',
                            ].join(' · '),
                            style: AppTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Quantity (left of weight, tap card for popup stepper)
                    if (adjustable)
                      Padding(
                        padding: EdgeInsets.only(right: 8.sp),
                        child: Text(
                          '×$qty',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 13.sp,
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
                                _gwp.value,
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: 13.sp,
                                ),
                              ),
                              Text(_gwp.unit, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Remove button
                    SizedBox(
                      width: 36.sp,
                      child: IconButton(
                        icon: PhosphorIcon(
                          PhosphorIconsFill.x,
                          size: 14.sp,
                          color: colors.textSecondary,
                        ),
                        onPressed: () => _removeGearItem(pwg.packItem.id),
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
  List<GearItem> _allGear = [];
  List<Category> _categories = [];
  String _searchQuery = '';
  String? _selectedCategoryId;
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
        _allGear = filtered;
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
    return cat != null ? AppColors.parseHex(cat.color) : fallback;
  }

  List<GearItem> get _visibleGear {
    final query = _searchQuery.toLowerCase();
    return _allGear.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          (item.brand?.toLowerCase() ?? '').contains(query);
      final matchesCategory = _selectedCategoryId == null ||
          item.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _handleTap(GearItem gear) {
    widget.onGearSelected(gear.id);
    setState(() {
      _allGear.removeWhere((g) => g.id == gear.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
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
            padding: EdgeInsets.fromLTRB(12.sp, 4.sp, 12.sp, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Gear to Pack',
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Done', style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.sp, 4.sp, 12.sp, 4.sp),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search kit…',
                prefixIcon: SizedBox(
                  width: 40.sp,
                  child: Center(
                    child: PhosphorIcon(PhosphorIconsFill.magnifyingGlass, size: 14.sp),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    UiConstants.borderRadius,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.sp,
                  vertical: 12.sp,
                ),
                filled: true,
                fillColor: colors.surface,
                isDense: true,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value),
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          SizedBox(
            height: 48.sp,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.sp),
              children: [
                PatchChip(
                  label: 'All',
                  count: _allGear.length,
                  selected: _selectedCategoryId == null,
                  onSelected: (_) =>
                      setState(() => _selectedCategoryId = null),
                ),
                ..._categories.map((category) {
                  final count = _allGear
                      .where((i) => i.categoryId == category.id)
                      .length;
                  return Padding(
                    padding: EdgeInsets.only(left: 6.sp),
                    child: PatchChip(
                      label: category.name,
                      iconKey: category.icon,
                      iconColor: AppColors.parseHex(category.color),
                      count: count,
                      selected: _selectedCategoryId == category.id,
                      onSelected: (_) => setState(
                        () => _selectedCategoryId = category.id,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 4.sp),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _visibleGear.isEmpty
                ? Center(
                    child: Text(
                      _allGear.isEmpty
                          ? 'All gear is already in the pack\nor no gear available.'
                          : 'No matches. Try another search or category.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _visibleGear.length,
                    itemBuilder: (context, index) {
                      final gear = _visibleGear[index];
                      final iconKey = _getIconKey(gear.categoryId);

                      return ListTile(
                        leading: PhosphorIcon(
                          IconRegistry.resolve(iconKey),
                          size: 20.sp,
                          color: _categoryColorById(
                            gear.categoryId,
                            colors.primary,
                          ),
                        ),
                        title: Text(gear.name, style: AppTextStyles.bodyLarge),
                        subtitle: (gear.brand != null || gear.quantity > 1)
                            ? Text(
                                [
                                  if (gear.brand case final b) b,
                                  if (gear.quantity > 1) '×${gear.quantity}',
                                ].join(' · '),
                                style: AppTextStyles.bodySmall,
                              )
                            : null,
                        trailing: Text(
                          formatWeight(
                            gear.weightGrams * gear.quantity.clamp(1, 1 << 30),
                          ),
                          style: AppTextStyles.bodyMedium,
                        ),
                        onTap: () => _handleTap(gear),
                      );
                    },
                  ),
          ),
          SizedBox(height: bottomInset),
        ],
        ),
      ),
    );
  }
}
