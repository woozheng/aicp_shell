import 'dart:io';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

bool get isHarmonyOS {
  final os = Platform.operatingSystem.toLowerCase();
  return os.contains('harmony') || os.contains('ohos');
}

class NetworkPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? 'status';
    try {
      if (action == 'status') {
        final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
        List<String> netTypes = results.map((item) => item.name).toList();

        envelop.payload = {
          'ok': true,
          'types': netTypes,
          'connected': results.isNotEmpty && !results.contains(ConnectivityResult.none),
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