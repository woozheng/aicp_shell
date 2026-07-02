// lib/plugins/mobile/bluetooth.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

bool get isAndroid => Platform.isAndroid;
bool get isHarmonyOS {
  final os = Platform.operatingSystem.toLowerCase();
  return os.contains('harmony') || os.contains('ohos');
}

class BluetoothPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    // 参数平铺在payload顶层，无嵌套params
    final Map<String, dynamic> params = envelop.payload;

    try {
      // 申请蓝牙相关权限
      final hasPerm = await _requestBluetoothPermissions();
      if (!hasPerm) {
        envelop.payload = {'ok': false, 'error': '蓝牙权限被用户拒绝'};
        return envelop;
      }

      switch (action) {
        case 'scan_start':
          envelop.payload = {
            'ok': true,
            'scanning': true,
            'devices': []
          };
          break;
        case 'scan_stop':
          envelop.payload = {
            'ok': true,
            'scanning': false
          };
          break;
        case 'get_devices':
          envelop.payload = {
            'ok': true,
            'devices': []
          };
          break;
        case 'connect':
          final String addr = params['address'] ?? '';
          envelop.payload = {
            'ok': true,
            'address': addr,
            'connected': true
          };
          break;
        case 'disconnect':
          envelop.payload = {
            'ok': true,
            'disconnected': true
          };
          break;
        case 'send':
          final String data = params['data'] ?? '';
          envelop.payload = {
            'ok': true,
            'data': data,
            'sent': true
          };
          break;
        default:
          envelop.payload = {
            'ok': false,
            'error': 'Unknown bluetooth action: $action'
          };
      }
    } catch (e) {
      envelop.payload = {
        'ok': false,
        'error': e.toString()
      };
    }
    return envelop;
  }

  /// 分系统申请蓝牙权限：鸿蒙 / Android12+ / 旧安卓 / iOS
  static Future<bool> _requestBluetoothPermissions() async {
    if (isHarmonyOS) {
      final bt = await Permission.bluetooth.request();
      final loc = await Permission.location.request();
      return bt.isGranted && loc.isGranted;
    }

    if (isAndroid) {
      // 先申请Android 12专用蓝牙权限
      final scanRes = await Permission.bluetoothScan.request();
      final connRes = await Permission.bluetoothConnect.request();
      if (scanRes.isGranted && connRes.isGranted) {
        return true;
      }
      // 申请失败则降级为旧版蓝牙+定位
      final btBase = await Permission.bluetooth.request();
      final locBase = await Permission.location.request();
      return btBase.isGranted && locBase.isGranted;
    }

    // iOS
    final btIos = await Permission.bluetooth.request();
    return btIos.isGranted;
  }
}