import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../models/category.dart';
import '../models/condition.dart';
import '../models/gear_item.dart';
import '../database/gear_item_dao.dart';
import '../database/category_dao.dart';
import '../utils/icon_registry.dart';

class AddGearPage extends StatefulWidget {
  final GearItem? gear;

  const AddGearPage({Key? key, this.gear}) : super(key: key);

  bool get isEditing => gear != null;

  @override
  State<AddGearPage> createState() => _AddGearPageState();
}

class _AddGearPageState extends State<AddGearPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  Category? _selectedCategory;
  Condition? _selectedCondition;
  List<Category> _categories = [];
  bool _isPack = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _purchaseYearController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final dao = await CategoryDao.create();
      final cats = await dao.getAll();
      setState(() {
        _categories = cats;
      });
      // After categories are loaded, populate fields if editing.
      final gear = widget.gear;
      if (gear != null) {
        _populateFields(gear);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  void _populateFields(GearItem gear) {
    _nameController.text = gear.name;
    _brandController.text = gear.brand ?? '';
    _weightController.text = gear.weightGrams.toString();
    _priceController.text = gear.price?.toString() ?? '';
    _purchaseYearController.text = gear.purchaseYear?.toString() ?? '';
    _quantityController.text = gear.quantity.toString();
    _notesController.text = gear.notes ?? '';
    _capacityController.text = gear.capacityLiters?.toString() ?? '';

    setState(() {
      _isPack = gear.isPack;
      _selectedCategory = _categories.firstWhere(
        (c) => c.id == gear.categoryId,
        orElse: () => _categories.first,
      );

      _selectedCondition = Condition.values.firstWhere(
        (c) => c.name == gear.condition,
        orElse: () => Condition.Good,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _purchaseYearController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  String _prettyEnumName(Enum e) {
    final name = e.name;
    return name.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
  }

  final Map<Condition, FaIconData> _conditionIcons = {
    Condition.Good: FontAwesomeIcons.check,
    Condition.Worn: FontAwesomeIcons.rotate,
    Condition.Retired: FontAwesomeIcons.trash,
  };

  Widget _fieldLabel(
    BuildContext context,
    String label, {
    bool required = false,
  }) {
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

  Widget _buildLabeledField(
    BuildContext context, {
    required String label,
    required String hint,
    bool requiredField = false,
    TextInputType? keyboardType,
    TextEditingController? controller,
    int? minLines,
    int? maxLines,
    bool expands = false,
  }) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, label, required: requiredField),
        SizedBox(height: 6.sp),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          expands: expands,
          style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: colors.border, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: colors.border, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: colors.primary, width: 2.0),
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

  Widget _rowOfTwoFields(BuildContext context, Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: 8.sp),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context, bool required) {
    final colors = AppColors.of(context);

    return FormField<Category>(
      key: ValueKey('category_${_selectedCategory?.id}'),
      initialValue: _selectedCategory,
      validator: (value) => required && value == null ? 'Required' : null,
      builder: (field) {
        final hasError = field.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(context, 'Category', required: required),
            SizedBox(height: 6.sp),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: hasError ? colors.error : colors.border,
                  width: 2.0,
                ),
              ),
              child: _categories.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(12.sp),
                      child: Text(
                        'Loading categories...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8.sp,
                      runSpacing: 8.sp,
                      children: _categories.map((c) {
                        final selected = field.value == c;
                        final icon = IconRegistry.resolve(c.icon);
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.name,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: selected
                                      ? colors.onPrimary
                                      : colors.onSurface,
                                ),
                              ),
                              SizedBox(width: 6.sp),
                              FaIcon(
                                icon,
                                size: 14.sp,
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurface,
                              ),
                            ],
                          ),
                          selected: selected,
                          onSelected: (s) {
                            field.didChange(s ? c : null);
                            setState(() {
                              _selectedCategory = s ? c : null;
                            });
                          },
                          backgroundColor: colors.surface,
                          selectedColor: colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: selected ? colors.primary : colors.border,
                              width: 2.0,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.sp,
                            vertical: 8.sp,
                          ),
                        );
                      }).toList(),
                    ),
            ),
            SizedBox(height: 12.sp),
          ],
        );
      },
    );
  }

  Widget _buildConditionField(BuildContext context, bool required) {
    final colors = AppColors.of(context);

    return FormField<Condition>(
      key: ValueKey('condition_${_selectedCondition?.name}'),
      initialValue: _selectedCondition,
      validator: (value) => required && value == null ? 'Required' : null,
      builder: (field) {
        final hasError = field.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(context, 'Condition', required: required),
            SizedBox(height: 6.sp),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: hasError ? colors.error : colors.border,
                  width: 2.0,
                ),
              ),
              child: Wrap(
                spacing: 8.sp,
                runSpacing: 8.sp,
                children: Condition.values.map((c) {
                  final selected = field.value == c;
                  final icon = _conditionIcons[c] ?? FontAwesomeIcons.question;
                  return ChoiceChip(
                    showCheckmark: false,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _prettyEnumName(c),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: selected
                                ? colors.onPrimary
                                : colors.onSurface,
                          ),
                        ),
                        SizedBox(width: 6.sp),
                        FaIcon(
                          icon,
                          size: 14.sp,
                          color: selected ? colors.onPrimary : colors.onSurface,
                        ),
                      ],
                    ),
                    selected: selected,
                    onSelected: (s) {
                      field.didChange(s ? c : null);
                      setState(() {
                        _selectedCondition = s ? c : null;
                      });
                    },
                    backgroundColor: colors.surface,
                    selectedColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected ? colors.primary : colors.border,
                        width: 2.0,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.sp,
                      vertical: 8.sp,
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 12.sp),
          ],
        );
      },
    );
  }

  Widget _buildIsPackToggle(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Backpack'),
        SizedBox(height: 6.sp),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: colors.border, width: 2.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'This is a backpack',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.onBackground,
                  ),
                ),
              ),
              SizedBox(width: 8.sp),
              Switch(
                value: _isPack,
                onChanged: (val) => setState(() => _isPack = val),
                activeColor: colors.primary,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.sp),
      ],
    );
  }

  Widget _buildCapacityField(BuildContext context) {
    return _buildLabeledField(
      context,
      label: 'Capacity',
      hint: 'Capacity in liters (e.g. 45)',
      requiredField: false,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      controller: _capacityController,
    );
  }

  Future<void> _saveGear() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null || _selectedCondition == null) return;

    final now = DateTime.now();
    final isEditing = widget.gear != null;

    final double? capacity = _isPack
        ? double.tryParse(_capacityController.text.trim())
        : null;

    final gearItem = GearItem(
      id: isEditing ? widget.gear!.id : _uuid.v4(),
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      categoryId: _selectedCategory!.id,
      isPack: _isPack,
      capacityLiters: capacity,
      weightGrams: double.tryParse(_weightController.text.trim()) ?? 0,
      price: double.tryParse(_priceController.text.trim()),
      purchaseYear: int.tryParse(_purchaseYearController.text.trim()),
      quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
      condition: _selectedCondition!.name,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      imageUrl: isEditing ? widget.gear!.imageUrl : null,
      createdAt: isEditing ? widget.gear!.createdAt : now,
      updatedAt: now,
    );

    try {
      final dao = await GearItemDao.create();
      if (isEditing) {
        await dao.update(gearItem);
      } else {
        await dao.insert(gearItem);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Updated Gear!' : 'Saved Gear!')),
        );
        Navigator.of(context).pop(gearItem);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // Shared fixed height for bottom-sheet buttons so they always match
    final double buttonHeight = 56.sp;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          widget.gear != null ? 'Edit Gear' : 'Add Gear',
          style: AppTextStyles.bodyMedium,
        ),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8.sp),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabeledField(
                context,
                label: 'Name',
                hint: 'Gear Name',
                requiredField: true,
                controller: _nameController,
              ),
              _buildLabeledField(
                context,
                label: 'Brand',
                hint: 'Brand (optional)',
                requiredField: false,
                controller: _brandController,
              ),
              _buildCategoryField(context, true),
              _rowOfTwoFields(
                context,
                _buildLabeledField(
                  context,
                  label: 'Weight',
                  hint: 'Weight in grams (e.g. 1500)',
                  requiredField: true,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: _weightController,
                ),
                _buildLabeledField(
                  context,
                  label: 'Price',
                  hint: '\$ 0',
                  requiredField: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: _priceController,
                ),
              ),
              _rowOfTwoFields(
                context,

                _buildIsPackToggle(context),
                _buildCapacityField(context),
              ),
              _rowOfTwoFields(
                context,
                _buildLabeledField(
                  context,
                  label: 'Purchase Year',
                  hint: '2026',
                  requiredField: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: false),
                  controller: _purchaseYearController,
                ),
                _buildLabeledField(
                  context,
                  label: 'Quantity',
                  hint: '1',
                  requiredField: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: false),
                  controller: _quantityController,
                ),
              ),
              _buildConditionField(context, true),
              _buildLabeledField(
                context,
                label: 'Notes',
                hint: 'Storage, care, quirks, etc...',
                requiredField: false,
                keyboardType: TextInputType.multiline,
                controller: _notesController,
                minLines: 1,
                maxLines: null,
              ),
              SizedBox(
                height: 100.sp,
              ), //Needs to be at the bottom so the bottom sheet doesn't cover it
            ],
          ),
        ),
      ),
      bottomSheet: SafeArea(
        left: false,
        right: false,
        bottom: true,
        child: Container(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 8.sp),
          color: colors.background,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border, width: 2.0),
                    backgroundColor: colors.surface,
                    foregroundColor: colors.onSurface,
                    minimumSize: Size.fromHeight(buttonHeight),
                    padding: EdgeInsets.symmetric(vertical: 0.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                  ),
                  onPressed: () {
                    // Cancel / close page
                    Navigator.of(context).pop();
                  },
                  child: FaIcon(
                    size: 25.sp,
                    FontAwesomeIcons.xmark,
                    color: colors.onSurface,
                  ),
                ),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                flex: 5,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    minimumSize: Size.fromHeight(buttonHeight),
                    padding: EdgeInsets.symmetric(vertical: 0.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.sp),
                    ),
                  ),
                  onPressed: _saveGear,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.check,
                        color: colors.onPrimary,
                        size: 25.sp,
                      ),
                      SizedBox(width: 8.sp),
                      Text(
                        widget.gear != null ? 'Update Gear' : 'Save Gear',
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
}
