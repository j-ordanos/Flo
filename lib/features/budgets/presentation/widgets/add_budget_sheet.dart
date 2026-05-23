import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/budget_period.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../expenses/presentation/widgets/num_pad.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';

/// Opens the add/edit budget modal. Pass [initial] to edit, or
/// [presetCategoryId] to pre-select a category.
Future<void> showAddBudgetSheet(
  BuildContext context, {
  Budget? initial,
  String? presetCategoryId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        AddBudgetSheet(initial: initial, presetCategoryId: presetCategoryId),
  );
}

class AddBudgetSheet extends ConsumerStatefulWidget {
  const AddBudgetSheet({this.initial, this.presetCategoryId, super.key});

  final Budget? initial;
  final String? presetCategoryId;

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  late String? _categoryId =
      widget.initial?.categoryId ?? widget.presetCategoryId;
  late int _limitCents = widget.initial?.limitCents ?? 0;
  late BudgetPeriod _period = widget.initial?.period ?? BudgetPeriod.monthly;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;
  bool get _canSave => _categoryId != null && _limitCents > 0 && !_saving;

  void _onKey(String key) {
    setState(() {
      if (key == 'back') {
        _limitCents = _limitCents ~/ 10;
      } else if (key != '.') {
        _limitCents = (_limitCents * 10 + int.parse(key)).clamp(0, 99999999);
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final repo = ref.read(budgetRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    final now = DateTime.now().toUtc();
    // Reuse the category's existing budget if there is one.
    final existing =
        widget.initial ?? await repo.findByCategory(userId, _categoryId!);
    final budget = existing != null
        ? existing.copyWith(
            limitCents: _limitCents,
            period: _period,
            updatedAt: now,
            syncStatus: SyncStatus.pending,
          )
        : Budget(
            id: const Uuid().v4(),
            userId: userId,
            categoryId: _categoryId!,
            limitCents: _limitCents,
            period: _period,
            createdAt: now,
            updatedAt: now,
          );
    await repo.upsertBudget(budget);
    await HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];

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
            Text(
              _isEdit ? 'Edit budget' : 'New budget',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              formatCents(_limitCents),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!_isEdit) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Category', style: theme.textTheme.labelLarge),
              ),
              const SizedBox(height: AppSpacing.sm),
              CategoryPicker(
                categories: categories,
                selectedId: _categoryId,
                onSelect: (id) => setState(() => _categoryId = id),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            SegmentedButton<BudgetPeriod>(
              segments: const [
                ButtonSegment(
                    value: BudgetPeriod.monthly, label: Text('Monthly')),
                ButtonSegment(
                    value: BudgetPeriod.weekly, label: Text('Weekly')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            NumPad(onKey: _onKey, showDecimal: false),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Create budget'),
            ),
          ],
        ),
      ),
    );
  }
}
