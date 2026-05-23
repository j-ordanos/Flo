import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/sync_status.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../domain/entities/expense.dart';

/// A single expense row used in lists. Resolves its category for the avatar
/// and falls back through merchant → note → category name for the title.
class ExpenseTile extends ConsumerWidget {
  const ExpenseTile({required this.expense, this.onTap, super.key});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoriesByIdProvider)[expense.categoryId];
    final title = switch (expense) {
      Expense(:final merchant?) when merchant.isNotEmpty => merchant,
      Expense(:final note?) when note.isNotEmpty => note,
      _ => category?.name ?? 'Expense',
    };

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: category == null
          ? const CircleAvatar(child: Icon(Icons.category_outlined))
          : CategoryAvatar(iconKey: category.icon, colorHex: category.colorHex),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(DateFormat.MMMd().format(expense.date)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expense.syncStatus == SyncStatus.pending)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.sync, size: 14, color: theme.hintColor),
            ),
          Text(
            '-${formatCents(expense.amountCents)}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
