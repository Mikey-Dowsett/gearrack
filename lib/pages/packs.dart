import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gearrack/database/pack_dao.dart';
import 'package:gearrack/database/pack_item_dao.dart';
import 'package:gearrack/database/gear_item_dao.dart';
import 'package:gearrack/models/pack.dart';
import 'package:gearrack/models/gear_item.dart';
import 'package:gearrack/widgets/pack_card.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/pages/add_pack.dart';
import 'package:gearrack/pages/pack.dart' as pack_detail;

class PacksPage extends StatefulWidget {
  const PacksPage({super.key});

  @override
  State<PacksPage> createState() => _PacksPageState();
}

class _PacksPageState extends State<PacksPage> {
  List<Pack> _packs = [];
  List<GearItem> _bags = [];
  bool _isLoading = true;

  // Cached stats per pack id
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

  Future<void> _navigateToAddPack() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddPackPage()),
    );

    if (result == true && mounted) {
      _loadPacks();
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('My Packs', style: AppTextStyles.titleLarge),
                  const SizedBox(width: 8),
                  Text(
                    '\u2022 ${_packs.length} pack${_packs.length != 1 ? 's' : ''}',
                    style: AppTextStyles.bodyMedium,
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
                        Text('No packs yet', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to build your first pack',
                          style: AppTextStyles.bodySmall,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPack,
        child: const Icon(Icons.add),
      ),
    );
  }

  double? _getBagCapacity(String? bagId) {
    if (bagId == null) return null;
    final bag = _bags.where((b) => b.id == bagId).firstOrNull;
    return bag?.capacityLiters;
  }
}
