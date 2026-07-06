import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../theme/ui_constants.dart';
import '../models/pack.dart';
import '../models/trip.dart';
import '../models/trip_item.dart';
import '../models/gear_item.dart';
import '../database/trip_dao.dart';
import '../database/pack_dao.dart';
import '../database/pack_item_dao.dart';
import '../database/gear_item_dao.dart';
import '../database/category_dao.dart';
import '../models/category.dart';
import '../utils/icon_registry.dart';
import '../utils/weight_formatter.dart';
import 'package:gearrack/database/app_settings_dao.dart';
import 'package:gearrack/pages/profile_page.dart';

/// A "trip item candidate" used while the user is composing their trip.
/// Wraps a gear item reference (nullable) with user-facing fields the
/// user can toggle/configure before saving.
class _TripItemCandidate {
  final String? gearItemId;
  String itemName;
  double weightGrams;
  int quantity;
  bool isSelected;

  _TripItemCandidate({
    this.gearItemId,
    required this.itemName,
    required this.weightGrams,
    this.quantity = 1,
    this.isSelected = true,
  });
}

class LogTripPage extends StatefulWidget {
  /// Optional pack to pre-fill items from.
  final Pack? pack;

  /// Existing trip to edit (mutually exclusive with [pack]).
  final Trip? trip;

  /// Existing trip items when editing.
  final List<TripItem>? tripItems;

  const LogTripPage({super.key, this.pack, this.trip, this.tripItems});

  bool get isEditing => trip != null;

  @override
  State<LogTripPage> createState() => _LogTripPageState();
}

