import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  late int _amountCents = widget.initial?.amountCents ?? 0;
  late String? _categoryId = widget.initial?.categoryId;
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  late final TextEditingController _note =
      TextEditingController(text: widget.initial?.note ?? '');
  bool _saving = false;

  bool get _isEdit => widget.initial != null;
  bool get _canSave => _amountCents > 0 && _categoryId != null && !_saving;

  void _onDigit(int d) =>
      setState(() => _amountCents = (_amountCents * 10 + d).clamp(0, 99999999));

  void _onBackspace() => setState(() => _amountCents = _amountCents ~/ 10);

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
      await repo.updateExpense(
        widget.initial!.copyWith(
          amountCents: _amountCents,
          categoryId: _categoryId!,
          note: noteOrNull,
          date: _date,
          updatedAt: now,
          syncStatus: SyncStatus.pending,
        ),
      );
    } else {
      await repo.addExpense(
        Expense(
          id: const Uuid().v4(),
          userId: ref.read(currentUserIdProvider),
          amountCents: _amountCents,
          categoryId: _categoryId!,
          note: noteOrNull,
          date: _date,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
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
              _isEdit ? 'Edit expense' : 'Add expense',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              formatCents(_amountCents),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CategoryGrid(
              categories: categories,
              selectedId: _categoryId,
              onSelect: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _note,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(_friendlyDate(_date)),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            NumPad(onDigit: _onDigit, onBackspace: _onBackspace),
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

String _friendlyDate(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return 'Today';
  }
  return DateFormat.yMMMd().format(d);
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
      childAspectRatio: 0.78,
      children: [
        for (final c in categories)
          _CategoryChip(
            category: c,
            selected: c.id == selectedId,
            onTap: () => onSelect(c.id),
          ),
      ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: CategoryAvatar(
              iconKey: category.icon,
              colorHex: category.colorHex,
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
