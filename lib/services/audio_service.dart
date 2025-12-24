import 'dart:io';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  Timer? _recordingTimer;
  VoidCallback? onRecordingLimitReached;
  static const Duration _maxRecordingDuration = Duration(minutes: 1);



  Future<bool> checkPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }


  Future<void> startRecording(String bookId) async {
    if (_isRecording) return;

    final allowed = await checkPermission();
    if (!allowed) {
      throw Exception('Microphone permission denied');
    }

    await _player.stop();

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;

    final safeBookId =
        bookId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

    final path = '${dir.path}/audio_${safeBookId}_$ts.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: path,
    );

    _isRecording = true;
    _recordingTimer?.cancel();
    _recordingTimer = Timer(_maxRecordingDuration, () async {
      if(_isRecording) {
        await stopRecording();
        onRecordingLimitReached?.call();
      }
    });
    print('Recording started: $path');
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _recordingTimer?.cancel();
    _recordingTimer = null;
    final path = await _recorder.stop();
    _isRecording = false;

    await Future.delayed(const Duration(milliseconds: 300));

    print('Recording stopped: $path');
    return path;
  }

  bool get isRecording => _isRecording;


  Stream<PlayerState> get playerState => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;

  Future<void> play(String path) async {
    if (_isRecording) return;

    // Ignore legacy/unsupported formats (e.g. old .wav recordings)
    if (!path.toLowerCase().endsWith('.m4a')) {
      print('Skipping playback for unsupported format: $path');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      print('Audio file not found: $path');
      return;
    }

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);

      await Future.delayed(const Duration(milliseconds: 200));

      await _player.setSource(DeviceFileSource(path));
      await _player.resume();

      print('Playing audio: $path');
    } catch (e) {
      print('Audio play failed: $e');
    }
  }

  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();
  Future<void> seek(Duration d) async => _player.seek(d);


  Future<Duration?> getDuration(String path) async {
    if (_isRecording) return null;

    if (!path.toLowerCase().endsWith('.m4a')) {
      print('Skipping duration read for unsupported format: $path');
      return null;
    }

    final file = File(path);
    if (!await file.exists()) return null;

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);

      await Future.delayed(const Duration(milliseconds: 200));

      await _player.setSource(DeviceFileSource(path));
      return await _player.getDuration();
    } catch (e) {
      print('Duration read failed: $e');
      return null;
    }
  }


  Future<void> deleteAudio(String path) async {
    await stop();

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print('Audio deleted: $path');
    }
  }


  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
  }
}
