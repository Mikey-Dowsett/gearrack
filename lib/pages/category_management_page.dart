import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:gearrack/database/category_dao.dart';
import 'package:gearrack/database/gear_item_dao.dart';
import 'package:gearrack/models/category.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/theme/ui_constants.dart';
import 'package:gearrack/utils/icon_registry.dart';
import 'package:uuid/uuid.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final dao = await CategoryDao.create();
      final cats = await dao.getAll();
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(Category cat) async {
    if (cat.isDefault) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${cat.name}"?'),
        content: Text('This category will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dao = await CategoryDao.create();
      final gearDao = await GearItemDao.create();
      final count = await gearDao.countByCategory(cat.id);

      if (count > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$count gear items use this category. Remove them first.',
              ),
            ),
          );
        }
        return;
      }

      await dao.delete(cat.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _showCategoryDialog({Category? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp)),
      ),
      builder: (_) => _CategoryDialog(existing: existing),
    );

    if (result == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          'Categories',
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onBackground),
        ),
        centerTitle: false,
      actions: [
        IconButton(
          icon: PhosphorIcon(
            PhosphorIconsFill.plus,
            size: 22.5.sp,
            color: colors.primary,
          ),
          onPressed: () => _showCategoryDialog(),
        ),
      ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Text(
                'No categories yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: UiConstants.spacingL.sp,
                vertical: UiConstants.spacingM.sp,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _buildCategoryTile(colors, cat);
              },
            ),
    );
  }

  Widget _buildCategoryTile(AppColorPalette colors, Category cat) {
    final catColor = AppColors.parseHex(cat.color);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: Card.filled(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        elevation: UiConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
          side: BorderSide(color: colors.border, width: UiConstants.borderWidth),
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: UiConstants.spacingM.sp,
                  vertical: 2.sp,
                ),
                leading: Container(
                  width: 40.sp,
                  height: 40.sp,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.sp),
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      IconRegistry.resolve(cat.icon),
                      size: 18.sp,
                      color: catColor,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      cat.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    if (cat.isDefault) ...[
                      SizedBox(width: 6.sp),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.sp,
                          vertical: 2.sp,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.sp),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colors.primary,
                            fontSize: 8.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!cat.isDefault)
                      IconButton(
                        icon: PhosphorIcon(
                          PhosphorIconsFill.trash,
                          size: 14.sp,
                          color: colors.textSecondary,
                        ),
                        onPressed: () => _deleteCategory(cat),
                      ),
                    PhosphorIcon(
                      PhosphorIconsFill.pencilSimple,
                      size: 14.sp,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
                onTap: () => _showCategoryDialog(existing: cat),
              ),
            ],
          ),
        ),
      );
  }
}

