import 'dart:convert';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:aicp_shell/core/registry.dart';
import 'package:aicp_shell/core/route.dart';

/// JS Bridge - 处理页面发来的 Envelop
class JSBridge {
  static final ShellAgent _agent = ShellAgent();

  /// 处理来自 JS 的消息
  static Future<String> handleMessage(String message) async {
    try {
      // 1. 解析 JS 发来的数据
      final data = jsonDecode(message);
      final receiver = data['receiver'] ?? '';
      final payload = data['payload'] ?? {};
      final intent = data['intent'] ?? '';

      // 2. 构建 Envelop
      final envelop = Envelop(
        sender: 'web/page',
        receiver: receiver,
        intent: intent,
        payload: payload,
      );

      print('[JSBridge] 收到 Envelop: ${envelop.receiver}');

      // 3. 路由执行
      final result = await RouteDispatcher.route(envelop, agent: _agent);

      // 4. 返回结果
      if (result != null) {
        return jsonEncode({
          'ok': true,
          'payload': result.payload,
          'trace_id': result.traceId,
        });
      } else {
        return jsonEncode({
          'ok': false,
          'error': 'No response',
        });
      }
    } catch (e) {
      return jsonEncode({
        'ok': false,
        'error': e.toString(),
      });
    }
  }
}