import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:share_plus/share_plus.dart';

class SharePlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    print('📤 Share 插件: $action, params: $params');

    if (action == 'text') {
      final text = params['text'] as String? ?? '';

      if (text.isEmpty) {
        envelop.payload = {'ok': false, 'error': '分享内容不能为空'};
        return envelop;
      }

      try {
        await Share.share(text);
        envelop.payload = {'ok': true, 'text': text};
      } catch (e) {
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    } else if (action == 'file') {
      final path = params['path'] as String? ?? '';

      if (path.isEmpty) {
        envelop.payload = {'ok': false, 'error': '文件路径不能为空'};
        return envelop;
      }

      try {
        final xFile = XFile(path);
        await Share.shareXFiles([xFile]);
        envelop.payload = {'ok': true, 'path': path};
      } catch (e) {
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    } else {
      envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
    }

    return envelop;
  }
}
