import 'dart:io';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

class ProcessPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? 'shell';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'run':
        return await _run(envelop, params);
      case 'spawn':
        return await _spawn(envelop, params);
      case 'shell':
        return await _shell(envelop, params);
      case 'open':
        return await _open(envelop, params);
      case 'kill':
        return await _kill(envelop, params);
      default:
        envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
        return envelop;
    }
  }

  static Future<Envelop> _run(
    Envelop envelop,
    Map<String, dynamic> params,
  ) async {
    final path = params['path'] as String? ?? '';
    final args = List<String>.from(params['args'] ?? []);
    final timeout = params['timeout'] as int? ?? 30;

    if (path.isEmpty) {
      envelop.payload = {'ok': false, 'error': 'Missing path'};
      return envelop;
    }

    try {
      final result = await Process.run(
        path,
        args,
      ).timeout(Duration(seconds: timeout));
      envelop.payload = {
        'ok': result.exitCode == 0,
        'exit_code': result.exitCode,
        'stdout': result.stdout.toString(),
        'stderr': result.stderr.toString(),
      };
    } catch (e) {
      envelop.payload = {'ok': false, 'error': e.toString()};
    }
    return envelop;
  }

  static Future<Envelop> _spawn(
    Envelop envelop,
    Map<String, dynamic> params,
  ) async {
    final path = params['path'] as String? ?? '';
    final args = List<String>.from(params['args'] ?? []);

    if (path.isEmpty) {
      envelop.payload = {'ok': false, 'error': 'Missing path'};
      return envelop;
    }

    try {
      final process = await Process.start(
        path,
        args,
        mode: ProcessStartMode.detached,
      );
      envelop.payload = {'ok': true, 'pid': process.pid};
    } catch (e) {
      envelop.payload = {'ok': false, 'error': e.toString()};
    }
    return envelop;
  }

  static Future<Envelop> _shell(
    Envelop envelop,
    Map<String, dynamic> params,
  ) async {
    final command = params['command'] as String? ?? '';
    final timeout = params['timeout'] as int? ?? 30;

    if (command.isEmpty) {
      envelop.payload = {'ok': false, 'error': 'Missing command'};
      return envelop;
    }

    String shell;
    List<String> args;

    if (Platform.isWindows) {
      shell = 'cmd.exe';
      args = ['/c', command];
    } else if (Platform.isMacOS) {
      shell = '/bin/zsh';
      args = ['-c', command];
    } else {
      shell = '/bin/bash';
      args = ['-c', command];
    }

    try {
      final result = await Process.run(
        shell,
        args,
      ).timeout(Duration(seconds: timeout));
      envelop.payload = {
        'ok': result.exitCode == 0,
        'exit_code': result.exitCode,
        'stdout': result.stdout.toString(),
        'stderr': result.stderr.toString(),
      };
    } catch (e) {
      envelop.payload = {'ok': false, 'error': e.toString()};
    }
    return envelop;
  }

  static Future<Envelop> _open(
    Envelop envelop,
    Map<String, dynamic> params,
  ) async {
    final target =
        params['target'] as String? ?? params['url'] as String? ?? '';

    if (target.isEmpty) {
      envelop.payload = {'ok': false, 'error': 'Missing target'};
      return envelop;
    }

    try {
      if (Platform.isWindows) {
        await Process.run('start', [target], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [target]);
      } else {
        await Process.run('xdg-open', [target]);
      }
      envelop.payload = {'ok': true, 'target': target};
    } catch (e) {
      envelop.payload = {'ok': false, 'error': e.toString()};
    }
    return envelop;
  }

  static Future<Envelop> _kill(
    Envelop envelop,
    Map<String, dynamic> params,
  ) async {
    final pid = params['pid'] as int?;
    final name = params['name'] as String?;

    try {
      if (pid != null) {
        Process.killPid(pid);
        envelop.payload = {'ok': true, 'pid': pid};
      } else if (name != null) {
        if (Platform.isWindows) {
          await Process.run('taskkill', ['/IM', name, '/F']);
        } else {
          await Process.run('pkill', [name]);
        }
        envelop.payload = {'ok': true, 'name': name};
      } else {
        envelop.payload = {'ok': false, 'error': 'Missing pid or name'};
      }
    } catch (e) {
      envelop.payload = {'ok': false, 'error': e.toString()};
    }
    return envelop;
  }
}
