import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

class FileSystemPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    print('📁 FileSystem 插件: $action, params: $params');

    try {
      switch (action) {
        case 'read':
          return await _readFile(params);
        case 'write':
          return await _writeFile(params);
        case 'list':
          return await _listFiles(params);
        case 'search':
          return await _searchFiles(params);
        case 'delete':
          return await _deleteFile(params);
        case 'move':
          return await _moveFile(params);
        case 'copy':
          return await _copyFile(params);
        case 'mkdir':
          return await _makeDirectory(params);
        case 'info':
          return await _fileInfo(params);
        case 'exists':
          return await _fileExists(params);
        case 'get_app_dir':
          return await _getAppDirectory(params);
        default:
          envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
          return envelop;
      }
    } catch (e) {
      print('📁 FileSystem 错误: $e');
      envelop.payload = {'ok': false, 'error': e.toString()};
      return envelop;
    }
  }

  // ===== 读取文件 =====
  static Future<Envelop?> _readFile(Map<String, dynamic> params) async {
    final path = params['path'] as String?;
    if (path == null || path.isEmpty) {
      return _errorResponse('文件路径不能为空');
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        return _errorResponse('文件不存在: $path');
      }

      final content = await file.readAsString();
      final size = await file.length();

      return _successResponse({
        'path': path,
        'content': content,
        'size': size,
        'exists': true,
      });
    } catch (e) {
      return _errorResponse('读取文件失败: $e');
    }
  }

  // ===== 写入文件 =====
  static Future<Envelop?> _writeFile(Map<String, dynamic> params) async {
    final path = params['path'] as String?;
    final content = params['content'] as String? ?? '';
    final append = params['append'] as bool? ?? false;

    if (path == null || path.isEmpty) {
      return _errorResponse('文件路径不能为空');
    }

    try {
      final file = File(path);
      await file.parent.create(recursive: true);

      if (append) {
        await file.writeAsString(content, mode: FileMode.append);
      } else {
        await file.writeAsString(content);
      }

      final size = await file.length();

      return _successResponse({
        'path': path,
        'size': size,
        'written': true,
        'append': append,
      });
    } catch (e) {
      return _errorResponse('写入文件失败: $e');
    }
  }

  // ===== 列出文件（默认不递归，限制深度） =====
  static Future<Envelop?> _listFiles(Map<String, dynamic> params) async {
    final path = params['path'] as String?;
    final recursive = params['recursive'] as bool? ?? false;
    final includeHidden = params['includeHidden'] as bool? ?? false;
    final maxDepth = params['maxDepth'] as int? ?? 3;

    if (path == null || path.isEmpty) {
      return _errorResponse('目录路径不能为空');
    }

    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return _errorResponse('目录不存在: $path');
      }

      final files = <Map<String, dynamic>>[];
      await _listDirectory(dir, files, recursive, includeHidden, 0, maxDepth);

      return _successResponse({
        'path': path,
        'count': files.length,
        'files': files,
      });
    } catch (e) {
      return _errorResponse('列出目录失败: $e');
    }
  }

  // ===== 递归列出目录（限制深度和结果数） =====
  static Future<void> _listDirectory(
    Directory dir,
    List<Map<String, dynamic>> files,
    bool recursive,
    bool includeHidden,
    int depth,
    int maxDepth,
  ) async {
    if (depth > maxDepth || files.length > 5000) return;

    try {
      final entities = await dir.list().toList();
      for (final entity in entities) {
        if (files.length > 5000) return;

        final name = entity.path.split('/').last;

        if (!includeHidden && name.startsWith('.')) {
          continue;
        }

        final isDir = entity is Directory;
        FileStat? stat;
        try {
          stat = await entity.stat();
        } catch (e) {
          continue;
        }

        files.add({
          'name': name,
          'path': entity.path,
          'isDirectory': isDir,
          'size': stat?.size ?? 0,
          'modified': stat?.modified.toIso8601String() ?? '',
        });

        if (recursive && isDir && depth < maxDepth) {
          try {
            await _listDirectory(
              entity as Directory,
              files,
              recursive,
              includeHidden,
              depth + 1,
              maxDepth,
            );
          } catch (e) {
            // 子目录权限错误，跳过继续
          }
        }
      }
    } catch (e) {
      // 当前目录权限错误，跳过继续
    }
  }

  // ===== 搜索文件（默认不递归，限制结果） =====
  static Future<Envelop?> _searchFiles(Map<String, dynamic> params) async {
    final path = params['path'] as String?;
    final pattern = params['pattern'] as String? ?? '';
    final recursive = params['recursive'] as bool? ?? false;
    final caseSensitive = params['caseSensitive'] as bool? ?? false;
    final maxDepth = params['maxDepth'] as int? ?? 3;

    if (path == null || path.isEmpty) {
      return _errorResponse('目录路径不能为空');
    }
    if (pattern.isEmpty) {
      return _errorResponse('搜索模式不能为空');
    }

    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return _errorResponse('目录不存在: $path');
      }

      final results = <String>[];
      await _searchDirectory(
        dir,
        pattern,
        results,
        recursive,
        caseSensitive,
        0,
        maxDepth,
      );

      return _successResponse({
        'path': path,
        'pattern': pattern,
        'count': results.length,
        'files': results,
      });
    } catch (e) {
      return _errorResponse('搜索文件失败: $e');
    }
  }

  // ===== 递归搜索（限制深度和结果数） =====
  static Future<void> _searchDirectory(
    Directory dir,
    String pattern,
    List<String> results,
    bool recursive,
    bool caseSensitive,
    int depth,
    int maxDepth,
  ) async {
    if (depth > maxDepth || results.length > 1000) return;

    try {
      final entities = await dir.list().toList();
      for (final entity in entities) {
        if (results.length > 1000) return;

        if (entity is File) {
          final name = entity.path.split('/').last;
          bool match;
          if (caseSensitive) {
            match = name.contains(pattern);
          } else {
            match = name.toLowerCase().contains(pattern.toLowerCase());
          }
          if (match) {
            results.add(entity.path);
          }
        } else if (entity is Directory && recursive && depth < maxDepth) {
          try {
            await _searchDirectory(
              entity,
              pattern,
              results,
              recursive,
              caseSensitive,
              depth + 1,
              maxDepth,
            );
          } catch (e) {
            // 子目录权限错误，跳过继续
          }
        }
      }
    } catch (e) {
      // 当前目录权限错误，跳过继续
    }
  }

  // ===== 删除文件/目录 =====
  static Future<Envelop?> _deleteFile(Map<String, dynamic> params) async {
    final path = params['path'] as String?;
    final recursive = params['recursive'] as bool? ?? false;

    if (path == null || path.isEmpty) {
      return _errorResponse('路径不能为空');
    }

    try {
      final entity =
          FileSystemEntity.isDirectorySync(path)
              ? Directory(path)
              : File(path) as FileSystemEntity;

      if (!await entity.exists()) {
        return _errorResponse('文件或目录不存在: $path');
      }

      if (entity is Directory) {
        await entity.delete(recursive: recursive);
      } else {
        await (entity as File).delete();
      }

      return _successResponse({
        'path': path,
        'deleted': true,
        'recursive': recursive,
      });
    } catch (e) {
      return _errorResponse('删除失败: $e');
    }
  }

  // ===== 移动文件/目录 =====
  static Future<Envelop?> _moveFile(Map<String, dynamic> params) async {
    final from = params['from'] as String?;
    final to = params['to'] as String?;

    if (from == null || from.isEmpty) {
      return _errorResponse('源路径不能为空');
    }
    if (to == null || to.isEmpty) {
      return _errorResponse('目标路径不能为空');
    }

    try {
      final source = File(from);
      if (!await source.exists()) {
        return _errorResponse('源文件不存在: $from');
      }

      final targetFile = File(to);
      await targetFile.parent.create(recursive: true);
      await source.rename(to);

      return _successResponse({'from': from, 'to': to, 'moved': true});
    } catch (e) {
      return _errorResponse('移动失败: $e');
    }
  }

  // ===== 复制文件 =====
  static Future<Envelop?> _copyFile(Map<String, dynamic> params) async {
    final from = params['from'] as String?;
    final to = params['to'] as String?;

    if (from == null || from.isEmpty) {
      return _errorResponse('源路径不能为空');
    }
    if (to == null || to.isEmpty) {
      return _errorResponse('目标路径不能为空');
    }

    try {
      final source = File(from);
      if (!await source.exists()) {
        return _errorResponse('源文件不存在: $from');
      }

      final targetFile = File(to);
      await targetFile.parent.create(recursive: true);
      await source.copy(to);

      return _successResponse({'from': from, 'to': to, 'copied': true});
    } catch (e) {
      return _errorResponse('复制失败: $e');
    }
  }

  // ===== 创建目录 =====
  static Future<Envelop?> _makeDirectory(Map<String, dynamic> params) async {
    final path = params['path'] as String?;
    final recursive = params['recursive'] as bool? ?? true;

    if (path == null || path.isEmpty) {
      return _errorResponse('目录路径不能为空');
    }

    try {
      final dir = Directory(path);
      await dir.create(recursive: recursive);

      return _successResponse({
        'path': path,
        'created': true,
        'recursive': recursive,
      });
    } catch (e) {
      return _errorResponse('创建目录失败: $e');
    }
  }

  // ===== 获取文件信息 =====
  static Future<Envelop?> _fileInfo(Map<String, dynamic> params) async {
    final path = params['path'] as String?;

    if (path == null || path.isEmpty) {
      return _errorResponse('文件路径不能为空');
    }

    try {
      final entity = File(path);
      if (!await entity.exists()) {
        return _errorResponse('文件不存在: $path');
      }

      final stat = await entity.stat();
      final isDir = await entity is Directory;

      return _successResponse({
        'path': path,
        'name': path.split('/').last,
        'isDirectory': isDir,
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
        'exists': true,
      });
    } catch (e) {
      return _errorResponse('获取文件信息失败: $e');
    }
  }

  // ===== 检查文件是否存在 =====
  static Future<Envelop?> _fileExists(Map<String, dynamic> params) async {
    final path = params['path'] as String?;

    if (path == null || path.isEmpty) {
      return _errorResponse('文件路径不能为空');
    }

    try {
      final file = File(path);
      final exists = await file.exists();

      return _successResponse({'path': path, 'exists': exists});
    } catch (e) {
      return _errorResponse('检查文件失败: $e');
    }
  }

  // ===== 获取应用目录 =====
  static Future<Envelop?> _getAppDirectory(Map<String, dynamic> params) async {
    final type = params['type'] as String? ?? 'documents';

    try {
      Directory? dir;
      switch (type) {
        case 'documents':
          dir = await getApplicationDocumentsDirectory();
          break;
        case 'temp':
          dir = await getTemporaryDirectory();
          break;
        case 'support':
          dir = await getApplicationSupportDirectory();
          break;
        case 'external_storage':
          dir = await getExternalStorageDirectory();
          break;
        default:
          dir = await getApplicationDocumentsDirectory();
      }

      return _successResponse({'type': type, 'path': dir?.path ?? ''});
    } catch (e) {
      return _errorResponse('获取目录失败: $e');
    }
  }

  // ===== 辅助方法 =====
  static Envelop _successResponse(Map<String, dynamic> data) {
    final envelop = Envelop(
      receiver: 'mobile/file_system',
      intent: 'API_CALL',
      payload: {'ok': true, ...data},
    );
    return envelop;
  }

  static Envelop _errorResponse(String error) {
    final envelop = Envelop(
      receiver: 'mobile/file_system',
      intent: 'API_CALL',
      payload: {'ok': false, 'error': error},
    );
    return envelop;
  }
}
