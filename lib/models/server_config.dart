import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aicp_shell/config/app_config.dart';

class ServerConfig {
  String mode;
  String url;
  String token;

  ServerConfig({required this.mode, required this.url, this.token = ''});

  Map<String, dynamic> toJson() => {'mode': mode, 'url': url, 'token': token};

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
    mode: json['mode'] ?? 'local',
    url: json['url'] ?? '',
    token: json['token'] ?? '',
  );

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.kStorageKey, jsonEncode(toJson()));
  }

  static Future<ServerConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConfig.kStorageKey);
    if (data == null || data.isEmpty) return null;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return ServerConfig.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// 获取页面 URL
  ///
  /// 规则：
  /// - 如果地址以 .html 或 .htm 结尾 → 直接返回（用户指定了完整路径）
  /// - 否则 → 自动补 /mobile/index.html
  String get pageUrl {
    final trimmed = url.trim();

    // 如果已经以 .html 或 .htm 结尾，直接返回
    if (trimmed.endsWith('.html') || trimmed.endsWith('.htm')) {
      return trimmed;
    }

    // 如果以 http:// 或 https:// 开头，直接返回（不拼接）
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // 其他情况才拼接 /mobile/index.html
    var base = trimmed;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return '$base/mobile/index.html';
  }

  @override
  String toString() =>
      'ServerConfig(mode: $mode, url: $url, token: ${token.isNotEmpty ? '***' : '空'})';
}
