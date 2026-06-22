import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gearrack/database/gear_item_dao.dart';
import 'package:gearrack/database/category_dao.dart';
import 'package:gearrack/models/gear_item.dart';
import 'package:gearrack/models/category.dart';
import 'package:gearrack/widgets/gear_card.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/pages/add_gear.dart';
import 'package:gearrack/utils/icon_registry.dart';
import 'package:gearrack/theme/app_colors.dart' show AppColors;
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
  int _sortMode = 0; // 0 = name (A-Z), 1 = weight, 2 = price

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

    // If a new gear item was added, refresh the list
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
                  Text('My Inventory', style: AppTextStyles.titleLarge),
                  Text(' \u2022 ', style: AppTextStyles.bodyMedium),
                  Text(
                    '${_gearItems.length} item${_gearItems.length != 1 ? 's' : ''} tracked',
                    style: AppTextStyles.bodyMedium,
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
                        Text('No gear yet', style: AppTextStyles.bodyMedium),

                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first item',
                          style: AppTextStyles.bodySmall,
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
                              hintText: 'Search...',
                              prefixIcon: SizedBox(
                                width: 40.sp,
                                child: Center(
                                  child: FaIcon(FontAwesomeIcons.search),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.sp),
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
                            style: AppTextStyles.bodyMedium,
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
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: colors.border,
                                    width: UiConstants.borderWidth,
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
                                        FaIcon(
                                          IconRegistry.resolve(category.icon),
                                          size: 15.sp,
                                          color: catColor,
                                        ),
                                        SizedBox(width: 5.sp),
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
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: colors.border,
                                        width: UiConstants.borderWidth,
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
                              Text(
                                '${_filteredGearItems.length} items \u2219 ${formatWeight(_totalGrams)} total',
                                style: AppTextStyles.bodyMedium,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddGear,
        child: const Icon(Icons.add),
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
      icon: FaIcon(FontAwesomeIcons.arrowDownWideShort, size: 14.sp),
      label: Text(_label, style: TextStyle(fontSize: 12.sp)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.border, width: UiConstants.borderWidth),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.sp),
        ),
      ),
    );
  }
}
