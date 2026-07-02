import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifyPlugin {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    print('🔔 Notify 插件: $action, params: $params');

    if (action == 'send') {
      final title = params['title'] as String? ?? '通知';
      final body = params['body'] as String? ?? '';

      try {
        // ===== 初始化通知通道（Android 需要） =====
        await _initializeChannel();

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'aicp_channel',
              'AICP 通知',
              channelDescription: 'AICP 应用通知',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@drawable/ic_notification', // ← 加这行
            );

        const NotificationDetails details = NotificationDetails(
          android: androidDetails,
        );

        await _notifications.show(0, title, body, details);
        print('🔔 通知发送成功');
        envelop.payload = {'ok': true, 'title': title, 'body': body};
      } catch (e) {
        print('🔔 通知发送失败: $e');
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    } else {
      envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
    }

    return envelop;
  }

  static Future<void> _initializeChannel() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> initialize() async {
    await _initializeChannel();
  }
}
