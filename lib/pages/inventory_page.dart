import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:gearrack/database/gear_item_dao.dart';
import 'package:gearrack/database/category_dao.dart';
import 'package:gearrack/database/app_settings_dao.dart';
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
import 'package:gearrack/pages/settings_page.dart';
import 'package:gearrack/utils/weight_formatter.dart';
import 'package:gearrack/widgets/patch_chip.dart';
import 'package:gearrack/widgets/section_header.dart';

class InventoryPage extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const InventoryPage({super.key, this.onThemeChanged});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int _selectedIndex = 0;
  final GlobalKey<GearTabState> _gearKey = GlobalKey<GearTabState>();
  final GlobalKey<PacksTabState> _packsKey = GlobalKey<PacksTabState>();
  final GlobalKey<TripsTabState> _tripsKey = GlobalKey<TripsTabState>();

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(onThemeChanged: widget.onThemeChanged),
      ),
    );
  }

  void _handleFabPress() {
    switch (_selectedIndex) {
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
      await _gearKey.currentState?.refresh();
      setState(() {});
    }
  }

  Future<void> _navigateToAddPack() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddPackPage()),
    );

    if (result == true && mounted) {
      await _packsKey.currentState?.refresh();
      await _gearKey.currentState?.refresh();
      setState(() {});
    }
  }

  Future<void> _navigateToLogTrip() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LogTripPage()),
    );
    if (result == true && mounted) {
      await _tripsKey.currentState?.refresh();
      setState(() {});
    }
  }

  IconData _fabIcon() {
    return Icons.add;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        toolbarHeight: 32.sp,
        automaticallyImplyLeading: false,
        title: Text(
          'GearRack',
          style: AppTextStyles.specSmall.copyWith(
            color: colors.textSecondary,
            letterSpacing: 1.4,
            fontSize: 11.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIconsFill.gear, size: 14.sp, color: colors.textSecondary),
            onPressed: _openSettings,
            tooltip: 'Settings',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: 32.sp, height: 32.sp),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            GearTab(key: _gearKey),
            PacksTab(key: _packsKey),
            TripsTab(key: _tripsKey),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFabPress,
        child: Icon(_fabIcon()),
      ),
      bottomNavigationBar: SafeArea(
        left: false,
        right: false,
        bottom: true,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colors.borderStrong,
                width: UiConstants.borderWidth,
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: colors.surfaceRaised,
            elevation: 0,
            currentIndex: _selectedIndex,
            selectedItemColor: colors.primary,
            unselectedItemColor: colors.textSecondary,
            showUnselectedLabels: true,
            onTap: _onTabTapped,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsFill.tent),
                label: 'Gear',
              ),
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsFill.backpack),
                label: 'Packs',
              ),
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsFill.path),
                label: 'Trips',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gear Tab
// ---------------------------------------------------------------------------

class GearTab extends StatefulWidget {
  const GearTab({super.key});

  @override
  State<GearTab> createState() => GearTabState();
}

class GearTabState extends State<GearTab> {
  List<GearItem> _gearItems = [];
  List<GearItem> _filteredGearItems = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;
  int _sortMode = 0;
  bool _sortAscending = true;
  String _currencySymbol = '\$';

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

  @override
  void initState() {
    super.initState();
    _loadGear();
  }

  Future<void> refresh() => _loadGear();

