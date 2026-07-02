// lib/core/route.dart
// 对应 Python core.py 的 async def route()

import 'dart:async';  // ← 加这个导入
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:aicp_shell/core/registry.dart';

/// 路由分发器
class RouteDispatcher  {
  /// 路由执行
  /// 对应 Python 的 async def route(envelop, agent, timeout)
  static Future<Envelop?> route(
    Envelop envelop, {
    ShellAgent? agent,
    Duration timeout = const Duration(seconds: 300),
  }) async {
    // 检查 receiver
    if (envelop.receiver.isEmpty) {
      envelop.payload = {'error': 'Missing receiver'};
      return envelop;
    }

    // 检查 TTL
    if (envelop.ttl <= 0) {
      envelop.payload = {'error': 'TTL expired'};
      return envelop;
    }

    // TTL - 1
    envelop.ttl -= 1;

    // 查找插件
    final handler = PluginRegistry.get(envelop.receiver);
    if (handler == null) {
      envelop.payload = {
        'error': 'Plugin not found: ${envelop.receiver}',
        'available_plugins': PluginRegistry.list(),
      };
      return envelop;
    }

    // 如果 agent 为空，创建默认 Agent
    final effectiveAgent = agent ?? ShellAgent();

    try {
      // 执行插件，带超时
      final result = await handler(envelop, effectiveAgent).timeout(timeout);
      return result;
    } on TimeoutException catch (_) {
      // ← 这里用 on TimeoutException catch (_)
      envelop.payload = {'error': 'Plugin timeout after ${timeout.inSeconds}s'};
      return envelop;
    } catch (e) {
      final errorMsg = e.toString();
      envelop.payload = {
        'error': 'Plugin execution error: ${errorMsg.substring(0, errorMsg.length > 200 ? 200 : errorMsg.length)}',
      };
      return envelop;
    }
  }
}