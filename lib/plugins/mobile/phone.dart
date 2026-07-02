import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:url_launcher/url_launcher.dart';

class PhonePlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    // ===== 从 params 里取参数 =====
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    print('📞 Phone 插件: $action, params: $params');

    if (action == 'call') {
      final number = params['number'] as String? ?? '';

      if (number.isEmpty) {
        envelop.payload = {'ok': false, 'error': '电话号码不能为空'};
        return envelop;
      }

      try {
        final uri = Uri.parse('tel:$number');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          envelop.payload = {'ok': true, 'number': number};
        } else {
          envelop.payload = {'ok': false, 'error': '无法拨打电话'};
        }
      } catch (e) {
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    } else {
      envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
    }

    return envelop;
  }
}
