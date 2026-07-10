import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gearrack/database/gear_item_dao.dart';
import 'package:gearrack/database/category_dao.dart';
import 'package:gearrack/database/pack_dao.dart';
import 'package:gearrack/database/pack_item_dao.dart';
import 'package:gearrack/database/trip_dao.dart';
import 'package:gearrack/database/pack_dao.dart' as pack_dao;
import 'package:gearrack/models/gear_item.dart';
import 'package:gearrack/models/category.dart';
import 'package:gearrack/models/pack.dart';
import 'package:gearrack/models/trip.dart';
import 'package:gearrack/widgets/gear_card.dart';
import 'package:gearrack/widgets/pack_card.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/theme/ui_constants.dart';
import 'package:gearrack/pages/add_gear.dart';
import 'package:gearrack/pages/add_pack.dart';
import 'package:gearrack/pages/log_trip_page.dart';
import 'package:gearrack/pages/trip_detail_page.dart';
import 'package:gearrack/pages/pack_page.dart' as pack_detail;
import 'package:gearrack/utils/icon_registry.dart';
import 'package:gearrack/utils/weight_formatter.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleFabPress() {
    switch (_tabController.index) {
      case 0:
        _navigateToAddGear();
        break;
      case 1:
        _navigateToAddPack();
        break;
      case 2:
        _navigateToLogTrip();
        break;
    }
  }

  Future<void> _navigateToAddGear() async {
    final result = await Navigator.push<GearItem>(
      context,
      MaterialPageRoute(builder: (context) => const AddGearPage()),
    );

    if (result != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _navigateToAddPack() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddPackPage()),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _navigateToLogTrip() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LogTripPage()),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  IconData _fabIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.add;
      case 1:
        return Icons.add;
      case 2:
        return Icons.add;
      default:
        return Icons.add;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
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
              tabs: const [
                Tab(text: 'Gear'),
                Tab(text: 'Packs'),
                Tab(text: 'Trips'),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 64.sp),
                child: IndexedStack(
                  index: _tabController.index,
                  children: const [
                    _GearTab(),
                    _PacksTab(),
                    _TripsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFabPress,
        child: Icon(_fabIcon()),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gear Tab
// ---------------------------------------------------------------------------

class _GearTab extends StatefulWidget {
  const _GearTab();

  @override
  State<_GearTab> createState() => _GearTabState();
}

class _GearTabState extends State<_GearTab> {
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

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.sp, top: 12.sp, bottom: 8.sp),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'My Inventory',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: colors.onBackground,
                  ),
                ),
                Text(
                  ' \u2022 ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.onBackground,
                  ),
                ),
                Text(
                  '${_gearItems.length} item${_gearItems.length != 1 ? 's' : ''} tracked',
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
              : _gearItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No gear yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first item',
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
                            hintText: 'Search...',
                            prefixIcon: SizedBox(
                              width: 40.sp,
                              child: Center(
                                child: FaIcon(FontAwesomeIcons.search),
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
                                      FaIcon(
                                        IconRegistry.resolve(category.icon),
                                        size: 15.sp,
                                        color: catColor,
                                      ),
                                      SizedBox(
                                        width: UiConstants.spacingXS.sp,
                                      ),
                                      Text('${category.name}\u2022$count'),
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
                              '${_filteredGearItems.length} items \u2022 ${formatWeight(_totalGrams)} total',
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

// ---------------------------------------------------------------------------
// Packs Tab
// ---------------------------------------------------------------------------

class _PacksTab extends StatefulWidget {
  const _PacksTab();

  @override
  State<_PacksTab> createState() => _PacksTabState();
}

class _PacksTabState extends State<_PacksTab> {
  List<Pack> _packs = [];
  List<GearItem> _bags = [];
  bool _isLoading = true;

  Map<String, double> _totalWeights = {};
  Map<String, int> _totalItemCounts = {};
  Map<String, String> _bagNames = {};

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    setState(() => _isLoading = true);
    try {
      final packDao = await PackDao.create();
      final gearDao = await GearItemDao.create();
      final packItemDao = await PackItemDao.create();

      final packs = await packDao.getAll();
      final bags = await gearDao.getPacks();

      final Map<String, double> weights = {};
      final Map<String, int> counts = {};
      final Map<String, String> bagNames = {};

      for (final pack in packs) {
        weights[pack.id] = await packItemDao.getTotalWeightByPack(pack.id);
        counts[pack.id] = await packItemDao.getItemCountByPack(pack.id);

        if (pack.bagId != null) {
          final bag = bags.where((b) => b.id == pack.bagId).firstOrNull;
          bagNames[pack.id] = bag?.name ?? '';
        }
      }

      setState(() {
        _packs = packs;
        _bags = bags;
        _totalWeights = weights;
        _totalItemCounts = counts;
        _bagNames = bagNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load packs: $e')));
      }
    }
  }

  Future<void> _navigateToPackDetail(Pack pack) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pack_detail.PackPage(pack: pack)),
    );
    if (mounted) {
      _loadPacks();
    }
  }

  double? _getBagCapacity(String? bagId) {
    if (bagId == null) return null;
    final bag = _bags.where((b) => b.id == bagId).firstOrNull;
    return bag?.capacityLiters;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.sp, top: 12.sp, bottom: 8.sp),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'My Packs',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: colors.onBackground,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\u2022 ${_packs.length} pack${_packs.length != 1 ? 's' : ''}',
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
              : _packs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                      'No packs yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to build your first pack',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                  onRefresh: _loadPacks,
                  child: ListView.builder(
                    itemCount: _packs.length,
                    itemBuilder: (context, index) {
                      final pack = _packs[index];
                      return PackCard(
                        pack: pack,
                        bagName: _bagNames[pack.id],
                        totalWeightGrams: _totalWeights[pack.id] ?? 0,
                        totalItems: _totalItemCounts[pack.id] ?? 0,
                        capacityLiters: _getBagCapacity(pack.bagId),
                        onTap: () => _navigateToPackDetail(pack),
                        onPackUpdated: _loadPacks,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trips Tab
// ---------------------------------------------------------------------------

class _TripsTab extends StatefulWidget {
  const _TripsTab();

  @override
  State<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<_TripsTab> {
  List<Trip> _trips = [];
  Map<String, double> _totalWeights = {};
  Map<String, int> _itemCounts = {};
  Map<String, String> _packNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final dao = await TripDao.create();
      final packDao = await pack_dao.PackDao.create();
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

  Future<void> _navigateToTripDetail(Trip trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripDetailPage(tripId: trip.id)),
    );
    if (mounted) {
      _load();
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

    return Column(
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
                  '\u2022 ${_trips.length} trip${_trips.length != 1 ? 's' : ''}',
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
                  onRefresh: _load,
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
                            elevation: UiConstants.cardElevation,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                UiConstants.cardRadius.sp,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: colors.border, width: 1),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                                    FontAwesomeIcons.calendarDays,
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
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}