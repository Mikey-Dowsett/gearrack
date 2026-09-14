import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../theme/ui_constants.dart';
import '../models/category.dart';
import '../models/condition.dart';
import '../models/gear_item.dart';
import '../database/gear_item_dao.dart';
import '../database/category_dao.dart';
import '../utils/icon_registry.dart';
import '../widgets/form_shell.dart';
import '../widgets/patch_chip.dart';
import '../widgets/section_header.dart';

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
  List<String> _allBrands = [];
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
    // Live hero title as the name is typed.
    _nameController.addListener(() => setState(() {}));
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final dao = await CategoryDao.create();
      final cats = await dao.getAll();
      List<String> brands = [];
      try {
        final gearDao = await GearItemDao.create();
        brands = await gearDao.getDistinctBrands();
      } catch (_) {
        // Brands are best-effort; ignore failures.
      }
      setState(() {
        _categories = cats;
        _allBrands = brands;
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
          label.toUpperCase(),
          style: AppTextStyles.specSmall.copyWith(color: colors.onBackground),
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

  Widget _buildBrandField(BuildContext context) {
    final colors = AppColors.of(context);

    InputDecoration decoration(String hint) => InputDecoration(
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
        );

    textFieldBuilder(
      TextEditingController c,
      FocusNode f,
      VoidCallback onSubmit,
    ) =>
        TextFormField(
          controller: c,
          focusNode: f,
          onFieldSubmitted: (_) => onSubmit(),
          style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface),
          decoration: decoration('Brand (optional)'),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Brand'),
        SizedBox(height: 6.sp),
        LayoutBuilder(
          builder: (context, constraints) => Autocomplete<String>(
            initialValue: TextEditingValue(text: _brandController.text),
            optionsBuilder: (value) {
              final q = value.text.trim().toLowerCase();
              // Exclude current item's own brand? No — keep it so editing
              // still suggests the current value.
              final matches = q.isEmpty
                  ? _allBrands
                  : _allBrands
                      .where((b) => b.toLowerCase().contains(q))
                      .toList();
              // If typed text is new, offer it as first "create" option
              // by just letting free text through; Autocomplete already
              // keeps raw text on submit.
              return matches;
            },
            onSelected: (selection) {
              _brandController.text = selection;
            },
            fieldViewBuilder:
                (context, fieldController, fieldFocus, onFieldSubmitted) {
              // Keep controllers in sync both ways.
              if (fieldController.text != _brandController.text &&
                  fieldFocus.hasFocus == false &&
                  _brandController.text.isNotEmpty) {
                fieldController.text = _brandController.text;
              }
              fieldController.addListener(() {
                if (_brandController.text != fieldController.text) {
                  _brandController.text = fieldController.text;
                }
              });
              return textFieldBuilder(
                  fieldController, fieldFocus, onFieldSubmitted);
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius:
                      BorderRadius.circular(UiConstants.borderRadius),
                  color: colors.surface,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: 220.sp,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.all(4.sp),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          borderRadius: BorderRadius.circular(
                              UiConstants.borderRadius),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.sp,
                              vertical: 10.sp,
                            ),
                            child: Text(
                              option,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
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
                borderRadius: BorderRadius.circular(UiConstants.borderRadius),
                border: Border(
                  bottom: BorderSide(
                    color: hasError ? colors.error : colors.border,
                    width: UiConstants.borderWidth,
                  ),
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
                        return PatchChip(
                          label: c.name,
                          iconKey: c.icon,
                          iconColor: AppColors.parseHex(c.color),
                          selected: selected,
                          onSelected: (s) {
                            field.didChange(s ? c : null);
                            setState(() {
                              _selectedCategory = s ? c : null;
                            });
                          },
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
                borderRadius: BorderRadius.circular(UiConstants.borderRadius),
                border: Border(
                  bottom: BorderSide(
                    color: hasError ? colors.error : colors.border,
                    width: 1,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8.sp,
                runSpacing: 8.sp,
                children: Condition.values.map((c) {
                  final selected = field.value == c;
                  final statusColor = c == Condition.Good
                      ? AppColors.statusGood
                      : c == Condition.Worn
                      ? AppColors.statusWorn
                      : AppColors.statusRetired;
                  return PatchChip(
                    label: _prettyEnumName(c),
                    iconData: _conditionIcons[c],
                    iconColor: statusColor,
                    selected: selected,
                    onSelected: (s) {
                      field.didChange(s ? c : null);
                      setState(() {
                        _selectedCondition = s ? c : null;
                      });
                    },
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
            borderRadius: BorderRadius.circular(UiConstants.borderRadius),
            border: Border(bottom: BorderSide(color: colors.border, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Backpack',
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
      label: 'Capacity(L)',
      hint: '45L',
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
    final isEditing = widget.gear != null;
    final heroIcon = _selectedCategory != null
        ? IconRegistry.resolve(_selectedCategory!.icon)
        : FontAwesomeIcons.box;
    final heroLabel =
        '${isEditing ? 'Editing' : 'New gear'} · ${_selectedCategory?.name ?? 'no category'}';

    return FormShell(
      title: isEditing ? 'Edit Gear' : 'Add Gear',
      saveLabel: isEditing ? 'Update Gear' : 'Save Gear',
      onSave: _saveGear,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormHero(
              icon: heroIcon,
              label: heroLabel,
              title: _nameController.text.isEmpty
                  ? 'Untitled piece'
                  : _nameController.text,
              spec: _selectedCondition != null
                  ? _prettyEnumName(_selectedCondition!).toUpperCase()
                  : null,
            ),
            SizedBox(height: 12.sp),
            const SectionHeader(title: 'Identity'),
            SizedBox(height: 8.sp),
            _buildLabeledField(
                context,
                label: 'Name',
                hint: 'Gear Name',
                requiredField: true,
                controller: _nameController,
              ),
              _buildBrandField(context),
              _buildCategoryField(context, true),
              SizedBox(height: 4.sp),
              const SectionHeader(title: 'Specifications'),
              SizedBox(height: 8.sp),
              _rowOfTwoFields(
                context,
                _buildLabeledField(
                  context,
                  label: 'Weight(g)',
                  hint: '1500g',
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
              SizedBox(height: 4.sp),
              const SectionHeader(title: 'Condition & Notes'),
              SizedBox(height: 8.sp),
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
    );
  }
}
