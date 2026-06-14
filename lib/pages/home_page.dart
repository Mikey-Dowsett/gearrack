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
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.sp, top: 16.sp, bottom: 8.sp),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Inventory', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
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
                          padding: EdgeInsets.all(8.sp),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: SizedBox(
                                width: 36.sp,
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
                          height: 44.sp,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 10.sp),
                            children: [
                              ChoiceChip(
                                label: Text('All'),
                                selected: _selectedCategoryId == null,
                                onSelected: (_) {
                                  setState(() => _selectedCategoryId = null);
                                  _applyFilters();
                                },
                              ),
                              ..._categories.map((category) {
                                final chipColor = Color(
                                  int.parse(
                                    category.color.replaceFirst('#', '0xFF'),
                                  ),
                                );
                                final count = _gearItems
                                    .where((i) => i.categoryId == category.id)
                                    .length;
                                return Padding(
                                  padding: EdgeInsets.only(left: 5.sp),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FaIcon(
                                          IconRegistry.resolve(category.icon),
                                          size: 15.sp,
                                        ),
                                        SizedBox(width: 5.sp),
                                        Text('${category.name}\u2219$count'),
                                      ],
                                    ),
                                    selected:
                                        _selectedCategoryId == category.id,
                                    selectedColor: chipColor.withValues(
                                      alpha: 1,
                                    ),
                                    onSelected: (_) {
                                      setState(
                                        () => _selectedCategoryId = category.id,
                                      );
                                      _applyFilters();
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredGearItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredGearItems[index];
                              final categoryIdx = _categories.indexWhere(
                                (c) => c.id == item.categoryId,
                              );
                              final iconKey = categoryIdx != -1
                                  ? _categories[categoryIdx].icon
                                  : 'box';
                              return GearCard(
                                gear: item,
                                categoryIcon: iconKey,
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
