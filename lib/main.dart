import 'dart:io';
import 'package:flutter/material.dart';
import 'package:aicp_shell/models/server_config.dart';
import 'package:aicp_shell/pages/settings_page.dart';
import 'package:aicp_shell/pages/shell_page.dart';
import 'package:aicp_shell/plugins/local_server.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 仅桌面执行窗口逻辑
  if (!Platform.isAndroid && !Platform.isIOS) {
    await windowManager.ensureInitialized();
    // WindowOptions 仅配置基础尺寸居中，无maximize参数
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      // 单独调用最大化方法
      await windowManager.maximize();
    });
  }

  await LocalServer().start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AICP Mobile Shell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

// SplashPage 代码不变，沿用你原有代码
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkConfig();
  }

  Future<void> _checkConfig() async {
    final config = await ServerConfig.load();

    if (Platform.isAndroid || Platform.isIOS) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShellPage()),
        );
      }
      return;
    }

    if (config != null && config.url.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ShellPage(config: config)),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}