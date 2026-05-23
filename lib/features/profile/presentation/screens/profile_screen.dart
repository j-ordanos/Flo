import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../providers/settings_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _faceId = false;
  bool _push = true;
  bool _budgetAlerts = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final currency = ref.watch(currencyProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final name = (user?.userMetadata?['name'] as String?) ??
        user?.email?.split('@').first ??
        'Local account';
    final email = user?.email ?? 'Sign in to back up your data';

    final expenseCount = ref.watch(expensesProvider).value?.length ?? 0;
    final categoryCount = ref.watch(categoriesProvider).value?.length ?? 0;
    final monthSpent = ref.watch(monthlyTotalProvider).value ?? 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
          children: [
            Text('Profile', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.brand,
                      shape: BoxShape.circle,
                    ),
                    child: Text(_initials(name),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _Stat(label: 'This month', value: formatCents0(monthSpent)),
                const SizedBox(width: AppSpacing.sm),
                _Stat(label: 'Expenses', value: '$expenseCount'),
                const SizedBox(width: AppSpacing.sm),
                _Stat(label: 'Categories', value: '$categoryCount'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionLabel('Preferences'),
            const SizedBox(height: AppSpacing.sm),
            _Group(children: [
              _SettingsRow(
                icon: Icons.payments_outlined,
                tint: AppColors.primary,
                label: 'Currency',
                detail: '${currency.code} · ${currency.symbol}',
                onTap: _pickCurrency,
              ),
              _SettingsRow(
                icon: Icons.dark_mode_outlined,
                tint: AppColors.primary,
                label: 'Dark mode',
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) => ref
                      .read(themeModeProvider.notifier)
                      .set(v ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
              _SettingsRow(
                icon: Icons.fingerprint,
                tint: AppColors.success,
                label: 'Face ID',
                trailing: Switch(
                    value: _faceId,
                    onChanged: (v) => setState(() => _faceId = v)),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            const _SectionLabel('Notifications'),
            const SizedBox(height: AppSpacing.sm),
            _Group(children: [
              _SettingsRow(
                icon: Icons.notifications_outlined,
                tint: AppColors.warning,
                label: 'Push notifications',
                trailing: Switch(
                    value: _push, onChanged: (v) => setState(() => _push = v)),
              ),
              _SettingsRow(
                icon: Icons.warning_amber_rounded,
                tint: AppColors.danger,
                label: 'Budget alerts',
                trailing: Switch(
                    value: _budgetAlerts,
                    onChanged: (v) => setState(() => _budgetAlerts = v)),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            const _SectionLabel('Data'),
            const SizedBox(height: AppSpacing.sm),
            _Group(children: [
              _SettingsRow(
                icon: Icons.ios_share,
                tint: AppColors.primary,
                label: 'Export as CSV',
                onTap: _exportCsv,
              ),
              _SettingsRow(
                icon: Icons.picture_as_pdf_outlined,
                tint: AppColors.primary,
                label: 'Export as PDF',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export is coming soon.')),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            _Group(children: [
              if (user == null)
                _SettingsRow(
                  icon: Icons.cloud_sync_outlined,
                  tint: AppColors.primary,
                  label: 'Sign in to sync',
                  onTap: () => context.go(AppRoutes.login),
                )
              else
                _SettingsRow(
                  icon: Icons.logout,
                  tint: AppColors.danger,
                  label: 'Log out',
                  danger: true,
                  onTap: () => ref.read(authControllerProvider).signOut(),
                ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text('Flo · v1.0.0 · Made with care',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final expenses = ref.read(expensesProvider).value ?? const [];
    final categories = ref.read(categoriesByIdProvider);
    await ref.read(csvExportServiceProvider).exportExpenses(expenses, categories);
  }

  Future<void> _pickCurrency() async {
    final current = ref.read(currencyProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
                padding: EdgeInsets.all(AppSpacing.md), child: Text('Currency')),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in kCurrencies)
                    ListTile(
                      leading: SizedBox(
                          width: 28,
                          child:
                              Text(c.symbol, textAlign: TextAlign.center)),
                      title: Text(c.name),
                      subtitle: Text(c.code),
                      trailing: c.code == current.code
                          ? Icon(Icons.check,
                              color: Theme.of(ctx).colorScheme.primary)
                          : null,
                      onTap: () {
                        ref.read(currencyProvider.notifier).select(c);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'F';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.tint,
    required this.label,
    this.detail,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: danger ? AppColors.danger : null)),
            ),
            if (detail != null)
              Text(detail!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor)),
            ?trailing,
            if (trailing == null && onTap != null && detail == null)
              Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
