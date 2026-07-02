// lib/plugins/mobile/vibrate.dart
import 'package:flutter/services.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

class VibratePlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? 'vibrate';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    if (action == 'vibrate') {
      try {
        final duration = params['duration'] as int? ?? 200;
        
        if (duration <= 0) {
          envelop.payload = {'ok': false, 'error': '无效的震动时长'};
          return envelop;
        }

        // 简单震动
        HapticFeedback.lightImpact();
        
        // 或者用 vibrate 包做更精细控制
        // await Vibration.vibrate(duration: duration);
        
        envelop.payload = {
          'ok': true,
          'duration': duration,
        };
      } catch (e) {
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    } else {
      envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
    }
    return envelop;
  }
}