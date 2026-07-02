import 'dart:io';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// 平台判断
bool get isAndroid => Platform.isAndroid;
bool get isIOS => Platform.isIOS;
bool get isHarmonyOS {
  final os = Platform.operatingSystem.toLowerCase();
  return os.contains('harmony') || os.contains('ohos');
}

class CameraPlugin {
  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    final params = envelop.payload['params'] as Map<String, dynamic>? ?? {};

    print('📷 相机插件: $action, params: $params');

    // ===== 拍照 =====
    if (action == 'take_photo') {
      try {
        print('📷 检查相机权限...');
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          print('📷 相机权限被拒绝');
          envelop.payload = {'ok': false, 'error': '相机权限被拒绝'};
          return envelop;
        }
        print('📷 相机权限已授予');

        final picker = ImagePicker();
        print('📷 打开相机...');

        final XFile? photo = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 80,
        );

        if (photo != null) {
          print('📷 拍照成功: ${photo.path}');
          envelop.payload = {
            'ok': true,
            'path': photo.path,
            'name': photo.name,
            'size': await photo.length(),
          };
        } else {
          print('📷 用户取消拍照');
          envelop.payload = {'ok': false, 'error': 'User cancelled'};
        }
      } catch (e) {
        print('📷 相机错误: $e');
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    }
    // ===== 相册选择 =====
    else if (action == 'pick_from_gallery') {
      try {
        print('📷 检查图库权限...');
        PermissionStatus galleryStatus;
        if (isHarmonyOS || isIOS) {
          galleryStatus = await Permission.photos.request();
        } else {
          // 安卓先尝试相册权限，失败再走存储
          galleryStatus = await Permission.photos.request();
          if (!galleryStatus.isGranted) {
            galleryStatus = await Permission.storage.request();
          }
        }

        if (!galleryStatus.isGranted) {
          print('📷 图库权限被拒绝');
          envelop.payload = {'ok': false, 'error': '图库权限被拒绝'};
          return envelop;
        }
        print('📷 图库权限已授予');

        final picker = ImagePicker();
        print('📷 打开相册...');

        final XFile? photo = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 80,
        );

        if (photo != null) {
          print('📷 选择成功: ${photo.path}');
          envelop.payload = {
            'ok': true,
            'path': photo.path,
            'name': photo.name,
            'size': await photo.length(),
          };
        } else {
          print('📷 用户取消选择');
          envelop.payload = {'ok': false, 'error': 'User cancelled'};
        }
      } catch (e) {
        print('📷 相册错误: $e');
        envelop.payload = {'ok': false, 'error': e.toString()};
      }
    }
    // ===== 未知 action =====
    else {
      envelop.payload = {'ok': false, 'error': 'Unknown action: $action'};
    }

    return envelop;
  }
}