import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:gearrack/database/gear_item_dao.dart';
import 'package:gearrack/database/category_dao.dart';
import 'package:gearrack/models/gear_item.dart';
import 'package:gearrack/models/category.dart';
import 'package:gearrack/widgets/gear_card.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/pages/add_gear.dart';
import 'package:gearrack/utils/icon_registry.dart';
import 'package:gearrack/theme/ui_constants.dart';
import 'package:gearrack/utils/weight_formatter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GearItem> _gearItems = [];
  List<GearItem> _filteredGearItems = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;
  int _sortMode = 0;

  @override
  void initState() {
    super.initState();
    _loadGear();
  }

  Future<void> _loadGear() async {
    setState(() => _isLoading = true);
    try {
      final dao = await GearItemDao.create();
      final categoryDao = await CategoryDao.create();
      final items = await dao.getAll();
      final categories = await categoryDao.getAll();
      setState(() {
        _gearItems = items;
        _categories = categories;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load gear: $e')));
      }
    }
  }

  Future<void> _navigateToAddGear() async {
    final result = await Navigator.push<GearItem>(
      context,
      MaterialPageRoute(builder: (context) => const AddGearPage()),
    );

    if (result != null) {
      _loadGear();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredGearItems = _gearItems.where((item) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch =
            _searchQuery.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            (item.brand?.toLowerCase() ?? '').contains(query);

        final matchesCategory =
            _selectedCategoryId == null ||
            item.categoryId == _selectedCategoryId;

        return matchesSearch && matchesCategory;
      }).toList();
      _applySort();
    });
  }

  void _applySort() {
    switch (_sortMode) {
      case 0:
        _filteredGearItems.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 1:
        _filteredGearItems.sort(
          (a, b) => a.weightGrams.compareTo(b.weightGrams),
        );
        break;
      case 2:
        _filteredGearItems.sort(
          (a, b) => (a.price ?? 0).compareTo(b.price ?? 0),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final _totalGrams = _filteredGearItems.fold(
      0.0,
      (sum, item) => sum + item.weightGrams,
    );

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
                    'Basecamp',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: colors.onBackground,
                    ),
                  ),
                  Text(
                    ' • ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.onBackground,
                    ),
                  ),
                  Text(
                    '${_gearItems.length} ITEMS TRACKED'.toUpperCase(),
                    style: AppTextStyles.specSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _gearItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pack’s empty — let’s fix that',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.onBackground,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Log your first piece of kit below',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGear,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 12.sp,
                            right: 12.sp,
                            top: 4.sp,
                            bottom: 4.sp,
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search kit…',
                              prefixIcon: SizedBox(
                                width: 40.sp,
                                child: Center(
                                  child: PhosphorIcon(PhosphorIconsFill.magnifyingGlass),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(UiConstants.borderRadius),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.sp,
                                vertical: 12.sp,
                              ),
                              filled: true,
                              fillColor: colors.surface,
                            ),
                            onChanged: (value) {
                              _searchQuery = value;
                              _applyFilters();
                            },
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
                              ChoiceChip(
                                label: Text('All'),
                                selected: _selectedCategoryId == null,
                                onSelected: (_) {
                                  setState(() => _selectedCategoryId = null);
                                  _applyFilters();
                                },
                                showCheckmark: false,
                                selectedColor: colors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    UiConstants.chipRadius.sp,
                                  ),
                                ),
                              ),
                              ..._categories.map((category) {
                                final count = _gearItems
                                    .where((i) => i.categoryId == category.id)
                                    .length;
                                final catColor = AppColors.parseHex(
                                  category.color,
                                );
                                return Padding(
                                  padding: EdgeInsets.only(left: 6.sp),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PhosphorIcon(
                                          IconRegistry.resolve(category.icon),
                                          size: 15.sp,
                                          color: catColor,
                                        ),
                                        SizedBox(
                                          width: UiConstants.spacingXS.sp,
                                        ),
                                        Text('${category.name}∙$count'),
                                      ],
                                    ),
                                    selected:
                                        _selectedCategoryId == category.id,
                                    selectedColor: colors.primary,
                                    onSelected: (_) {
                                      setState(
                                        () => _selectedCategoryId = category.id,
                                      );
                                      _applyFilters();
                                    },
                                    showCheckmark: false,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        UiConstants.chipRadius.sp,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        SizedBox(height: 2.sp),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.sp),
                          child: Row(
                            children: [
                              Container(
                                width: 4.sp,
                                height: 16.sp,
                                decoration: BoxDecoration(
                                  color: colors.tertiary,
                                  borderRadius: BorderRadius.circular(1.sp),
                                ),
                              ),
                              SizedBox(width: 6.sp),
                              Text(
                                '${_filteredGearItems.length} items ∙ ${formatWeight(_totalGrams)} total',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: colors.onBackground,
                                ),
                              ),
                              Spacer(),
                              _SortButton(
                                sortMode: _sortMode,
                                onPressed: () {
                                  setState(() {
                                    _sortMode = (_sortMode + 1) % 3;
                                    _applySort();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 2.sp),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredGearItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredGearItems[index];
                              final categoryIdx = _categories.indexWhere(
                                (c) => c.id == item.categoryId,
                              );
                              final cat = categoryIdx != -1
                                  ? _categories[categoryIdx]
                                  : null;
                              final iconKey = cat?.icon ?? 'box';
                              final catColor = cat != null
                                  ? AppColors.parseHex(cat.color)
                                  : null;
                              return GearCard(
                                gear: item,
                                categoryIcon: iconKey,
                                categoryColor: catColor,
                                onGearUpdated: _loadGear,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddGear,
        icon: const Icon(Icons.add),
        label: const Text('LOG GEAR'),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final int sortMode;
  final VoidCallback onPressed;

  const _SortButton({required this.sortMode, required this.onPressed});

  String get _label {
    switch (sortMode) {
      case 0:
        return 'Name';
      case 1:
        return 'Weight';
      case 2:
        return 'Price';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: PhosphorIcon(PhosphorIconsFill.arrowsDownUp, size: 14.sp),
      label: Text(_label, style: TextStyle(fontSize: 12.sp)),
      style: OutlinedButton.styleFrom(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.buttonRadius.sp),
        ),
      ),
    );
  }
}
