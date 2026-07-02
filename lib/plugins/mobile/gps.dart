import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:geolocator/geolocator.dart';

class GPSPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    print('📍 GPS 插件: $action');

    if (action == 'get_current') {
      try {
        print('📍 检查权限...');
        LocationPermission permission = await Geolocator.checkPermission();
        print('📍 权限状态: $permission');

        if (permission == LocationPermission.denied) {
          print('📍 请求权限...');
          permission = await Geolocator.requestPermission();
          print('📍 权限结果: $permission');
          if (permission == LocationPermission.denied) {
            envelop.payload = {'ok': false, 'error': 'Permission denied'};
            return envelop;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          envelop.payload = {
            'ok': false,
            'error': 'Permission permanently denied',
          };
          return envelop;
        }

        print('📍 检查 GPS 是否开启...');
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('📍 GPS 未开启');
          envelop.payload = {'ok': false, 'error': 'GPS 未开启'};
          return envelop;
        }
        print('📍 GPS 已开启');

        print('📍 获取位置中...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        print('📍 定位成功: ${position.latitude}, ${position.longitude}');
        envelop.payload = {
          'ok': true,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'altitude': position.altitude,
          'speed': position.speed,
          'timestamp': position.timestamp.toIso8601String(),
        };
      } catch (e) {
        print('📍 定位错误: $e');
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    } else {
      envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
    }

    return envelop;
  }
}
