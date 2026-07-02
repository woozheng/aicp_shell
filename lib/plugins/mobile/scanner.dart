// lib/plugins/mobile/scanner.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

class ScannerPlugin {
  static MobileScannerController? _controller;
  static Completer<Map<String, dynamic>?>? _completer;

  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    final Map<String, dynamic> params = envelop.payload;

    try {
      switch (action) {
        case 'scan':
          // 相机权限校验
          final camPerm = await Permission.camera.request();
          if (!camPerm.isGranted) {
            envelop.payload = {'ok': false, 'error': '相机权限被拒绝'};
            return envelop;
          }

          _completer = Completer<Map<String, dynamic>?>();
          _controller = MobileScannerController();

          // 监听扫码识别
          _controller!.barcodes.listen((BarcodeCapture capture) {
            if (capture.barcodes.isNotEmpty && _completer != null && !_completer!.isCompleted) {
              final barcode = capture.barcodes.first;
              final scanResult = {
                'ok': true,
                'text': barcode.rawValue ?? '',
                'format': barcode.format.name,
              };
              _completer!.complete(scanResult);
              _controller?.stop();
            }
          });

          // 弹出扫码弹窗等待结果
          final dialogResult = await _showScannerDialog(agent);
          final scanData = await _completer!.future;

          // 释放资源
          await _controller?.dispose();
          _controller = null;
          _completer = null;

          if (scanData != null) {
            envelop.payload = scanData;
          } else {
            envelop.payload = {'ok': false, 'error': '用户取消扫码'};
          }
          break;

        default:
          envelop.payload = {'ok': false, 'error': 'Unknown scanner action: $action'};
      }
    } catch (e) {
      // 异常兜底释放相机
      await _controller?.dispose();
      _controller = null;
      _completer = null;
      envelop.payload = {'ok': false, 'error': e.toString()};
    }
    return envelop;
  }

  static Future<Map<String, dynamic>?> _showScannerDialog(ShellAgent agent) async {
    final BuildContext? ctx = agent.get('context') as BuildContext?;
    if (ctx == null) {
      _completer?.complete({'ok': false, 'error': 'UI上下文获取失败'});
      return null;
    }

    return showDialog<Map<String, dynamic>?>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: SizedBox.expand(
            child: Stack(
              children: [
                MobileScanner(controller: _controller!),
                // 关闭按钮
                Positioned(
                  top: 32,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () {
                      if (_completer != null && !_completer!.isCompleted) {
                        _completer!.complete(null);
                      }
                      Navigator.pop(dialogCtx, null);
                    },
                  ),
                ),
                // 扫描框
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}