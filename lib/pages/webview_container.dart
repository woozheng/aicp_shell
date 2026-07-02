import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';

class WebViewContainer extends StatefulWidget {
  const WebViewContainer({
    super.key,
    required this.url,
    this.onPageFinished,
    this.onPageStarted,
    this.onWebResourceError,
    this.onBridgeMessage,
    this.onWebViewCreated,
    this.lanIp = '',
  });

  final String url;
  final String lanIp;
  final void Function(String)? onPageStarted;
  final void Function(String)? onPageFinished;
  final void Function(Object)? onWebResourceError;
  final void Function(String)? onBridgeMessage;
  final void Function(InAppWebViewController)? onWebViewCreated;

  @override
  State<WebViewContainer> createState() => WebViewContainerState();
}

class WebViewContainerState extends State<WebViewContainer> {
  late InAppWebViewController _controller;
  bool _isInitialized = false;
  Offset? _dragPointer;
  // 新增在 _injectMobileBridge 上方即可
  Future<void> goBack() async {
    if (_isInitialized && await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> goForward() async {
    if (_isInitialized && await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  Future<void> loadUrl(String targetUrl) async {
    if (!_isInitialized) return;
    await _controller.loadUrl(urlRequest: URLRequest(url: WebUri(targetUrl)));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      // 捕获鼠标滚轮+拖拽手势，转发给网页JS实现滚动
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) async {
          // 鼠标滚轮滚动
          if (event is PointerScrollEvent && _isInitialized) {
            double scrollDelta = -event.scrollDelta.dy * 0.8;
            await _controller.evaluateJavascript(
              source: "window.scrollBy(0, $scrollDelta);",
            );
          }
        },
        onPointerDown: (PointerDownEvent event) {
          // 左键按下，记录拖拽起点
          if (event.buttons == kPrimaryMouseButton) {
            _dragPointer = event.localPosition;
          }
        },
        onPointerMove: (PointerMoveEvent event) async {
          // 鼠标按住拖拽滑动页面
          if (_dragPointer != null &&
              event.buttons == kPrimaryMouseButton &&
              _isInitialized) {
            double dyDiff = event.localPosition.dy - _dragPointer!.dy;
            _dragPointer = event.localPosition;
            await _controller.evaluateJavascript(
              source: "window.scrollBy(0, ${-dyDiff});",
            );
          }
        },
        onPointerUp: (_) => _dragPointer = null,
        child: InAppWebView(
          initialSettings: InAppWebViewSettings(
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            javaScriptEnabled: true,
            domStorageEnabled: true,
            javaScriptCanOpenWindowsAutomatically: true,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            supportZoom: true,
          ),
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          onWebViewCreated: (controller) async {
            _controller = controller;
            setState(() => _isInitialized = true);
            print('🔧 WebView 创建完成');

            final ipStr = widget.lanIp.replaceAll("'", "\\'");
            await controller.evaluateJavascript(
              source: "window.lanIp='$ipStr';",
            );

            if (widget.onWebViewCreated != null) {
              widget.onWebViewCreated!(controller);
            }
            controller.addJavaScriptHandler(
              handlerName: 'flutterBridge',
              callback: (arguments) {
                final message =
                    arguments.isNotEmpty ? arguments[0] as String? : '';
                if (message != null && widget.onBridgeMessage != null) {
                  widget.onBridgeMessage!(message);
                }
                return {'ok': true};
              },
            );
          },
          onLoadStart: (controller, url) {
            if (widget.onPageStarted != null) {
              widget.onPageStarted!(url?.toString() ?? '');
            }
          },
          onLoadStop: (controller, url) async {
            if (widget.onPageFinished != null) {
              widget.onPageFinished!(url?.toString() ?? '');
            }
            // 强制解锁网页滚动，覆盖所有页面overflow:hidden限制
            final fixScrollJs = """
Object.defineProperty(navigator, 'mediaDevices', {
  value: {
    getUserMedia: function(){return Promise.reject(new Error('media blocked'));},
    enumerateDevices: function(){return Promise.resolve([]);}
  },
  writable: false
});
document.documentElement.style.overflow = 'auto';
document.body.style.overflow = 'auto';
document.documentElement.style.height = 'auto !important';
document.body.style.height = 'auto !important';
html{height:auto !important;}
            """;
            await controller.evaluateJavascript(source: fixScrollJs);
            await _injectMobileBridge();
          },
          onLoadError: (controller, url, code, message) {
            if (widget.onWebResourceError != null) {
              widget.onWebResourceError!(message);
            }
          },
        ),
      ),
    );
  }

  Future<void> _injectMobileBridge() async {
    try {
      final js = await rootBundle.loadString('assets/mobile_bridge.js');
      await _controller.evaluateJavascript(source: js);
    } catch (e) {
      print('[WebView] 注入bridge失败: $e');
    }
  }

  Future<void> reload() async {
    if (!_isInitialized) return;
    await _controller.reload();
  }
}
