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

  void setLanIp(String ip) {
    _lanIp = ip;
  }

  String get lanIp => _lanIp ?? "127.0.0.1";

  Future<void> start() async {
    if (_server != null) return;

    final router = Router();

    // 全部改为async异步路由，等待_serveAsset读取资源
    router.get('/', (Request request) async {
      return await _serveAsset('index.html');
    });

    router.get('/index.html', (Request request) async {
      return await _serveAsset('index.html');
    });

    router.get('/finder.html', (Request request) async {
      return await _serveAsset('finder.html');
    });

    router.get('/god_mode.html', (Request request) async {
      return await _serveAsset('god_mode.html');
    });

    router.get('/mobile_bridge.js', (Request request) async {
      return await _serveAsset('mobile_bridge.js', 'application/javascript; charset=utf-8');
    });

    // 文件预览接口（同步读取本地磁盘文件，无需改）
    router.get('/file', (Request request) {
      final path = request.url.queryParameters['path'] ?? '';
      if (path.isEmpty) return Response.badRequest(body: 'Missing path');

      final file = File(path);
      if (!file.existsSync()) return Response.notFound('File not found');

      final ext = path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(ext);

      return Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': mimeType,
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

      final files = dir.listSync().map((f) {
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
        jsonEncode({'ok': true, 'files': files}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    });

    // 404兜底路由（异步）
    router.all('/<ignored|.*>', (Request request) async {
      return Response.notFound('404 - ${request.url.path}');
    });

    // 监听0.0.0.0，本机+局域网均可访问
    _server = await shelf_io.serve(router, '0.0.0.0', port);
    print('🌐 本地HTTP服务启动成功');
    print('   本机访问: http://127.0.0.1:$port');
    print('   局域网访问: http://$lanIp:$port');
  }

  String _getAssetsPath() {
    // 移动端不使用本地文件路径，直接返回空标记
    if (Platform.isAndroid || Platform.isIOS) {
      return "";
    }
    // Windows/macOS/Linux桌面端读取本地assets目录
    final exeDir = File(Platform.resolvedExecutable).parent;
    final dataAssets = Directory('${exeDir.path}/data/flutter_assets/assets');
    if (dataAssets.existsSync()) {
      print('[LocalServer] 📂 桌面加载资源: ${dataAssets.path}');
      return dataAssets.path;
    }

    final exeAssets = Directory('${exeDir.path}/assets');
    if (exeAssets.existsSync()) {
      print('[LocalServer] 📂 exe目录assets');
      return exeAssets.path;
    }

    final devAssets = Directory('assets');
    if (devAssets.existsSync()) {
      print('[LocalServer] 📂 开发环境assets');
      return 'assets';
    }

    print('[LocalServer] ❌ 桌面未找到assets目录');
    return 'assets';
  }

  // 异步读取静态资源：安卓用rootBundle，桌面用File
  Future<Response> _serveAsset(String path, [String? contentType]) async {
    // 安卓/iOS：从apk内置assets读取，不操作本地File
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final byteData = await rootBundle.load("assets/$path");
        final uint8List = byteData.buffer.asUint8List();
        final ext = path.split('.').last.toLowerCase();
        final mimeType = contentType ?? _getMimeType(ext);
        return Response(
          200,
          body: uint8List,
          headers: {
            'Content-Type': mimeType,
            'Content-Length': uint8List.length.toString(),
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'no-cache',
          },
        );
      } catch (e) {
        print('[LocalServer][Mobile] 读取assets失败 $path : $e');
        return Response.notFound('404');
      }
    }

    // 桌面端原有File读取逻辑
    final assetsPath = _getAssetsPath();
    final file = File('$assetsPath/$path');
    print('[LocalServer] 请求静态资源: $path -> ${file.absolute.path}');
    if (!file.existsSync()) {
      print('[LocalServer] ❌ 资源不存在: ${file.absolute.path}');
      return Response.notFound('404 - $path');
    }
    final content = file.readAsBytesSync();
    final ext = path.split('.').last.toLowerCase();
    final mimeType = contentType ?? _getMimeType(ext);
    return Response(
      200,
      body: content,
      headers: {
        'Content-Type': mimeType,
        'Content-Length': content.length.toString(),
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-cache',
      },
    );
  }

  void stop() {
    _server?.close();
    _server = null;
    print('🌐 本地HTTP服务已关闭');
  }

  // 生成文件预览URL，自动区分平台
  String fileUrl(String path) {
    final encodePath = Uri.encodeComponent(path);
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://127.0.0.1:$port/file?path=$encodePath';
    } else {
      return 'http://$lanIp:$port/file?path=$encodePath';
    }
  }

  String _getMimeType(String ext) {
    const mimeTypes = {
      // 视频
      'mp4': 'video/mp4','webm': 'video/webm','mkv': 'video/x-matroska','avi': 'video/x-msvideo','mov': 'video/quicktime','flv': 'video/x-flv','wmv': 'video/x-msvideo','m4v': 'video/x-m4v',
      // 音频
      'mp3': 'audio/mpeg','wav': 'audio/wav','flac': 'audio/flac','aac': 'audio/aac','ogg': 'audio/ogg','wma': 'audio/x-ms-wma','m4a': 'audio/mp4',
      // 图片
      'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','gif':'image/gif','svg':'image/svg+xml','webp':'image/webp','bmp':'image/bmp','ico':'image/x-icon','tiff':'image/tiff','tif':'image/tiff',
      // Office
      'doc': 'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      // 文档
      'pdf':'application/pdf','txt':'text/plain','md':'text/markdown','csv':'text/csv','log':'text/plain',
      // 网页代码
      'html':'text/html; charset=utf-8','htm':'text/html; charset=utf-8','css':'text/css','js':'application/javascript; charset=utf-8','ts':'application/typescript','json':'application/json; charset=utf-8','xml':'application/xml','yaml':'text/yaml','yml':'text/yaml','py':'text/x-python','java':'text/x-java','c':'text/x-c','cpp':'text/x-c++','h':'text/x-c','go':'text/x-go','rs':'text/x-rust','swift':'text/x-swift','kt':'text/x-kotlin','dart':'application/dart','sh':'text/x-shellscript','bat':'text/x-batch','ps1':'text/x-powershell','sql':'text/x-sql',
      // 压缩包
      'zip':'application/zip','rar':'application/x-rar-compressed','7z':'application/x-7z-compressed','tar':'application/x-tar','gz':'application/gzip','bz2':'application/x-bzip2','xz':'application/x-xz',
      // 字体
      'ttf':'font/ttf','otf':'font/otf','woff':'font/woff','woff2':'font/woff2','eot':'application/vnd.ms-fontobject',
      // 可执行程序
      'exe':'application/vnd.microsoft.portable-executable','dll':'application/vnd.microsoft.portable-executable','msi':'application/x-msdownload','apk':'application/vnd.android.package-archive','ipa':'application/octet-stream',
      // 镜像
      'iso':'application/x-iso9660-image','img':'application/octet-stream','dmg':'application/x-apple-diskimage',
      // 数据库
      'db':'application/octet-stream','sqlite':'application/vnd.sqlite3','sqlite3':'application/vnd.sqlite3',
      // 其他
      'torrent':'application/x-bittorrent','psd':'image/vnd.adobe.photoshop','ai':'application/postscript','eps':'application/postscript','sketch':'application/octet-stream','fig':'application/octet-stream','vsd':'application/vnd.visio','vsdx':'application/vnd.visio','epub':'application/epub+zip','mobi':'application/x-mobipocket-ebook',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }
}