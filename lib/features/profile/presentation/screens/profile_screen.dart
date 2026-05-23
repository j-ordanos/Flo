import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../providers/settings_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const _Header(),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Preferences'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.payments_outlined,
                  title: 'Currency',
                  trailing: Text('${currency.code}  ${currency.symbol}'),
                  onTap: () => _pickCurrency(context, ref),
                ),
                const Divider(height: 1),
                _SettingTile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Appearance',
                  trailing: Text(_themeLabel(themeMode)),
                  onTap: () => _pickTheme(context, ref),
                ),
                const Divider(height: 1),
                const _NotificationsTile(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Data'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: _SettingTile(
              icon: Icons.ios_share,
              title: 'Export expenses (CSV)',
              onTap: () => _export(ref),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Account'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: _SettingTile(
              icon: Icons.cloud_sync_outlined,
              title: 'Sign in to sync',
              subtitle: 'Back up and sync across devices',
              onTap: () => context.push(AppRoutes.login),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'Flo · v1.0.0',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(WidgetRef ref) async {
    final expenses = ref.read(expensesProvider).value ?? const [];
    final categories = ref.read(categoriesByIdProvider);
    await ref.read(csvExportServiceProvider).exportExpenses(expenses, categories);
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final current = ref.read(currencyProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Currency'),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in kCurrencies)
                    ListTile(
                      leading: SizedBox(
                        width: 28,
                        child: Text(c.symbol, textAlign: TextAlign.center),
                      ),
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

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Appearance'),
            ),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(_themeIcon(mode)),
                title: Text(_themeLabel(mode)),
                trailing: mode == current
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).set(mode);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

String _themeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

IconData _themeIcon(ThemeMode mode) => switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: AppGradients.brand,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Local account', style: theme.textTheme.titleMedium),
                Text(
                  'Sign in to back up your data',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
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
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.hintColor,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ??
          (onTap == null
              ? null
              : Icon(Icons.chevron_right, color: theme.hintColor)),
      onTap: onTap,
    );
  }
}

class _NotificationsTile extends StatefulWidget {
  const _NotificationsTile();

  @override
  State<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<_NotificationsTile> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      secondary:
          Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
      title: const Text('Notifications'),
      value: _enabled,
      onChanged: (v) => setState(() => _enabled = v),
    );
  }
}
