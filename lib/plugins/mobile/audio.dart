// lib/plugins/mobile/audio.dart
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aicp_shell/core/envelop.dart';
import 'package:aicp_shell/core/agent.dart';

bool get isHarmonyOS {
  final os = Platform.operatingSystem.toLowerCase();
  return os.contains('harmony') || os.contains('ohos');
}

class AudioPlugin {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static final FlutterSoundPlayer _player = FlutterSoundPlayer();
  static String? _currentRecordPath;
  static bool _isRecording = false;
  static bool _isPlaying = false;

  static Future<Envelop?> execute(Envelop envelop, ShellAgent agent) async {
    final action = envelop.payload['action'] ?? '';
    final Map<String, dynamic> params = envelop.payload;

    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        envelop.payload = {'ok': false, 'error': '麦克风权限被拒绝'};
        return envelop;
      }

      switch (action) {
        case 'record_start':
          return await _recordStart(envelop, params);
        case 'record_stop':
          return await _recordStop(envelop);
        case 'play':
          return await _playAudio(envelop, params);
        case 'stop_play':
          return await _stopPlay(envelop);
        case 'set_volume':
          final double vol = (params['volume'] ?? 0.5).clamp(0.0, 1.0);
          if (!_player.isOpen()) await _player.openPlayer();
          await _player.setVolume(vol);
          envelop.payload = {'ok': true, 'volume': vol, 'hint': 'flutter_sound不支持读取当前音量'};
          break;
        default:
          envelop.payload = {'ok': false, 'error': 'Unknown audio action: $action'};
      }
    } catch (e) {
      envelop.payload = {'ok': false, 'error': e.toString()};
    }
    return envelop;
  }

  static Future<Envelop> _recordStart(Envelop envelop, Map<String, dynamic> params) async {
    if (_isRecording) {
      envelop.payload = {'ok': false, 'error': '正在录音，请勿重复开启'};
      return envelop;
    }
    final String path = params['path'] ?? '/tmp/aicp_record.aac';
    await _recorder.openRecorder();
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
    );
    _isRecording = true;
    _currentRecordPath = path;
    envelop.payload = {
      'ok': true,
      'path': path,
      'status': 'recording'
    };
    return envelop;
  }

  static Future<Envelop> _recordStop(Envelop envelop) async {
    if (!_isRecording || _currentRecordPath == null) {
      envelop.payload = {'ok': false, 'error': '当前无录音任务'};
      return envelop;
    }
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    _isRecording = false;
    final audioFile = File(_currentRecordPath!);
    final int fileSize = audioFile.existsSync() ? await audioFile.length() : 0;
    envelop.payload = {
      'ok': true,
      'path': _currentRecordPath,
      'size': fileSize,
      'status': 'stopped'
    };
    _currentRecordPath = null;
    return envelop;
  }

  static Future<Envelop> _playAudio(Envelop envelop, Map<String, dynamic> params) async {
    final String path = params['path'] ?? '';
    if (path.isEmpty) {
      envelop.payload = {'ok': false, 'error': '音频文件路径不能为空'};
      return envelop;
    }
    if (!File(path).existsSync()) {
      envelop.payload = {'ok': false, 'error': '文件不存在：$path'};
      return envelop;
    }
    if (!_player.isOpen()) await _player.openPlayer();
    await _player.startPlayer(
      fromURI: path,
      whenFinished: () {
        _isPlaying = false;
      },
    );
    _isPlaying = true;
    envelop.payload = {'ok': true, 'path': path, 'status': 'playing'};
    return envelop;
  }

  static Future<Envelop> _stopPlay(Envelop envelop) async {
    if (!_isPlaying) {
      envelop.payload = {'ok': false, 'error': '当前无音频播放'};
      return envelop;
    }
    await _player.stopPlayer();
    await _player.closePlayer();
    _isPlaying = false;
    envelop.payload = {'ok': true, 'status': 'stopped'};
    return envelop;
  }
}