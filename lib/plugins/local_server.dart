// lib/plugins/local_server.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class LocalServer {
  static final LocalServer _instance = LocalServer._();
  factory LocalServer() => _instance;
  LocalServer._();

  HttpServer? _server;
  final int port = 9999;
  String? _lanIp;
  late String _webRoot;

  void setLanIp(String ip) => _lanIp = ip;
  String get lanIp => _lanIp ?? "127.0.0.1";

  Future<void> _initWebDir() async {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    _webRoot = "$exeDir/web";
    final webDir = Directory(_webRoot);
    if (!await webDir.exists()) await webDir.create(recursive: true);

    final List<String> assetList = [
      "index.html",
      "finder.html",
      "god_mode.html",
      "mobile_bridge.js"
    ];

    for (final fileName in assetList) {
      final byteData = await rootBundle.load("assets/$fileName");
      final targetFile = File("$_webRoot/$fileName");
      await targetFile.writeAsBytes(byteData.buffer.asUint8List());
    }
    print("[WEB资源] 静态页面解压至: $_webRoot");
  }

  Future<void> start() async {
    if (_server != null) return;
    await _initWebDir();

    final router = Router();
    router.get('/', (req) => _serveStaticFile('index.html'));
    router.get('/index.html', (req) => _serveStaticFile('index.html'));
    router.get('/finder.html', (req) => _serveStaticFile('finder.html'));
    router.get('/god_mode.html', (req) => _serveStaticFile('god_mode.html'));
    router.get('/mobile_bridge.js', (req) => _serveStaticFile('mobile_bridge.js', 'application/javascript; charset=utf-8'));

    router.get('/file', (Request request) {
      final path = request.url.queryParameters['path'] ?? '';
      if (path.isEmpty) return Response.badRequest(body: 'Missing path');
      final file = File(path);
      if (!file.existsSync()) return Response.notFound('File not found');
      final ext = path.split('.').last.toLowerCase();
      final mime = _getMimeType(ext);
      return Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': mime,
          'Accept-Ranges': 'bytes',
          'Access-Control-Allow-Origin': '*',
        },
      );
    });

    router.get('/file/list', (Request request) async {
      final path = request.url.queryParameters['path'] ?? '';
      if (path.isEmpty) return Response.badRequest(body: 'Missing path');
      final dir = Directory(path);
      if (!dir.existsSync()) return Response.notFound('Directory not found');
      final fileList = dir.listSync().map((f) {
        final stat = f.statSync();
        return {
          'name': f.path.split(Platform.pathSeparator).last,
          'path': f.path,
          'isDirectory': f is Directory,
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        };
      }).toList();
      return Response.ok(
        jsonEncode({'ok': true, 'files': fileList}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    });

    router.all('/<ignored|.*>', (req) async => Response.notFound("404 Not Found ${req.url.path}"));
    _server = await shelf_io.serve(router, '0.0.0.0', port);
    print('🌐 HTTP服务启动完成');
    print('本机访问: http://127.0.0.1:$port');
    print('局域网访问: http://$lanIp:$port');
  }

  Future<Response> _serveStaticFile(String fileName, [String? contentType]) async {
    final targetFile = File("$_webRoot/$fileName");
    if (!await targetFile.exists()) {
      print("[404] 静态文件不存在: ${targetFile.path}");
      return Response.notFound("404 $fileName");
    }
    final bytes = await targetFile.readAsBytes();
    final ext = fileName.split('.').last.toLowerCase();
    final mime = contentType ?? _getMimeType(ext);
    return Response(
      200,
      body: bytes,
      headers: {
        "Content-Type": mime,
        "Content-Length": bytes.length.toString(),
        "Access-Control-Allow-Origin": "*",
        "Cache-Control": "no-cache"
      },
    );
  }

  void stop() {
    _server?.close();
    _server = null;
    print("🌐 HTTP服务已关闭");
  }

  String fileUrl(String path) {
    final encodePath = Uri.encodeComponent(path);
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://127.0.0.1:$port/file?path=$encodePath';
    } else {
      return 'http://$lanIp:$port/file?path=$encodePath';
    }
  }

  String _getMimeType(String ext) {
    const mimeMap = {
      "html": "text/html; charset=utf-8",
      "htm": "text/html; charset=utf-8",
      "js": "application/javascript; charset=utf-8",
      "css": "text/css; charset=utf-8",
      "json": "application/json; charset=utf-8",
      "png": "image/png",
      "jpg": "image/jpeg",
      "jpeg": "image/jpeg",
      "gif": "image/gif",
      "svg": "image/svg+xml",
      "mp4": "video/mp4",
      "mp3": "audio/mpeg",
      "txt": "text/plain; charset=utf-8"
    };
    return mimeMap[ext] ?? "application/octet-stream";
  }
}