  Future<void> _loadGear() async {
    setState(() => _isLoading = true);
    try {
      final dao = await GearItemDao.create();
      final categoryDao = await CategoryDao.create();
      final settingsDao = await AppSettingsDao.create();
      final items = await dao.getAll();
      final categories = await categoryDao.getAll();
      final settings = await settingsDao.get();
      setState(() {
        _gearItems = items;
        _categories = categories;
        _currencySymbol =
            _currencySymbols[settings.currency] ?? '${settings.currency} ';
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
    final catNames = {for (final c in _categories) c.id: c.name};
    int compare(GearItem a, GearItem b) {
      switch (_sortMode) {
        case 1:
          return a.weightGrams.compareTo(b.weightGrams);
        case 2:
          return (a.price ?? 0).compareTo(b.price ?? 0);
        case 3:
          final byCat = (catNames[a.categoryId] ?? a.categoryId)
              .compareTo(catNames[b.categoryId] ?? b.categoryId);
          if (byCat != 0) return byCat;
          return a.name.compareTo(b.name);
        case 0:
        default:
          return a.name.compareTo(b.name);
      }
    }

    _filteredGearItems.sort(
      (a, b) => _sortAscending ? compare(a, b) : compare(b, a),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final _totalGrams = _filteredGearItems.fold(
      0.0,
      (sum, item) => sum + item.weightGrams,
    );
    final _totalPrice = _filteredGearItems.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0) * item.quantity,
    );

    return Column(
      children: [
        TopoBackdrop(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12.sp,
              right: 12.sp,
              top: 24.sp,
              bottom: 20.sp,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionHeader(
                title: 'Basecamp',
                spec: '${_gearItems.length} items',
              ),
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
                            PatchChip(
                              label: 'All',
                              count: _gearItems.length,
                              selected: _selectedCategoryId == null,
                              onSelected: (_) {
                                setState(() => _selectedCategoryId = null);
                                _applyFilters();
                              },
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
                                child: PatchChip(
                                  label: category.name,
                                  iconKey: category.icon,
                                  iconColor: catColor,
                                  count: count,
                                  selected:
                                      _selectedCategoryId == category.id,
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
                            Expanded(
                              child: Text(
                                '${_filteredGearItems.length} · ${formatWeight(_totalGrams)} · $_currencySymbol${_totalPrice.toStringAsFixed(2)}'
                                    .toUpperCase(),
                                style: AppTextStyles.specSmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 12.sp),
                            _SortButton(
                              sortMode: _sortMode,
                              onPressed: () {
                                setState(() {
                                  _sortMode = (_sortMode + 1) % 4;
                                  _applySort();
                                });
                              },
                            ),
                            SizedBox(width: 6.sp),
                            _SortDirectionButton(
                              ascending: _sortAscending,
                              onPressed: () {
                                setState(() {
                                  _sortAscending = !_sortAscending;
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
      case 3:
        return 'Category';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return OutlinedButton(
      onPressed: onPressed,
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
      child: Text(_label, style: TextStyle(fontSize: 12.sp)),
    );
  }
}

class _SortDirectionButton extends StatelessWidget {
  final bool ascending;
  final VoidCallback onPressed;

  const _SortDirectionButton({
    required this.ascending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: ascending ? colors.primary : colors.surface,
        foregroundColor: ascending ? colors.onPrimary : colors.onSurface,
        padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.buttonRadius.sp),
        ),
      ),
      child: PhosphorIcon(
        ascending
            ? PhosphorIconsFill.arrowsDownUp
            : PhosphorIconsFill.arrowsDownUp,
        size: 14.sp,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Packs Tab
// ---------------------------------------------------------------------------

class PacksTab extends StatefulWidget {
  const PacksTab({super.key});

  @override
  State<PacksTab> createState() => PacksTabState();
}

class PacksTabState extends State<PacksTab> {
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

  Future<void> refresh() => _loadPacks();

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
        final itemsWeight = await packItemDao.getTotalWeightByPack(pack.id);
        final itemsCount = await packItemDao.getItemQuantitySumByPack(pack.id);

        GearItem? bag;
        if (pack.bagId != null) {
          bag = bags.where((b) => b.id == pack.bagId).firstOrNull;
          bagNames[pack.id] = bag?.name ?? '';
        }
        // Match pack detail semantics: totals include the backpack itself.
        weights[pack.id] = itemsWeight + (bag?.weightGrams ?? 0);
        counts[pack.id] = itemsCount + (bag != null ? 1 : 0);
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
        TopoBackdrop(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12.sp,
              right: 12.sp,
              top: 24.sp,
              bottom: 20.sp,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionHeader(
                title: 'Pack Out',
                spec: '${_packs.length} packs',
              ),
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

class TripsTab extends StatefulWidget {
  const TripsTab({super.key});

  @override
  State<TripsTab> createState() => TripsTabState();
}

class TripsTabState extends State<TripsTab> {
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

  Future<void> refresh() => _load();

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
        TopoBackdrop(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12.sp,
              right: 12.sp,
              top: 24.sp,
              bottom: 20.sp,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionHeader(
                title: 'Trail Log',
                spec: '${_trips.length} trips',
              ),
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
                                      color: colors.primary,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: colors.border,
                                          width: UiConstants.borderWidth,
                                        ),
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
                                                  PhosphorIcon(
                                                    PhosphorIconsFill.calendar,
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
                                                      PhosphorIcon(
                                                        PhosphorIconsFill.mapPin,
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
                                                      PhosphorIcon(
                                                        PhosphorIconsFill.backpack,
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
                                        PhosphorIcon(
                                          PhosphorIconsFill.package,
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
                                          PhosphorIcon(
                                            PhosphorIconsFill.tag,
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