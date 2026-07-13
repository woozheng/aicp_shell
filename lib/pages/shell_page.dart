// lib/pages/shell_page.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:aicp_shell/models/server_config.dart';
import 'package:aicp_shell/pages/settings_page.dart';
import 'package:aicp_shell/core/registry.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/pages/webview_container.dart';
import 'package:aicp_shell/plugins/local_server.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key, this.config});
  final ServerConfig? config;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  ServerConfig? _config;
  String _currentUrl = '';
  String _homeUrl = '';
  int _reloadCounter = 0;
  InAppWebViewController? _webViewController;
  final TextEditingController _urlController = TextEditingController();
  String _lanIp = "";
  bool _loading = true;

  final GlobalKey<WebViewContainerState> _webKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    PluginRegistry.registerAll();
    _initPage();
  }

  Future<void> _initPage() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      await _fetchLanIp();
    } else {
      setState(() => _lanIp = "");
    }
    await _loadConfig();
    setState(() => _loading = false);
  }

  Future<String?> _getLocalLanIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final net in interfaces) {
        for (final addr in net.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('[IP] 获取网卡失败: $e');
    }
    return null;
  }

  Future<void> _fetchLanIp() async {
    final ip = await _getLocalLanIp();
    setState(() => _lanIp = ip ?? "");
    print('[IP] 桌面局域网IP: $_lanIp');
    LocalServer().setLanIp(_lanIp);
  }

  Future<void> _loadConfig() async {
    // 移动端固定本机http服务
    if (Platform.isAndroid || Platform.isIOS) {
      _homeUrl = 'http://127.0.0.1:9999/index.html';
      _currentUrl = _homeUrl;
      _urlController.text = _currentUrl;
      print('🌐 移动端本机地址: $_currentUrl');
      setState(() {
        _config = ServerConfig(mode: "local", url: _homeUrl, token: "");
      });
      return;
    }

    // Linux/WSL 强制内置本地网页，不读取配置、不弹窗跳转设置
    if (Platform.isLinux) {
      _homeUrl = 'http://127.0.0.1:9999/index.html';
      _currentUrl = _homeUrl;
      _urlController.text = _currentUrl;
      setState(() {
        _config = ServerConfig(mode: "local", url: _homeUrl, token: "");
      });
      print('🌐 Linux/WSL 强制本地内置服务');
      return;
    }

    // Windows/macOS 保留原有读取外部配置逻辑
    final config = widget.config ?? await ServerConfig.load();
    if (config == null || config.url.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final goSet = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("未配置网页服务地址"),
                content: const Text("暂无可用服务配置，前往设置填写地址才能加载页面"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("前往设置"),
                  ),
                ],
              ),
        );
        if (goSet == true) {
          _openSettings();
        }
      });
      return;
    }

    setState(() {
      _config = config;
    });

    String rawUrl = config.url.trim();
    final token = config.token;

    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      rawUrl = 'http://$rawUrl';
    }

    try {
      Uri uri = Uri.parse(rawUrl);
      if (token.isNotEmpty) {
        uri = uri.replace(queryParameters: {'token': token});
      }

      _homeUrl = uri.toString();
      _currentUrl = _homeUrl;
      _urlController.text = _currentUrl;
      print('🌐 Windows/macOS 加载外部地址: $_currentUrl');
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("地址格式错误"),
                content: Text("保存的地址解析失败：$e\n请前往设置修正服务地址"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("去设置"),
                  ),
                ],
              ),
        );
        _openSettings();
      });
    }
  }

  Future<void> _navigateTo(String url) async {
    final input = url.trim();
    if (input.isEmpty) return;

    String targetUrl = input;
    if (!targetUrl.startsWith('http://') &&
        !targetUrl.startsWith('https://') &&
        !targetUrl.startsWith('file://')) {
      targetUrl = 'https://$targetUrl';
    }

    await _webKey.currentState?.loadUrl(targetUrl);

    setState(() {
      _currentUrl = targetUrl;
      _urlController.text = targetUrl;
    });
  }

  void _goHome() async {
    if (_homeUrl.isNotEmpty) {
      await _webKey.currentState?.loadUrl(_homeUrl);
      setState(() {
        _currentUrl = _homeUrl;
        _urlController.text = _homeUrl;
      });
    }
  }

  void _handleBridgeMessage(String message) {
    print('📨 Bridge 收到 Envelop');
    try {
      final envelop = Envelop.fromJson(
        jsonDecode(message) as Map<String, dynamic>,
      );

      if (envelop.intent != 'API_CALL') {
        print('⚠️ 未知 intent: ${envelop.intent}');
        return;
      }

      final receiver = envelop.receiver;
      final payload = envelop.payload;
      final callbackId = payload['_callbackId'] as String?;
      final action = payload['action'] as String? ?? '';
      final params = payload['params'] ?? {};

      print('📨 Bridge 调用: $receiver.$action');
      _routeToPlugin(receiver, action, _toMap(params), callbackId);
    } catch (e) {
      print('❌ Bridge 解析错误: $e');
      print('📨 原始消息: $message');
    }
  }

  Map<String, dynamic> _toMap(dynamic params) {
    if (params is Map<String, dynamic>) {
      return params;
    } else if (params is String) {
      return {'value': params};
    } else if (params is List) {
      return {'items': params};
    } else {
      return {};
    }
  }

  void _routeToPlugin(
    String receiver,
    String action,
    Map<String, dynamic> params,
    String? callbackId,
  ) {
    if (!PluginRegistry.has(receiver)) {
      print('❌ 插件未注册: $receiver');
      if (callbackId != null) _sendError(callbackId, '插件未注册: $receiver');
      return;
    }

    final handler = PluginRegistry.get(receiver);
    if (handler == null) {
      if (callbackId != null) _sendError(callbackId, '插件获取失败: $receiver');
      return;
    }

    final envelop = Envelop(
      receiver: receiver,
      intent: 'API_CALL',
      payload: {'action': action, 'params': params, '_callbackId': callbackId},
    );

    _executePlugin(handler, envelop, callbackId);
  }

  void _executePlugin(
    PluginHandler handler,
    Envelop envelop,
    String? callbackId,
  ) {
    final agent = ShellAgent();
    handler(envelop, agent)
        .then((result) {
          print('📤 插件返回: ${result?.payload}');
          if (callbackId != null) {
            _sendResult(callbackId, result?.payload ?? {});
          }
        })
        .catchError((error) {
          if (callbackId != null) _sendError(callbackId, error.toString());
        });
  }

  void _sendResult(String callbackId, dynamic result) {
    final json = jsonEncode({
      'callbackId': callbackId,
      'result': result,
      'error': null,
    });
    _webViewController?.evaluateJavascript(
      source: '''
      (function() {
        var cid = '$callbackId';
        if (window._mobileCallbacks && window._mobileCallbacks[cid]) {
          window._mobileCallbacks[cid].resolve($json);
          delete window._mobileCallbacks[cid];
        }
      })();
    ''',
    );
  }

  void _sendError(String callbackId, String error) {
    final safeError = error.replaceAll("'", "\\'");
    _webViewController?.evaluateJavascript(
      source: '''
      (function() {
        var cid = '$callbackId';
        if (window._mobileCallbacks && window._mobileCallbacks[cid]) {
          window._mobileCallbacks[cid].reject(new Error('$safeError'));
          delete window._mobileCallbacks[cid];
        }
      })();
    ''',
    );
  }

  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (result == true && !Platform.isAndroid && !Platform.isIOS) {
      await _fetchLanIp();
      final config = await ServerConfig.load();
      if (config != null && config.url.isNotEmpty) {
        setState(() {
          _config = config;
          _homeUrl = config.url;
          _currentUrl = _homeUrl;
        });
        await _webKey.currentState?.loadUrl(_homeUrl);
        _urlController.text = _homeUrl;
      }
    }
  }

  void _reload() async {
    await _webKey.currentState?.reload();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _config == null || _currentUrl.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'AICP-OS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  tooltip: "上一页",
                  onPressed: () => _webKey.currentState?.goBack(),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    minimumSize: Size.zero,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  tooltip: "下一页",
                  onPressed: () => _webKey.currentState?.goForward(),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    minimumSize: Size.zero,
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.home, size: 18),
                  tooltip: '回到主页',
                  onPressed: _goHome,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '输入网址...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _reload,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                    onSubmitted: (value) => _navigateTo(value.trim()),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.settings, size: 18),
                  tooltip: '设置',
                  onPressed: _openSettings,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: WebViewContainer(
              key: _webKey,
              url: _currentUrl,
              lanIp: _lanIp,
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onBridgeMessage: (message) => _handleBridgeMessage(message),
              onPageFinished: (url) {
                print('✅ 加载完成: $url');
                if (url != null && url.toString() != _urlController.text) {
                  _urlController.text = url.toString();
                }
              },
              onWebResourceError: (error) => print('❌ 加载错误: $error'),
            ),
          ),
        ],
      ),
    );
  }
}