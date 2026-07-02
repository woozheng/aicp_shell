import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:battery_plus/battery_plus.dart';

class BatteryPlugin {
  static final Battery _battery = Battery();

  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';

    print('🔋 Battery 插件: $action');

    if (action == 'get_status') {
      try {
        final level = await _battery.batteryLevel;
        final state = await _battery.batteryState;

        envelop.payload = {
          'ok': true,
          'level': level,
          'is_charging': state == BatteryState.charging,
          'state': state.toString(),
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
