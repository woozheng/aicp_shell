import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

bool get isAndroid => Platform.isAndroid;
bool get isIOS => Platform.isIOS;
bool get isWindows => Platform.isWindows;
bool get isMacOS => Platform.isMacOS;
bool get isLinux => Platform.isLinux;

bool get isHarmonyOS {
  final os = Platform.operatingSystem.toLowerCase();
  return os.contains('harmony') || os.contains('ohos');
}

class MobileProcessPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? 'open';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'open':
        return await _open(envelop, params);
      default:
        envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
        return envelop;
    }
  }

  static Future<Envelop> _open(
    Envelop envelop,
    Map<String, dynamic> params,
  ) async {
    final target = params['target'] as String? ?? '';
    if (target.isEmpty) {
      envelop.payload = {'ok': false, 'error': 'Missing target'};
      return envelop;
    }

    print('📱 [MobileProcess] raw target: $target | OS: ${Platform.operatingSystem}');

    // 鸿蒙拦截安卓Intent
    if (isHarmonyOS &&
        (target.startsWith('android.settings.') ||
            target.startsWith('android.intent.') ||
            target.startsWith('android.provider.'))) {
      envelop.payload = {
        'ok': false,
        'error': 'HarmonyOS 不兼容 Android Intent',
        'hint': '请使用鸿蒙AppLinking地址或通用协议(tel/sms/http)'
      };
      return envelop;
    }

    Uri uri;
    if (target.startsWith('http://') || target.startsWith('https://')) {
      uri = Uri.parse(target);
    } else if (target.startsWith('tel:') ||
        target.startsWith('sms:') ||
        target.startsWith('mailto:') ||
        target.startsWith('geo:')) {
      uri = Uri.parse(target);
    } else if (target.contains('://')) {
      uri = Uri.parse(target);
    } else if (isAndroid &&
        (target.startsWith('android.settings.') ||
            target.startsWith('android.intent.') ||
            target.startsWith('android.provider.'))) {
      uri = Uri.parse('intent://#Intent;action=$target;category=android.intent.category.DEFAULT;end');
    } else if (isIOS && target.startsWith('ios_prefs_')) {
      final prefsMap = {
        'ios_prefs_main': 'App-Prefs:',
        'ios_prefs_wifi': 'App-Prefs:root=WIFI',
        'ios_prefs_bluetooth': 'App-Prefs:root=Bluetooth',
      };
      final scheme = prefsMap[target] ?? 'App-Prefs:';
      uri = Uri.parse(scheme);
    } else if (isAndroid && target.contains('.') && !target.startsWith('/')) {
      uri = Uri.parse('market://details?id=$target');
    } else {
      uri = Uri.parse(target);
    }

    print('📱 [MobileProcess] final uri: $uri');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        envelop.payload = {
          'ok': true,
          'target': target,
          'uri': uri.toString(),
          'platform': Platform.operatingSystem,
        };
        print('📱 launch success');
      } else {
        envelop.payload = {
          'ok': false,
          'error': '无法打开目标',
          'hint': isAndroid
              ? '模拟器系统精简，部分系统Intent不支持，真机正常'
              : '无对应应用可处理该链接'
        };
      }
    } catch (e) {
      envelop.payload = {'ok': false, 'error': e.toString()};
    }

    return envelop;
  }
}