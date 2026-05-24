import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/preferences_provider.dart';
import '../../data/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(FlutterLocalNotificationsPlugin()),
);

/// Master push-notifications toggle (persisted).
class PushEnabledNotifier extends Notifier<bool> {
  static const _key = 'notif_push';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final pushEnabledProvider =
    NotifierProvider<PushEnabledNotifier, bool>(PushEnabledNotifier.new);

/// Budget-alert toggle (persisted).
class BudgetAlertsNotifier extends Notifier<bool> {
  static const _key = 'notif_budget_alerts';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final budgetAlertsProvider =
    NotifierProvider<BudgetAlertsNotifier, bool>(BudgetAlertsNotifier.new);
