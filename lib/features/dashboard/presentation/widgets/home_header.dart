import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../features/notifications/presentation/providers/notification_providers.dart';

/// Dashboard greeting header: gradient avatar with initials, a time-of-day
/// greeting + first name, and a notifications bell.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final name =
        (user?.userMetadata?['name'] as String?) ??
        user?.email?.split('@').first;
    final firstName = (name == null || name.isEmpty)
        ? 'there'
        : name.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppGradients.brand,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                Text(
                  firstName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const _BellButton(),
        ],
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'F';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}

class _BellButton extends ConsumerWidget {
  const _BellButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkResponse(
      onTap: () async {
        final service = ref.read(notificationServiceProvider);
        try {
          final notifs = await service.getNotifications();
          if (notifs.isEmpty) {
            final open = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Notifications'),
                content: const Text(
                  'You have no notifications. Open notification settings?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(c).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(c).pop(true),
                    child: const Text('Open'),
                  ),
                ],
              ),
            );
            if (open == true) {
              context.go(AppRoutes.profile);
            }
            return;
          }

          // There are notifications: navigate to Profile and show a brief
          // message so the user knows there are outstanding notifications.
          context.go(AppRoutes.profile);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have ${notifs.length} notification(s). Check Notifications in Profile.',
              ),
            ),
          );
        } catch (_) {
          // If notifications are unsupported, still navigate to Profile and
          // inform the user.
          context.go(AppRoutes.profile);
          await showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Notifications'),
              content: const Text(
                'Notifications are unavailable on this device.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      radius: 24,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
