// lib/core/registry.dart
import 'dart:io';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';



// 插件导入
import 'package:aicp_shell/plugins/mobile/camera.dart';
import 'package:aicp_shell/plugins/mobile/gps.dart';
import 'package:aicp_shell/plugins/mobile/phone.dart';
import 'package:aicp_shell/plugins/mobile/notify.dart';
import 'package:aicp_shell/plugins/mobile/storage.dart';
import 'package:aicp_shell/plugins/mobile/share.dart';
import 'package:aicp_shell/plugins/mobile/clipboard.dart';
import 'package:aicp_shell/plugins/mobile/network.dart';
import 'package:aicp_shell/plugins/mobile/battery.dart';
import 'package:aicp_shell/plugins/mobile/file_system.dart';
import 'package:aicp_shell/plugins/mobile/process.dart';
import 'package:aicp_shell/plugins/mobile/scanner.dart';
import 'package:aicp_shell/plugins/mobile/vibrate.dart';
import 'package:aicp_shell/plugins/mobile/contacts.dart';
import 'package:aicp_shell/plugins/mobile/bluetooth.dart';
import 'package:aicp_shell/plugins/mobile/mobile_process.dart';

// 平台判断
bool get isAndroid => Platform.isAndroid;
bool get isIOS => Platform.isIOS;
bool get isWindows => Platform.isWindows;
bool get isMacOS => Platform.isMacOS;
bool get isLinux => Platform.isLinux;
bool get isHarmonyOS {
  final os = Platform.operatingSystem.toLowerCase();
  return os.contains('harmony') || os.contains('ohos');
}
typedef PluginHandler = Future<Envelop?> Function(Envelop envelop, ShellAgent agent);

class PluginRegistry {
  static final Map<String, PluginHandler> _plugins = {};

  static void registerAll() {
    // 全平台通用硬件插件
    register('mobile/camera', CameraPlugin.execute);
    register('mobile/gps', GPSPlugin.execute);
    register('mobile/phone', PhonePlugin.execute);
    register('mobile/notify', NotifyPlugin.execute);
    register('mobile/storage', StoragePlugin.execute);
    register('mobile/share', SharePlugin.execute);
    register('mobile/clipboard', ClipboardPlugin.execute);
    register('mobile/network', NetworkPlugin.execute);
    register('mobile/battery', BatteryPlugin.execute);
    register('mobile/file_system', FileSystemPlugin.execute);
    register('mobile/scanner', ScannerPlugin.execute);
    register('mobile/vibrate', VibratePlugin.execute);
    register('mobile/contacts', ContactsPlugin.execute);
    register('mobile/bluetooth', BluetoothPlugin.execute);


    // 移动端跳转插件 全设备注册
    register('mobile/mobile_process', MobileProcessPlugin.execute);

    // 桌面进程插件：仅Windows/macOS/Linux注册
    if (isWindows || isMacOS || isLinux) {
      register('mobile/process', ProcessPlugin.execute);
    }

    // 测试插件
    register('test/echo', (envelop, agent) async {
      final msg = envelop.payload['message'] ?? 'No message';
      envelop.payload = {'echo': 'You said: $msg'};
      return envelop;
    });
    register('test/ping', (envelop, agent) async {
      envelop.payload = {'pong': 'pong'};
      return envelop;
    });

    print('[Registry] ✅ 所有插件注册完成，共 ${_plugins.length} 个');
    print('[Registry] 📋 已注册插件: ${_plugins.keys.join(", ")}');
  }

  static void register(String receiver, PluginHandler handler) {
    _plugins[receiver] = handler;
    print('[Registry] ✅ Registered: $receiver');
  }

  static PluginHandler? get(String receiver) => _plugins[receiver];
  static bool has(String receiver) => _plugins.containsKey(receiver);
  static List<String> list() => _plugins.keys.toList();
  static int get count => _plugins.length;
  static void clear() => _plugins.clear();
  static bool remove(String receiver) => _plugins.remove(receiver) != null;
}

typedef Registry = PluginRegistry;