// ---------------------------------------------------------------------------
// Category dialog (create / edit) with icon and color pickers
// ---------------------------------------------------------------------------
class _CategoryDialog extends StatefulWidget {
  final Category? existing;
  const _CategoryDialog({this.existing});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameCtrl;
  late final GlobalKey<FormState> _formKey;
  late String _selectedIcon;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _formKey = GlobalKey<FormState>();
    _selectedIcon = widget.existing?.icon ?? 'box-open';
    _selectedColor = widget.existing?.color ?? '#80696B';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDefaultEditing = widget.existing?.isDefault ?? false;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(UiConstants.spacingL.sp),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.sp,
                  height: 4.sp,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2.sp),
                  ),
                ),
              ),
              SizedBox(height: 16.sp),
              Text(
                widget.existing == null ? 'New Category' : 'Edit Category',
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              SizedBox(height: 16.sp),

              // Preview
              Center(
                child: Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    color: AppColors.parseHex(
                      _selectedColor,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.sp),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        IconRegistry.resolve(_selectedIcon),
                        size: 20.sp,
                        color: AppColors.parseHex(_selectedColor),
                      ),
                      SizedBox(width: 8.sp),
                      Text(
                        _nameCtrl.text.isEmpty ? 'Category' : _nameCtrl.text,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.parseHex(_selectedColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.sp),

              // Name (locked for default categories — only color is editable)
              TextFormField(
                controller: _nameCtrl,
                enabled: !isDefaultEditing,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Camp Kitchen',
                  helperText: isDefaultEditing
                      ? 'Default categories cannot be renamed.'
                      : null,
                ),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 16.sp),

              // Icon picker (locked for default categories)
              if (isDefaultEditing) ...[
                Text(
                  'Icon',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.sp),
                Opacity(
                  opacity: 0.5,
                  child: IgnorePointer(
                    ignoring: true,
                    child: _IconPicker(
                      selectedIcon: _selectedIcon,
                      onSelect: (_) {},
                    ),
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  'Default categories keep their icon.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ] else ...[
                Text(
                  'Icon',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.sp),
                _IconPicker(
                  selectedIcon: _selectedIcon,
                  onSelect: (icon) => setState(() => _selectedIcon = icon),
                ),
              ],
              SizedBox(height: 16.sp),

              // Color picker
              Text(
                'Color',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 8.sp),
              _ColorPicker(
                selectedColor: _selectedColor,
                onSelect: (color) => setState(() => _selectedColor = color),
              ),
              SizedBox(height: 24.sp),

              // Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() != true) return;
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final dao = await CategoryDao.create();
                    if (widget.existing != null) {
                      final isDefault = widget.existing!.isDefault;
                      await dao.update(
                        widget.existing!.copyWith(
                          // Default categories: only color is editable.
                          name: isDefault
                              ? widget.existing!.name
                              : name,
                          icon: isDefault
                              ? widget.existing!.icon
                              : _selectedIcon,
                          color: _selectedColor,
                        ),
                      );
                    } else {
                      await dao.insert(
                        Category(
                          id: const Uuid().v4(),
                          name: name,
                          icon: _selectedIcon,
                          color: _selectedColor,
                        ),
                      );
                    }
                    if (mounted) Navigator.pop(context, true);
                  },
                  child: Text(
                    widget.existing == null ? 'Add Category' : 'Save',
                  ),
                ),
              ),
              SizedBox(height: 8.sp),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

// ---------------------------------------------------------------------------
// Searchable icon picker
// ---------------------------------------------------------------------------
class _IconPicker extends StatefulWidget {
  final String selectedIcon;
  final ValueChanged<String> onSelect;
  const _IconPicker({required this.selectedIcon, required this.onSelect});

  @override
  State<_IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<_IconPicker> {
  String _query = '';
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final results = IconRegistry.search(_query);

    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search icons...',
            prefixIcon: SizedBox(
              width: 40.sp,
              child: Center(
                child: PhosphorIcon(
                  PhosphorIconsFill.magnifyingGlass,
                  size: 14.sp,
                  color: colors.textSecondary,
                ),
              ),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8.sp),
          ),
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
          onChanged: (v) => setState(() => _query = v),
        ),
        SizedBox(height: 8.sp),
        SizedBox(
          height: 160.sp,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6.sp,
              runSpacing: 6.sp,
              children: results.map((entry) {
                final isSelected = entry.key == widget.selectedIcon;
                return GestureDetector(
                  onTap: () => widget.onSelect(entry.key),
                  child: Container(
                    width: 44.sp,
                    height: 44.sp,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.2)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(8.sp),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        entry.icon,
                        size: 20.sp,
                        color: isSelected ? colors.primary : colors.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Color swatch picker
// ---------------------------------------------------------------------------
class _ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onSelect;

  const _ColorPicker({required this.selectedColor, required this.onSelect});

  // Note: #BE6B50 (orange) is UI-only and intentionally excluded here.
  static const _swatches = [
    '#3D515B',
    '#719193',
    '#9DB3AC',
    '#954F4D',
    '#EFB571',
    '#D0A654',
    '#8F853C',
    '#5D523C',
    '#403639',
    '#5C4850',
    '#A68D8C',
    '#80696B',
    '#F7E4CD',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.sp,
      runSpacing: 8.sp,
      children: _swatches.map((hex) {
        final color = AppColors.parseHex(hex);
        final isSelected = hex == selectedColor;
        return GestureDetector(
          onTap: () => onSelect(hex),
          child: Container(
            width: 36.sp,
            height: 36.sp,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? PhosphorIcon(
                    PhosphorIconsFill.checkFat,
                    size: 18.sp,
                    color: Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
