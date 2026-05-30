import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/category_kind.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/enums/transaction_type.dart';
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
  late TransactionType _type = widget.initial?.type ?? TransactionType.expense;
  late String? _categoryId = widget.initial?.categoryId;
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  late final TextEditingController _note =
      TextEditingController(text: widget.initial?.note ?? '');
  bool _saving = false;

  bool get _isEdit => widget.initial != null;
  bool get _isIncome => _type == TransactionType.income;
  String get _typeWord => _isIncome ? 'income' : 'expense';
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
        type: _type,
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
        type: _type,
        categoryId: _categoryId!,
        note: noteOrNull,
        date: _date,
        createdAt: now,
        updatedAt: now,
      ));
    }
    ref.read(syncControllerProvider.notifier).requestSync();
    if (!_isIncome) await _maybeBudgetAlert();
    await HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  /// Fires a budget-overage notification if this save pushes the category past
  /// its limit (and alerts are enabled). Works for both new and edited expenses.
  Future<void> _maybeBudgetAlert() async {
    if (!(ref.read(pushEnabledProvider) && ref.read(budgetAlertsProvider))) {
      return;
    }
    final categoryId = _categoryId;
    if (categoryId == null) return;
    final budget = ref.read(budgetsByCategoryProvider)[categoryId];
    if (budget == null) return;

    // Fresh post-write total for this category this month.
    final totals = await ref.read(expenseRepositoryProvider).watchTotalsByCategory(
          ref.read(currentUserIdProvider),
          ref.read(currentMonthProvider),
        ).first;
    final after = totals[categoryId] ?? 0;

    // How much this save added to the category total.
    final sameCategory = _isEdit &&
        widget.initial!.categoryId == categoryId &&
        widget.initial!.type == TransactionType.expense;
    final delta =
        sameCategory ? _amountCents - widget.initial!.amountCents : _amountCents;
    final before = after - delta;

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
    final wantKind =
        _isIncome ? CategoryKind.income : CategoryKind.expense;
    final categories = (ref.watch(categoriesProvider).value ?? const <Category>[])
        .where((c) => c.kind == wantKind)
        .toList();
    final isZero = _amountCents == 0;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pinned top: title, type, category strip + note/date. Set these once.
          Center(
            child: Text(_isEdit ? 'Edit $_typeWord' : 'New $_typeWord',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: AppSpacing.md),
          _TypeToggle(
            value: _type,
            onChanged: (t) => setState(() {
              _type = t;
              // Selected category belongs to the other kind now — clear it.
              _categoryId = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          _CategoryStrip(
            categories: categories,
            selectedId: _categoryId,
            income: _isIncome,
            onSelect: (id) => setState(() => _categoryId = id),
          ),
          const SizedBox(height: AppSpacing.sm),
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
          // Amount sits directly above the keypad so it's always in view while
          // typing — no scrolling back and forth.
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 2),
                  child: Text(_isIncome ? '+${Money.symbol}' : Money.symbol,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: _isIncome && !isZero
                              ? AppColors.success
                              : theme.hintColor)),
                ),
                Text(
                  _amount,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: isZero
                        ? theme.hintColor
                        : _isIncome
                            ? AppColors.success
                            : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          NumPad(onKey: _onKey),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? 'Save changes' : 'Save $_typeWord'),
          ),
        ],
        ),
      ),
    );
  }
}

/// Segmented Expense / Income switch.
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: Row(
        children: [
          _segment(context, TransactionType.expense, 'Expense',
              Icons.remove_circle_outline, theme.colorScheme.primary),
          _segment(context, TransactionType.income, 'Income',
              Icons.add_circle_outline, AppColors.success),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, TransactionType type, String label,
      IconData icon, Color accent) {
    final theme = Theme.of(context);
    final selected = type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected && theme.brightness == Brightness.light
                ? const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 3,
                        offset: Offset(0, 1))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? accent : theme.hintColor),
              const SizedBox(width: 6),
              Text(label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? theme.colorScheme.onSurface
                        : theme.hintColor,
                  )),
            ],
          ),
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

/// Horizontal, single-row category picker. Keeps the sheet short so the amount
/// and keypad stay on screen while typing. Selected chip auto-scrolls into view.
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedId,
    required this.income,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedId;
  final bool income;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 84,
        child: Center(child: Text('No categories yet')),
      );
    }
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i == categories.length) {
            return _AddCategoryChip(income: income, onCreated: onSelect);
          }
          final c = categories[i];
          return _CategoryChip(
            category: c,
            selected: c.id == selectedId,
            onTap: () => onSelect(c.id),
          );
        },
      ),
    );
  }
}

class _AddCategoryChip extends StatelessWidget {
  const _AddCategoryChip({required this.income, required this.onCreated});

  final bool income;
  final ValueChanged<String> onCreated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: 64,
      child: Material(
        color: dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () async {
            final id = await showAddCategorySheet(context, income: income);
            if (id != null) onCreated(id);
          },
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
    return SizedBox(
      width: 64,
      child: Material(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryAvatar(
                  iconKey: category.icon, colorHex: category.colorHex, size: 34),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? theme.colorScheme.primary : null,
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
