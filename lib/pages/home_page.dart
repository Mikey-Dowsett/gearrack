import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gearrack/database/gear_item_dao.dart';
import 'package:gearrack/models/gear_item.dart';
import 'package:gearrack/widgets/gear_card.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/pages/add_gear.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GearItem> _gearItems = [];
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
      final items = await dao.getAll();
      setState(() {
        _gearItems = items;
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
                              // prefixIcon: FaIcon(FontAwesomeIcons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.sp),
                              ),
                              filled: true,
                              fillColor: colors.surface,
                            ),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _gearItems.length,
                            itemBuilder: (context, index) {
                              return GearCard(
                                gear: _gearItems[index],
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
