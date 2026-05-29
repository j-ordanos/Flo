import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper over flutter_local_notifications for budget alerts.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'budget_alerts',
    'Budget alerts',
    description: 'Notifies you when a category goes over budget.',
    importance: Importance.high,
  );

  static const _generalChannel = AndroidNotificationChannel(
    'general',
    'General',
    description: 'General Flo notifications.',
    importance: Importance.defaultImportance,
  );

  /// Initializes the plugin and requests permission. Idempotent and best-effort
  /// (no-op on platforms without an implementation, e.g. desktop/tests).
  Future<void> init() async {
    if (_ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      await android?.createNotificationChannel(_generalChannel);
      await android?.requestNotificationsPermission();

      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _ready = true;
    } catch (_) {
      // Notifications unsupported here — ignore.
    }
  }

  Future<void> showBudgetExceeded({
    required String category,
    required String spent,
    required String limit,
  }) async {
    await init();
    try {
      await _plugin.show(
        category.hashCode & 0x7fffffff,
        'Over budget: $category',
        "You've spent $spent of your $limit $category budget.",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_alerts',
            'Budget alerts',
            channelDescription:
                'Notifies you when a category goes over budget.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Best-effort.
    }
  }

  /// A general one-off notification (e.g. confirming notifications are on).
  Future<void> showReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'general',
            'General',
            channelDescription: 'General Flo notifications.',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Best-effort.
    }
  }

  /// Removes all delivered/pending notifications (e.g. when the user turns
  /// notifications off).
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Best-effort.
    }
  }
}
