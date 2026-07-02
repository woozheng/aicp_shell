import 'dart:convert';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoragePlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    // ===== 从 params 里取参数 =====
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    print('💾 Storage: $action, params: $params');

    final prefs = await SharedPreferences.getInstance();

    if (action == 'set') {
      final key = params['key'] as String? ?? '';
      final value = params['value'];

      if (key.isEmpty) {
        envelop.payload = {'ok': false, 'error': 'Key required'};
        return envelop;
      }

      try {
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List || value is Map) {
          await prefs.setString(key, jsonEncode(value));
        } else {
          await prefs.setString(key, value.toString());
        }
        envelop.payload = {'ok': true, 'key': key};
      } catch (e) {
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    } else if (action == 'get') {
      final key = params['key'] as String? ?? '';
      if (key.isEmpty) {
        envelop.payload = {'ok': false, 'error': 'Key required'};
        return envelop;
      }

      final value = prefs.get(key);
      envelop.payload = {'ok': true, 'key': key, 'value': value};
    } else if (action == 'remove') {
      final key = params['key'] as String? ?? '';
      if (key.isEmpty) {
        envelop.payload = {'ok': false, 'error': 'Key required'};
        return envelop;
      }

      await prefs.remove(key);
      envelop.payload = {'ok': true, 'key': key};
    } else if (action == 'clear') {
      await prefs.clear();
      envelop.payload = {'ok': true};
    } else {
      envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
    }

    return envelop;
  }
}
