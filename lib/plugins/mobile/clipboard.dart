// lib/plugins/mobile/clipboard.dart
import 'package:flutter/services.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

class ClipboardPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? 'copy';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    try {
      if (action == 'copy') {
        final text = params['text'] as String? ?? '';
        if (text.isEmpty) {
          envelop.payload = {'ok': false, 'error': '内容为空'};
          return envelop;
        }
        await Clipboard.setData(ClipboardData(text: text));
        envelop.payload = {'ok': true, 'text': text};
        
      } else if (action == 'paste') {
        final data = await Clipboard.getData('text/plain');
        final text = data?.text ?? '';
        envelop.payload = {
          'ok': true,
          'text': text,
          'has_content': text.isNotEmpty,
        };
        
      } else {
        envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
      }
    } catch (e) {
      envelop.payload = {'ok': false, 'error': e.toString()};
    }
    return envelop;
  }
}