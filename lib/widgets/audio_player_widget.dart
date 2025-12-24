import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:book_library/services/audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final AudioService audioService;
  final VoidCallback? onDelete;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    required this.audioService,
    this.onDelete,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _validateFile();
    _loadDuration();
    _listenPlayerState();
    _listenPosition();
  }

  Future<void> _validateFile() async {
    final file = File(widget.audioPath);
    if (!await file.exists()) {
      widget.onDelete?.call();
    }
  }

  Future<void> _loadDuration() async {
    final d = await widget.audioService.getDuration(widget.audioPath);
    if (mounted && d != null) {
      setState(() => duration = d);
    }
  }

  void _listenPlayerState() {
    widget.audioService.playerState.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });
  }

  void _listenPosition() {
    widget.audioService.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        position = pos;
      });
    });
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await widget.audioService.pause();
    } else {
      await widget.audioService.play(widget.audioPath);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = duration.inSeconds > 0 ? duration.inSeconds : 1;
    final sliderValue =
    position.inSeconds.clamp(0, maxSeconds).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.audiotrack, color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration ${_fmt(duration)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 40,
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _confirmDelete,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Slider(
              value: sliderValue,
              max: maxSeconds.toDouble(),
              onChanged: (v) {
                widget.audioService.seek(
                  Duration(seconds: v.toInt()),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(position),
                      style: const TextStyle(fontSize: 12)),
                  Text(_fmt(duration),
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Audio Note'),
        content:
        const Text('Are you sure you want to delete this audio note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.audioService.stop();
    super.dispose();
  }
}
