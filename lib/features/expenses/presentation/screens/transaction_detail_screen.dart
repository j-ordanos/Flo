import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/utils/hex_color.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../widgets/add_expense_sheet.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseByIdProvider(expenseId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                      icon: Icons.arrow_back, onTap: () => context.pop()),
                  _CircleButton(
                    icon: Icons.delete_outline,
                    onTap: () => _confirmDelete(context, ref, expenseId),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const LoadingView(),
                error: (_, _) =>
                    const ErrorView(message: 'Could not load transaction.'),
                data: (expense) => expense == null
                    ? const EmptyView(
                        icon: Icons.search_off,
                        title: 'Not found',
                        message: 'This expense no longer exists.',
                      )
                    : _Details(expense: expense),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, String id) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete expense?'),
      content: const Text('This expense will be removed.'),
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
  if ((confirmed ?? false) && context.mounted) {
    await ref.read(expenseRepositoryProvider).deleteExpense(id);
    ref.read(syncControllerProvider.notifier).requestSync();
    if (context.mounted) context.pop();
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
    final title = expense.merchant?.isNotEmpty == true
        ? expense.merchant!
        : (category?.name ?? 'Expense');

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 24),
      children: [
        const SizedBox(height: AppSpacing.md),
        if (category != null)
          Center(
            child: CategoryAvatar(
                iconKey: category.icon, colorHex: category.colorHex, size: 76),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(title,
            textAlign: TextAlign.center,
            style:
                theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
        const SizedBox(height: 6),
        Text('-${formatCents(expense.amountCents)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.md),
        if (category != null) Center(child: _CategoryPill(category: category)),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              _Row(label: 'Date', value: DateFormat.yMMMMEEEEd().format(expense.date)),
              const Divider(height: 1),
              _Row(
                label: 'Status',
                value: synced ? 'Synced' : 'Pending',
                valueColor: synced ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        ),
        if (expense.note?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NOTE',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.hintColor, letterSpacing: 0.4)),
                const SizedBox(height: 6),
                Text(expense.note!, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _ReceiptSection(expense: expense),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showAddExpenseSheet(context, initial: expense),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                  foregroundColor: AppColors.danger,
                  elevation: 0,
                ),
                onPressed: () => _confirmDelete(context, ref, expense.id),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(category.colorHex);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(category.name,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class _ReceiptSection extends ConsumerStatefulWidget {
  const _ReceiptSection({required this.expense});

  final Expense expense;

  @override
  ConsumerState<_ReceiptSection> createState() => _ReceiptSectionState();
}

class _ReceiptSectionState extends ConsumerState<_ReceiptSection> {
  bool _busy = false;

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _attach() async {
    if (!AppEnv.hasSupabase || ref.read(currentUserProvider) == null) {
      _snack('Sign in to attach receipts.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    setState(() => _busy = true);
    try {
      final path = await ref.read(receiptServiceProvider).pickAndUpload(
            userId: ref.read(currentUserIdProvider),
            expenseId: widget.expense.id,
            source: source,
          );
      if (path != null) {
        await ref.read(expenseRepositoryProvider).updateExpense(
              widget.expense.copyWith(
                receiptPath: path,
                updatedAt: DateTime.now().toUtc(),
                syncStatus: SyncStatus.pending,
              ),
            );
        ref.read(syncControllerProvider.notifier).requestSync();
      }
    } catch (_) {
      _snack('Could not attach the receipt.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      final path = widget.expense.receiptPath;
      if (path != null) {
        try {
          await ref.read(receiptServiceProvider).remove(path);
        } catch (_) {/* ignore storage errors */}
      }
      await ref.read(expenseRepositoryProvider).updateExpense(
            widget.expense.copyWith(
              receiptPath: null,
              updatedAt: DateTime.now().toUtc(),
              syncStatus: SyncStatus.pending,
            ),
          );
      ref.read(syncControllerProvider.notifier).requestSync();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = widget.expense.receiptPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECEIPT',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.hintColor, letterSpacing: 0.4)),
        const SizedBox(height: AppSpacing.sm),
        if (_busy)
          const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()))
        else if (path != null)
          _ReceiptImage(path: path, onRemove: _remove)
        else
          DottedPlaceholder(onTap: _attach),
      ],
    );
  }
}

class _ReceiptImage extends ConsumerWidget {
  const _ReceiptImage({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: FutureBuilder<String>(
            future: ref.read(receiptServiceProvider).signedUrl(path),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()));
              }
              return Image.network(
                snap.data!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 180,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRemove,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Remove'),
          ),
        ),
      ],
    );
  }
}

class DottedPlaceholder extends StatelessWidget {
  const DottedPlaceholder({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkSurfaceAlt
              : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, color: theme.hintColor),
            const SizedBox(height: 6),
            Text('Attach a receipt',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('Photo or PDF',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: CircleBorder(side: BorderSide(color: theme.dividerColor)),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
