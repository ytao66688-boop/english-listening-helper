import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_service.dart';
import '../services/vocabulary_service.dart';
import '../services/database_service.dart';
import '../models/word.dart';
import '../widgets/unknown_word_dialog.dart';

class PlayerScreen extends StatefulWidget {
  final String audioId;

  const PlayerScreen({super.key, required this.audioId});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioService _audioService;
  List<Map<String, dynamic>> _transcript = [];
  Map<String, dynamic>? _audioInfo;
  bool _isLoading = true;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  int _currentWordIndex = -1;
  bool _isPausedForUnknownWord = false;
  Timer? _positionTimer;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _loadAudioInfo();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioService.positionStream.listen((position) {
      if (!_isPausedForUnknownWord) {
        setState(() {
          _currentPosition = position;
        });
        _checkCurrentWord();
      }
    });

    _audioService.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioService.onComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    });
  }

  Future<void> _loadAudioInfo() async {
    setState(() => _isLoading = true);

    // 加载音频信息
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'audio_files',
      where: 'id = ?',
      whereArgs: [widget.audioId],
    );

    if (result.isNotEmpty) {
      _audioInfo = result.first;
      
      // 加载转写文本
      final transcriptResult = await db.query(
        'transcripts',
        where: 'audioId = ?',
        whereArgs: [widget.audioId],
        orderBy: 'startTime ASC',
      );

      if (transcriptResult.isNotEmpty) {
        _transcript = transcriptResult;
      } else {
        // 如果没有转写文本，生成模拟数据用于演示
        await _generateMockTranscript();
      }

      // 获取音频时长
      final duration = await _audioService.getDuration();
      if (duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generateMockTranscript() async {
    // 为演示生成模拟转写数据
    // 实际应该使用 Whisper 进行语音识别
    final mockWords = [
      {'word': 'hello', 'start': 0.0, 'end': 0.5},
      {'word': 'this', 'start': 0.6, 'end': 1.0},
      {'word': 'is', 'start': 1.1, 'end': 1.3},
      {'word': 'a', 'start': 1.4, 'end': 1.5},
      {'word': 'test', 'start': 1.6, 'end': 2.0},
      {'word': 'ability', 'start': 2.5, 'end': 3.0},
      {'word': 'conversation', 'start': 3.5, 'end': 4.5},
      {'word': 'about', 'start': 5.0, 'end': 5.3},
      {'word': 'learning', 'start': 5.5, 'end': 6.0},
      {'word': 'english', 'start': 6.2, 'end': 6.8},
    ];

    final db = await DatabaseService.instance.database;
    final batch = db.batch();

    for (var i = 0; i < mockWords.length; i++) {
      final word = mockWords[i];
      final isUnknown = !(await VocabularyService().isWordKnown(word['word'] as String));
      
      batch.insert('transcripts', {
        'audioId': widget.audioId,
        'word': word['word'],
        'startTime': word['start'],
        'endTime': word['end'],
        'isUnknown': isUnknown ? 1 : 0,
      });
    }

    await batch.commit();

    // 重新加载
    final transcriptResult = await db.query(
      'transcripts',
      where: 'audioId = ?',
      whereArgs: [widget.audioId],
      orderBy: 'startTime ASC',
    );

    setState(() {
      _transcript = transcriptResult;
    });

    // 标记为已处理
    await db.update(
      'audio_files',
      {'isProcessed': 1},
      where: 'id = ?',
      whereArgs: [widget.audioId],
    );
  }

  void _checkCurrentWord() {
    if (_transcript.isEmpty || _isPausedForUnknownWord) return;

    final currentSeconds = _currentPosition.inMilliseconds / 1000;
    
    for (int i = 0; i < _transcript.length; i++) {
      final word = _transcript[i];
      final startTime = word['startTime'] as double;
      final endTime = word['endTime'] as double;

      if (currentSeconds >= startTime && currentSeconds <= endTime) {
        if (_currentWordIndex != i) {
          setState(() {
            _currentWordIndex = i;
          });

          // 检查是否是生词
          if (word['isUnknown'] == 1) {
            _handleUnknownWord(word);
          }
        }
        break;
      }
    }
  }

  Future<void> _handleUnknownWord(Map<String, dynamic> transcriptWord) async {
    setState(() {
      _isPausedForUnknownWord = true;
    });

    await _audioService.pause();

    final wordInfo = await VocabularyService().lookupWord(
      transcriptWord['word'] as String,
    );

    if (wordInfo != null && mounted) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => UnknownWordDialog(
          word: wordInfo,
          audioPosition: _currentPosition,
        ),
      );

      // 用户选择是否加入熟词库
      if (result == true) {
        await VocabularyService().markWordAsKnown(wordInfo.id, true);
        
        // 更新转写记录
        final db = await DatabaseService.instance.database;
        await db.update(
          'transcripts',
          {'isUnknown': 0},
          where: 'audioId = ? AND word = ?',
          whereArgs: [widget.audioId, wordInfo.word],
        );
      }
    }

    if (mounted) {
      setState(() {
        _isPausedForUnknownWord = false;
      });
      await _audioService.resume();
    }
  }

  Future<void> _playPause() async {
    if (_audioInfo == null) return;

    if (_isPlaying) {
      await _audioService.pause();
    } else {
      if (_currentPosition == Duration.zero) {
        await _audioService.play(_audioInfo!['filePath']);
      } else {
        await _audioService.resume();
      }
    }
  }

  Future<void> _seek(double value) async {
    final position = Duration(
      milliseconds: (value * _totalDuration.inMilliseconds).toInt(),
    );
    await _audioService.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    await _audioService.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
  }

  @override
  void dispose() {
    _audioService.stop();
    _audioService.dispose();
    _positionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_audioInfo?['fileName'] ?? '播放器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              // 显示完整文本
              _showFullTranscript();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 文本显示区
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildTranscriptDisplay(),
                  ),
                ),

                // 进度条
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Slider(
                        value: _totalDuration.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                            : 0,
                        onChanged: _seek,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_currentPosition)),
                          Text(_formatDuration(_totalDuration)),
                        ],
                      ),
                    ],
                  ),
                ),

                // 控制按钮
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        iconSize: 36,
                        onPressed: () {
                          final newPosition = _currentPosition - const Duration(seconds: 10);
                          _audioService.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
                        },
                      ),
                      const SizedBox(width: 24),
                      FloatingActionButton.large(
                        onPressed: _playPause,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 48,
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        iconSize: 36,
                        onPressed: () {
                          final newPosition = _currentPosition + const Duration(seconds: 10);
                          _audioService.seek(
                            newPosition < _totalDuration ? newPosition : _totalDuration,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 播放速度控制
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('速度:', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('0.5x'),
                        selected: _playbackSpeed == 0.5,
                        onSelected: (_) => _setPlaybackSpeed(0.5),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('0.8x'),
                        selected: _playbackSpeed == 0.8,
                        onSelected: (_) => _setPlaybackSpeed(0.8),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('1.0x'),
                        selected: _playbackSpeed == 1.0,
                        onSelected: (_) => _setPlaybackSpeed(1.0),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('1.2x'),
                        selected: _playbackSpeed == 1.2,
                        onSelected: (_) => _setPlaybackSpeed(1.2),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('1.5x'),
                        selected: _playbackSpeed == 1.5,
                        onSelected: (_) => _setPlaybackSpeed(1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildTranscriptDisplay() {
    if (_transcript.isEmpty) {
      return const Center(child: Text('暂无文本'));
    }

    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _transcript.map((wordData) {
          final index = _transcript.indexOf(wordData);
          final isCurrent = index == _currentWordIndex;
          final isUnknown = wordData['isUnknown'] == 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent
                  ? Colors.blue
                  : isUnknown
                      ? Colors.orange.shade100
                      : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: isUnknown
                  ? Border.all(color: Colors.orange)
                  : null,
            ),
            child: Text(
              wordData['word'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent
                    ? Colors.white
                    : isUnknown
                        ? Colors.orange.shade800
                        : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showFullTranscript() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '完整文本',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _transcript.map((w) => w['word']).join(' '),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}