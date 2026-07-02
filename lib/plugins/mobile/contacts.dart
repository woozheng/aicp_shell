// lib/plugins/mobile/contacts.dart
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

class ContactsPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? 'open';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    try {
      if (action == 'open') {
        // 打开系统通讯录
        final uri = Platform.isAndroid 
          ? Uri.parse('content://contacts/people')
          : Uri.parse('addressbook://');
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          envelop.payload = {'ok': true, 'action': 'opened'};
        } else {
          envelop.payload = {'ok': false, 'error': '无法打开系统通讯录'};
        }

      } else if (action == 'pick') {
        // 选择联系人
        if (Platform.isAndroid) {
          await launchUrl(Uri.parse('content://contacts/people'));
        } else {
          await launchUrl(Uri.parse('addressbook://'));
        }
        envelop.payload = {'ok': true, 'hint': '请在系统通讯录中选择'};

      } else if (action == 'add') {
        // 添加联系人
        final name = params['name'] as String? ?? '';
        final phone = params['phone'] as String? ?? '';
        
        if (Platform.isAndroid) {
          await launchUrl(Uri.parse('content://contacts/people'));
        } else {
          await launchUrl(Uri.parse('addressbook://'));
        }
        envelop.payload = {
          'ok': true, 
          'hint': '请在系统通讯录中添加: $name $phone',
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