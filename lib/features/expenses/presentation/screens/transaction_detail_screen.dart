import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../widgets/add_expense_sheet.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.expenseId, super.key});

  final String expenseId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('This expense will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      await ref.read(expenseRepositoryProvider).deleteExpense(expenseId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseByIdProvider(expenseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final expense = ref.read(expenseByIdProvider(expenseId)).value;
              if (expense != null) {
                showAddExpenseSheet(context, initial: expense);
              }
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, _) => const ErrorView(message: 'Could not load transaction.'),
        data: (expense) => expense == null
            ? const EmptyView(
                icon: Icons.search_off,
                title: 'Not found',
                message: 'This expense no longer exists.',
              )
            : _Details(expense: expense),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoriesByIdProvider)[expense.categoryId];
    final synced = expense.syncStatus == SyncStatus.synced;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (category != null)
          Center(
            child: CategoryAvatar(
              iconKey: category.icon,
              colorHex: category.colorHex,
              size: 72,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          formatCents(expense.amountCents),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          category?.name ?? 'Uncategorized',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: DateFormat.yMMMMd().format(expense.date),
              ),
              if (expense.merchant?.isNotEmpty ?? false)
                _DetailRow(
                  icon: Icons.store_outlined,
                  label: 'Merchant',
                  value: expense.merchant!,
                ),
              if (expense.note?.isNotEmpty ?? false)
                _DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Note',
                  value: expense.note!,
                ),
              _DetailRow(
                icon: synced ? Icons.cloud_done_outlined : Icons.sync,
                label: 'Sync',
                value: synced ? 'Synced' : 'Pending',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),
      ),
      subtitle: Text(value, style: theme.textTheme.bodyLarge),
    );
  }
}
