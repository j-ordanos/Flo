import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../domain/entities/expense.dart';

/// A transaction row: category badge, merchant (→ note → category) title,
/// "Category · date" subtitle, and a negative amount.
class ExpenseTile extends ConsumerWidget {
  const ExpenseTile({required this.expense, this.onTap, super.key});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoriesByIdProvider)[expense.categoryId];
    final isIncome = expense.type == TransactionType.income;
    final title = switch (expense) {
      Expense(:final merchant?) when merchant.isNotEmpty => merchant,
      Expense(:final note?) when note.isNotEmpty => note,
      _ => category?.name ?? (isIncome ? 'Income' : 'Expense'),
    };
    final subtitle = [
      if (category != null) category.name,
      _relativeDate(expense.date),
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: category == null
          ? const CircleAvatar(child: Icon(Icons.category_outlined))
          : CategoryAvatar(iconKey: category.icon, colorHex: category.colorHex),
      title: Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
      subtitle: Text(subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      trailing: Text(
        '${isIncome ? '+' : '-'}${formatCents(expense.amountCents)}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isIncome ? AppColors.success : null,
        ),
      ),
    );
  }
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final d = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat.MMMd().format(date);
}