class _LogTripPageState extends State<LogTripPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String? _activityType;
  bool _isMultiDay = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _proMode = false;

  // For "log from pack" mode
  Pack? _selectedPack;
  List<Pack> _availablePacks = [];

  // For "from scratch" mode — all gear items to pick from
  List<GearItem> _allGearItems = [];
  List<Category> _categories = [];

  /// The items the user is configuring for this trip.
  List<_TripItemCandidate> _candidates = [];

  bool get _isFromPack => widget.pack != null || _selectedPack != null;
  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settingsDao = await AppSettingsDao.create();
      final settings = await settingsDao.get();
      _proMode = settings.proMode;

      if (!_proMode) {
        setState(() => _isLoading = false);
        return;
      }

      final packDao = await PackDao.create();
      final gearDao = await GearItemDao.create();
      final categoryDao = await CategoryDao.create();

      final packs = await packDao.getAll();
      final gearItems = await gearDao.getAll();
      final categories = await categoryDao.getAll();

      if (widget.pack != null) {
        _selectedPack = widget.pack;
        _nameController.text = widget.pack!.name;
        await _loadPackItems(widget.pack!);
      }

      // If editing, pre-populate fields from the existing trip.
      if (widget.trip != null) {
        final t = widget.trip!;
        _nameController.text = t.name;
        _startDate = t.startDate;
        _endDate = t.endDate;
        _isMultiDay = t.endDate != null;
        _activityType = t.activityType;
        if (t.location != null) _locationController.text = t.location!;
        if (t.conditions != null) _conditionsController.text = t.conditions!;
        if (t.notes != null) _notesController.text = t.notes!;

        if (widget.tripItems != null) {
          _candidates = widget.tripItems!.map((ti) {
            return _TripItemCandidate(
              gearItemId: ti.gearItemId,
              itemName: ti.itemName,
              weightGrams: ti.weightGrams,
              quantity: ti.quantity,
              isSelected: true,
            );
          }).toList();
        }
      }

      setState(() {
        _availablePacks = packs;
        _allGearItems = gearItems;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  Future<void> _loadPackItems(Pack pack) async {
    try {
      final packItemDao = await PackItemDao.create();
      final items = await packItemDao.getByPackWithGear(pack.id);

      setState(() {
        _candidates = items.map((pwg) {
          return _TripItemCandidate(
            gearItemId: pwg.gearItem.id,
            itemName: pwg.gearItem.name,
            weightGrams: pwg.gearItem.weightGrams,
            quantity: pwg.packItem.quantityInPack,
            isSelected: true,
          );
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pack items: $e')),
        );
      }
    }
  }

  void _onPackSelected(Pack? pack) {
    setState(() {
      _selectedPack = pack;
      _candidates = [];
    });
    if (pack != null) {
      _nameController.text = pack.name;
      _loadPackItems(pack);
    }
  }

  void _addManualItem() {
    // Show a bottom sheet or dialog to pick a gear item and set quantity.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGearToTripSheet(
        gearItems: _allGearItems,
        categories: _categories,
        onSelected: (gearItem, quantity) {
          Navigator.of(ctx).pop();
          setState(() {
            _candidates.add(
              _TripItemCandidate(
                gearItemId: gearItem.id,
                itemName: gearItem.name,
                weightGrams: gearItem.weightGrams,
                quantity: quantity,
                isSelected: true,
              ),
            );
          });
        },
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        final scale = MediaQuery.textScalerOf(context).textScaleFactor;
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedItems = _candidates.where((c) => c.isSelected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item for the trip')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dao = await TripDao.create();

      final tripItems = selectedItems.map((c) {
        return TripItem(
          id: _uuid.v4(),
          tripId: '', // will be set by the DAO
          gearItemId: c.gearItemId,
          itemName: c.itemName,
          weightGrams: c.weightGrams,
          quantity: c.quantity,
        );
      }).toList();

      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (_selectedPack?.name ?? 'Untitled Trip');

      if (_isEditing) {
        final updatedTrip = widget.trip!.copyWith(
          name: name,
          startDate: _startDate,
          endDate: _isMultiDay ? _endDate : null,
          activityType: _activityType,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          conditions: _conditionsController.text.trim().isNotEmpty
              ? _conditionsController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
        await dao.updateTripWithItems(trip: updatedTrip, items: tripItems);
      } else {
        await dao.logTripFromScratch(
          name: name,
          items: tripItems,
          packId: _selectedPack?.id,
          startDate: _startDate,
          endDate: _isMultiDay ? _endDate : null,
          activityType: _activityType,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          conditions: _conditionsController.text.trim().isNotEmpty
              ? _conditionsController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Trip updated!' : 'Trip logged!'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to log trip: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  Widget _fieldLabel(String label, {bool required = false}) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: colors.onBackground),
        ),
        if (required) ...[
          SizedBox(width: 4.sp),
          Text(
            '*',
            style: AppTextStyles.labelMedium.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    bool requiredField = false,
    TextInputType? keyboardType,
    TextEditingController? controller,
    int? minLines,
    int? maxLines,
  }) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, required: requiredField),
        SizedBox(height: 6.sp),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UiConstants.borderRadius),
              borderSide: BorderSide(
                color: colors.border,
                width: UiConstants.borderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UiConstants.borderRadius),
              borderSide: BorderSide(
                color: colors.border,
                width: UiConstants.borderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UiConstants.borderRadius),
              borderSide: BorderSide(
                color: colors.primary,
                width: UiConstants.borderWidth,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.sp,
              vertical: 14.sp,
            ),
          ),
          validator: (value) {
            if (requiredField && (value == null || value.trim().isEmpty)) {
              return 'Required';
            }
            return null;
          },
        ),
        SizedBox(height: 12.sp),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final double buttonHeight = 56.sp;

    if (!_isLoading && !_proMode) {
      return _buildProGate(colors);
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _isEditing
              ? 'Edit Trip'
              : (_isFromPack ? 'Log Trip from Pack' : 'Log Trip'),
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onBackground),
        ),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(8.sp),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pack selector (if not pre-selected)
                    if (widget.pack == null) _buildPackSelector(colors),

                    // Trip name
                    _buildTextField(
                      label: 'Trip Name',
                      hint: 'e.g. Red Rock weekend',
                      requiredField: true,
                      controller: _nameController,
                    ),

                    // Activity type
                    _buildActivityField(colors),

                    // Date pickers
                    _buildDateSection(colors),

                    // Location
                    _buildTextField(
                      label: 'Location',
                      hint: 'e.g. Yosemite NP',
                      controller: _locationController,
                    ),

                    // Conditions
                    _buildTextField(
                      label: 'Conditions',
                      hint: 'e.g. Sunny, 75°F',
                      controller: _conditionsController,
                    ),

                    // Notes
                    _buildTextField(
                      label: 'Notes',
                      hint: 'Trip highlights, lessons learned...',
                      controller: _notesController,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 3,
                    ),

                    // Divider
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.sp),
                      child: Divider(color: colors.border),
                    ),

                    // Items section
                    _buildItemsSection(colors),

                    SizedBox(height: 100.sp),
                  ],
                ),
              ),
            ),
      bottomSheet: _isLoading
          ? null
          : SafeArea(
              left: false,
              right: false,
              bottom: true,
              child: Container(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.sp,
                  vertical: 8.sp,
                ),
                color: colors.background,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          minimumSize: Size.fromHeight(buttonHeight),
                          padding: EdgeInsets.symmetric(vertical: 0.sp),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              UiConstants.buttonRadius.sp,
                            ),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveTrip,
                        child: _isSaving
                            ? SizedBox(
                                height: 24.sp,
                                width: 24.sp,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.sp,
                                  color: colors.onPrimary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.check,
                                    color: colors.onPrimary,
                                    size: 25.sp,
                                  ),
                                  SizedBox(width: 8.sp),
                                  Text(
                                    _isEditing ? 'Update Trip' : 'Log Trip',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: colors.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPackSelector(AppColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('From Pack'),
        SizedBox(height: 6.sp),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8.sp),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(UiConstants.borderRadius),
            border: Border(bottom: BorderSide(color: colors.border, width: 1)),
          ),
          child: _availablePacks.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(12.sp),
                  child: Text(
                    'No packs yet. Log a from-scratch trip instead.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8.sp,
                  runSpacing: 8.sp,
                  children: [
                    // "From scratch" option
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        'From Scratch',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: _selectedPack == null
                              ? colors.onPrimary
                              : colors.onSurface,
                        ),
                      ),
                      selected: _selectedPack == null,
                      onSelected: (_) => _onPackSelected(null),
                      selectedColor: colors.primary,
                      backgroundColor: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          UiConstants.chipRadius.sp,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.sp,
                        vertical: 8.sp,
                      ),
                    ),
                    ..._availablePacks.map((pack) {
                      final selected = _selectedPack == pack;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.suitcase,
                              size: 14.sp,
                              color: selected
                                  ? colors.onPrimary
                                  : colors.onSurface,
                            ),
                            SizedBox(width: 6.sp),
                            Text(
                              pack.name,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        selected: selected,
                        onSelected: (_) => _onPackSelected(pack),
                        selectedColor: colors.primary,
                        backgroundColor: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            UiConstants.chipRadius.sp,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.sp,
                          vertical: 8.sp,
                        ),
                      );
                    }),
                  ],
                ),
        ),
        SizedBox(height: 12.sp),
      ],
    );
  }

  Widget _buildActivityField(AppColorPalette colors) {
    final activities = [
      'Backpacking',
      'Day Hike',
      'Climbing',
      'Camping',
      'Bikepacking',
      'Trail Run',
      'Ski Trip',
      'Other',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Activity Type'),
        SizedBox(height: 6.sp),
        Wrap(
          spacing: 8.sp,
          runSpacing: 8.sp,
          children: activities.map((a) {
            final selected = _activityType == a;
            return ChoiceChip(
              showCheckmark: false,
              label: Text(
                a,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
              selected: selected,
              onSelected: (s) {
                setState(() => _activityType = s ? a : null);
              },
              selectedColor: colors.primary,
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiConstants.chipRadius.sp),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
            );
          }).toList(),
        ),
        SizedBox(height: 12.sp),
      ],
    );
  }

  Widget _buildDateSection(AppColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Date'),
        SizedBox(height: 6.sp),
        Row(
          children: [
            // Start date
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isStart: true),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.sp,
                    vertical: 14.sp,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(
                      UiConstants.borderRadius,
                    ),
                    border: Border(bottom: BorderSide(color: colors.border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.calendarDays,
                        size: 16.sp,
                        color: colors.textSecondary,
                      ),
                      SizedBox(width: 8.sp),
                      Text(
                        _formatDate(_startDate),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isMultiDay) ...[
              SizedBox(width: 8.sp),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(isStart: false),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.sp,
                      vertical: 14.sp,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(
                        UiConstants.borderRadius,
                      ),
                      border: Border(bottom: BorderSide(color: colors.border, width: 1)),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.calendarDays,
                          size: 16.sp,
                          color: colors.textSecondary,
                        ),
                        SizedBox(width: 8.sp),
                        Text(
                          _endDate != null
                              ? _formatDate(_endDate!)
                              : 'End date',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(width: 8.sp),
            // Multi-day toggle
            ChoiceChip(
              label: FaIcon(
                FontAwesomeIcons.arrowsLeftRight,
                size: 14.sp,
                color: _isMultiDay ? colors.onPrimary : colors.onSurface,
              ),
              selected: _isMultiDay,
              onSelected: (s) {
                setState(() {
                  _isMultiDay = s;
                  if (!s) _endDate = null;
                });
              },
              selectedColor: colors.primary,
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiConstants.chipRadius.sp),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 8.sp),
              showCheckmark: false,
            ),
          ],
        ),
        SizedBox(height: 12.sp),
      ],
    );
  }

  Widget _buildItemsSection(AppColorPalette colors) {
    final selectedCount = _candidates.where((c) => c.isSelected).length;
    final totalWeight = _candidates
        .where((c) => c.isSelected)
        .fold<double>(0.0, (sum, c) => sum + c.weightGrams * c.quantity);
    final wp = formatWeightParts(totalWeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Items', style: AppTextStyles.titleMedium),
            SizedBox(width: 8.sp),
            Text(
              '($selectedCount selected \u2219 ${wp.value} ${wp.unit})',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addManualItem,
              icon: FaIcon(FontAwesomeIcons.plus, size: 14.sp),
              label: Text('Add Item', style: AppTextStyles.bodySmall),
            ),
          ],
        ),
        SizedBox(height: 4.sp),
        if (_candidates.isEmpty)
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Center(
              child: Text(
                _selectedPack != null
                    ? 'Loading pack items...'
                    : 'No items yet. Tap "Add Item" to add gear manually\nor select a pack above to pre-fill.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          )
        else
          ..._candidates.asMap().entries.map((entry) {
            final c = entry.value;
            final cwp = formatWeightParts(c.weightGrams);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 3.sp),
              child: Card.filled(
                color: c.isSelected ? colors.surface : colors.surfaceSunken,
                elevation: UiConstants.cardElevation,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    UiConstants.compactCardRadius.sp,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.sp,
                    vertical: 4.sp,
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      SizedBox(
                        width: 36.sp,
                        child: Checkbox(
                          value: c.isSelected,
                          onChanged: (v) {
                            setState(() => c.isSelected = v ?? false);
                          },
                          activeColor: colors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              c.itemName,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontSize: 13.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${cwp.value} ${cwp.unit} \u00d7 ${c.quantity}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity adjuster
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.minus,
                              size: 12.sp,
                              color: colors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                if (c.quantity > 1) c.quantity--;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 28.sp,
                              minHeight: 28.sp,
                            ),
                          ),
                          Text(
                            '${c.quantity}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.plus,
                              size: 12.sp,
                              color: colors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() => c.quantity++);
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 28.sp,
                              minHeight: 28.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildProGate(AppColorPalette colors) {
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _isEditing ? 'Edit Trip' : 'Log Trip',
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onBackground),
        ),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: UiConstants.spacingXL.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.crown, size: 48.sp, color: colors.tertiary),
              SizedBox(height: 20.sp),
              Text(
                'PRO Feature',
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
              SizedBox(height: 12.sp),
              Text(
                'Logging trips requires PRO mode. Enable it in your profile settings.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 24.sp),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                  icon: FaIcon(FontAwesomeIcons.crown, size: 16.sp, color: colors.onPrimary),
                  label: Text(
                    'Go to PRO Settings',
                    style: AppTextStyles.bodyMedium.copyWith(color: colors.onPrimary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
                    minimumSize: Size(0, 44.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        UiConstants.buttonRadius.sp,
                      ),
                    ),
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
// Bottom sheet to pick a gear item and quantity for manual addition
// ---------------------------------------------------------------------------

class _AddGearToTripSheet extends StatefulWidget {
  final List<GearItem> gearItems;
  final List<Category> categories;
  final void Function(GearItem gearItem, int quantity) onSelected;

  const _AddGearToTripSheet({
    required this.gearItems,
    required this.categories,
    required this.onSelected,
  });

  @override
  State<_AddGearToTripSheet> createState() => _AddGearToTripSheetState();
}

class _AddGearToTripSheetState extends State<_AddGearToTripSheet> {
  List<GearItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.gearItems;
  }

  void _filter(String q) {
    setState(() {
      _filtered = widget.gearItems.where((g) {
        final match =
            g.name.toLowerCase().contains(q.toLowerCase()) ||
            (g.brand?.toLowerCase() ?? '').contains(q.toLowerCase());
        return match;
      }).toList();
    });
  }

  String _iconKey(GearItem g) {
    final cat = widget.categories
        .where((c) => c.id == g.categoryId)
        .firstOrNull;
    return cat?.icon ?? 'box';
  }

  Color? _catColor(GearItem g) {
    final cat = widget.categories
        .where((c) => c.id == g.categoryId)
        .firstOrNull;
    return cat != null ? AppColors.parseHex(cat.color) : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final height = MediaQuery.of(context).size.height * 0.7;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.sp),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search gear...',
                prefixIcon: SizedBox(
                  width: 40.sp,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 16.sp,
                    ),
                  ),
                ),
                filled: true,
                fillColor: colors.surface,
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.sp,
                  vertical: 12.sp,
                ),
              ),
              onChanged: _filter,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No gear found',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final g = _filtered[index];
                      final iconKey = _iconKey(g);
                      final catColor = _catColor(g);
                      final wp = formatWeightParts(g.weightGrams);

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.sp,
                          vertical: 2.sp,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colors.surfaceRaised,
                            child: FaIcon(
                              IconRegistry.resolve(iconKey),
                              size: 18.sp,
                              color: catColor ?? colors.primary,
                            ),
                          ),
                          title: Text(g.name, style: AppTextStyles.bodyMedium),
                          subtitle: Text(
                            '${wp.value} ${wp.unit}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () => widget.onSelected(g, 1),
                            child: Text(
                              'Add',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
