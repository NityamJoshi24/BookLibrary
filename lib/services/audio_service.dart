import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;

  /* ===================== PERMISSIONS ===================== */

  Future<bool> checkPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /* ===================== RECORDING ===================== */

  Future<void> startRecording(String bookId) async {
    if (_isRecording) return;

    final allowed = await checkPermission();
    if (!allowed) {
      throw Exception('Microphone permission denied');
    }

    await _player.stop();

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;

    // Sanitize bookId so the file name contains only safe characters
    final safeBookId =
        bookId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

    // Use AAC in an .m4a container – this is widely supported by Android's MediaPlayer
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
    print('Recording started: $path');
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;

    // 🔴 VERY IMPORTANT: allow file to flush
    await Future.delayed(const Duration(milliseconds: 300));

    print('Recording stopped: $path');
    return path;
  }

  bool get isRecording => _isRecording;

  /* ===================== PLAYBACK ===================== */

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

      // 🔴 KEY FIX: delay before setting source
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

  /* ===================== DURATION ===================== */

  Future<Duration?> getDuration(String path) async {
    if (_isRecording) return null;

    // Ignore legacy/unsupported formats (e.g. old .wav recordings)
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

  /* ===================== DELETE ===================== */

  Future<void> deleteAudio(String path) async {
    await stop();

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print('Audio deleted: $path');
    }
  }

  /* ===================== CLEANUP ===================== */

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
