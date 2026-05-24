import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/utils/hex_color.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../domain/entities/category.dart';
import '../category_icons.dart';
import '../providers/category_providers.dart';
import 'category_avatar.dart';

/// Opens the add/edit category sheet. Resolves to the new/edited category id,
/// or null if dismissed.
Future<String?> showAddCategorySheet(BuildContext context, {Category? initial}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (_) => AddCategorySheet(initial: initial),
  );
}

class AddCategorySheet extends ConsumerStatefulWidget {
  const AddCategorySheet({this.initial, super.key});

  final Category? initial;

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late String _iconKey = widget.initial?.icon ?? 'other';
  late String _colorHex = widget.initial?.colorHex ?? kCategoryPalette.first;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(categoryRepositoryProvider);
    final now = DateTime.now().toUtc();
    String id;
    if (_isEdit) {
      id = widget.initial!.id;
      await repo.updateCategory(widget.initial!.copyWith(
        name: name,
        icon: _iconKey,
        colorHex: _colorHex,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      ));
    } else {
      id = const Uuid().v4();
      await repo.addCategory(Category(
        id: id,
        userId: ref.read(currentUserIdProvider),
        name: name,
        icon: _iconKey,
        colorHex: _colorHex,
        createdAt: now,
        updatedAt: now,
      ));
    }
    ref.read(syncControllerProvider.notifier).requestSync();
    await HapticFeedback.selectionClick();
    if (mounted) Navigator.of(context).pop(id);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: const Text(
            'Existing expenses keep their amount but lose this category.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      await ref
          .read(categoryRepositoryProvider)
          .deleteCategory(widget.initial!.id);
      ref.read(syncControllerProvider.notifier).requestSync();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hexToColor(_colorHex);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(_isEdit ? 'Edit category' : 'New category',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: CategoryAvatar(
                  iconKey: _iconKey, colorHex: _colorHex, size: 64),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('ICON',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.hintColor, letterSpacing: 0.4)),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              children: [
                for (final key in kSelectableIconKeys)
                  _IconTile(
                    iconKey: key,
                    color: color,
                    selected: key == _iconKey,
                    onTap: () => setState(() => _iconKey = key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('COLOR',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.hintColor, letterSpacing: 0.4)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final hex in kCategoryPalette)
                  _ColorDot(
                    hex: hex,
                    selected: hex == _colorHex,
                    onTap: () => setState(() => _colorHex = hex),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _name.text.trim().isEmpty || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Create category'),
            ),
            if (_isEdit && !widget.initial!.isDefault)
              TextButton.icon(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete category'),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.iconKey,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: selected
          ? color.withValues(alpha: dark ? 0.22 : 0.16)
          : (dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Icon(iconForCategoryKey(iconKey),
            size: 20, color: selected ? color : theme.hintColor),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(hex);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: color, width: 2)
              : null,
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
