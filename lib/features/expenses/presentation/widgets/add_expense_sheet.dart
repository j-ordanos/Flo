import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/add_category_sheet.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import 'num_pad.dart';

/// Opens the add/edit expense modal bottom sheet. Pass [initial] to edit.
Future<void> showAddExpenseSheet(BuildContext context, {Expense? initial}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (_) => AddExpenseSheet(initial: initial),
  );
}

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({this.initial, super.key});

  final Expense? initial;

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  late String _amount = widget.initial == null
      ? '0'
      : (widget.initial!.amountCents / 100).toStringAsFixed(2);
  late String? _categoryId = widget.initial?.categoryId;
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  late final TextEditingController _note =
      TextEditingController(text: widget.initial?.note ?? '');
  bool _saving = false;

  bool get _isEdit => widget.initial != null;
  int get _amountCents => ((double.tryParse(_amount) ?? 0) * 100).round();
  bool get _canSave => _amountCents > 0 && _categoryId != null && !_saving;

  void _onKey(String key) {
    setState(() {
      if (key == 'back') {
        _amount = _amount.length <= 1 ? '0' : _amount.substring(0, _amount.length - 1);
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount = '$_amount.';
      } else {
        // Limit to two decimal places.
        final dot = _amount.indexOf('.');
        if (dot != -1 && _amount.length - dot > 2) return;
        _amount = _amount == '0' ? key : _amount + key;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final repo = ref.read(expenseRepositoryProvider);
    final now = DateTime.now().toUtc();
    final note = _note.text.trim();
    final noteOrNull = note.isEmpty ? null : note;

    if (_isEdit) {
      await repo.updateExpense(widget.initial!.copyWith(
        amountCents: _amountCents,
        categoryId: _categoryId!,
        note: noteOrNull,
        date: _date,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      ));
    } else {
      await repo.addExpense(Expense(
        id: const Uuid().v4(),
        userId: ref.read(currentUserIdProvider),
        amountCents: _amountCents,
        categoryId: _categoryId!,
        note: noteOrNull,
        date: _date,
        createdAt: now,
        updatedAt: now,
      ));
    }
    ref.read(syncControllerProvider.notifier).requestSync();
    if (!_isEdit) await _maybeBudgetAlert();
    await HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  /// Fires a budget-overage notification if this expense pushes the category
  /// past its limit (and alerts are enabled).
  Future<void> _maybeBudgetAlert() async {
    if (!(ref.read(pushEnabledProvider) && ref.read(budgetAlertsProvider))) {
      return;
    }
    final categoryId = _categoryId;
    if (categoryId == null) return;
    final budget = ref.read(budgetsByCategoryProvider)[categoryId];
    if (budget == null) return;
    final before = ref.read(categoryTotalsProvider).value?[categoryId] ?? 0;
    final after = before + _amountCents;
    if (before <= budget.limitCents && after > budget.limitCents) {
      final category = ref.read(categoriesByIdProvider)[categoryId];
      await ref.read(notificationServiceProvider).showBudgetExceeded(
            category: category?.name ?? 'budget',
            spent: formatCents(after),
            limit: formatCents(budget.limitCents),
          );
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final isZero = _amountCents == 0;

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
              child: Text(_isEdit ? 'Edit expense' : 'New expense',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('AMOUNT',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.hintColor, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 2),
                  child: Text(Money.symbol,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: theme.hintColor)),
                ),
                Text(
                  _amount,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: isZero ? theme.hintColor : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('CATEGORY',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.hintColor, letterSpacing: 0.4)),
            const SizedBox(height: AppSpacing.sm),
            _CategoryGrid(
              categories: categories,
              selectedId: _categoryId,
              onSelect: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _note,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Add a note',
                      prefixIcon: Icon(Icons.edit_outlined, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DateButton(date: _date, onTap: _pickDate),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            NumPad(onKey: _onKey),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Save expense'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    return Material(
      color: dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      borderRadius: BorderRadius.circular(AppRadii.button),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: theme.hintColor),
              const SizedBox(width: AppSpacing.sm),
              Text(isToday ? 'Today' : DateFormat.MMMd().format(date),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 72,
        child: Center(child: Text('No categories yet')),
      );
    }
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.82,
      children: [
        for (final c in categories)
          _CategoryTile(
            category: c,
            selected: c.id == selectedId,
            onTap: () => onSelect(c.id),
          ),
        _AddCategoryTile(onCreated: onSelect),
      ],
    );
  }
}

class _AddCategoryTile extends StatelessWidget {
  const _AddCategoryTile({required this.onCreated});

  final ValueChanged<String> onCreated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () async {
          final id = await showAddCategorySheet(context);
          if (id != null) onCreated(id);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Icon(Icons.add, color: theme.hintColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text('New',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryAvatar(
                  iconKey: category.icon, colorHex: category.colorHex, size: 36),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
