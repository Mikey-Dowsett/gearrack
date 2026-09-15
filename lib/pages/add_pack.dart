import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../theme/ui_constants.dart';
import '../models/pack.dart';
import '../models/gear_item.dart';
import '../database/pack_dao.dart';
import '../database/gear_item_dao.dart';
import '../widgets/form_shell.dart';
import '../widgets/section_header.dart';

class AddPackPage extends StatefulWidget {
  final Pack? pack;

  const AddPackPage({super.key, this.pack});

  bool get isEditing => pack != null;

  @override
  State<AddPackPage> createState() => _AddPackPageState();
}

class _AddPackPageState extends State<AddPackPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  List<GearItem> _availableBags = [];
  GearItem? _selectedBag;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _loadBags();
  }

  Future<void> _loadBags() async {
    try {
      final dao = await GearItemDao.create();
      final bags = await dao.getPacks();
      setState(() {
        _availableBags = bags;
      });
      final pack = widget.pack;
      if (pack != null && pack.bagId != null) {
        _selectedBag = bags.where((b) => b.id == pack.bagId).firstOrNull;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load bags: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _fieldLabel(String label, {bool required = false}) {
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

  Widget _buildLabeledField({
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

  Widget _buildBagSelector() {
    final colors = AppColors.of(context);

    return FormField<GearItem>(
      initialValue: _selectedBag,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Choose a Bag'),
            SizedBox(height: 6.sp),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(UiConstants.borderRadius),
                border: Border(bottom: BorderSide(color: colors.border, width: UiConstants.borderWidth)),
              ),
              child: _availableBags.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(12.sp),
                      child: Text(
                        'No bags found. Add a bag in your gear first.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8.sp,
                      runSpacing: 8.sp,
                      children: _availableBags.map((bag) {
                        final selected = field.value == bag;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PhosphorIcon(
                                PhosphorIconsFill.backpack,
                                size: 14.sp,
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurface,
                              ),
                              SizedBox(width: 6.sp),
                              Text(
                                bag.name,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: selected
                                      ? colors.onPrimary
                                      : colors.onSurface,
                                ),
                              ),
                              if (bag.capacityLiters != null) ...[
                                SizedBox(width: 4.sp),
                                Text(
                                  '(${bag.capacityLiters!.toStringAsFixed(0)}L)',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: selected
                                        ? colors.onPrimary.withValues(
                                            alpha: 0.8,
                                          )
                                        : colors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: selected,
                          onSelected: (s) {
                            field.didChange(s ? bag : null);
                            setState(() => _selectedBag = s ? bag : null);
                          },
                          backgroundColor: colors.surface,
                          selectedColor: colors.primary,
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
                      }).toList(),
                    ),
            ),
            SizedBox(height: 12.sp),
          ],
        );
      },
    );
  }

  Future<void> _savePack() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final isEditing = widget.pack != null;
    final pack = Pack(
      id: isEditing ? widget.pack!.id : _uuid.v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      bagId: _selectedBag?.id,
      createdAt: isEditing ? widget.pack!.createdAt : now,
    );

    try {
      final dao = await PackDao.create();
      if (isEditing) {
        await dao.update(pack);
      } else {
        await dao.insert(pack);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Updated Pack!' : 'Saved Pack!')),
        );
        Navigator.of(context).pop(true);
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
    final isEditing = widget.pack != null;
    return FormShell(
      title: isEditing ? 'Edit Pack' : 'New Pack',
      saveLabel: isEditing ? 'Update Pack' : 'Save Pack',
      onSave: _savePack,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormHero(
              icon: PhosphorIconsFill.backpack,
              label: isEditing ? 'Editing pack' : 'New pack',
              title: _nameController.text.isEmpty
                  ? 'Untitled pack'
                  : _nameController.text,
              spec: _selectedBag?.name.toUpperCase(),
            ),
            SizedBox(height: 12.sp),
            const SectionHeader(title: 'Pack'),
            SizedBox(height: 8.sp),
            _buildLabeledField(
              label: 'Pack Name',
              hint: 'e.g. Summer alpine',
              requiredField: true,
              controller: _nameController,
            ),
            _buildLabeledField(
              label: 'Description',
              hint: 'Route, dates, notes…',
              requiredField: false,
              keyboardType: TextInputType.multiline,
              controller: _descriptionController,
              minLines: 1,
              maxLines: 3,
            ),
            _buildBagSelector(),
            SizedBox(height: 100.sp),
          ],
        ),
      ),
    );
  }
}
