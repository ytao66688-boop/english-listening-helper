import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/word.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 播放状态
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  
  // 当前位置
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  
  // 播放完成
  Stream<void> get onComplete => _audioPlayer.onPlayerComplete;
  
  // 播放状态变化
  Stream<PlayerState> get onPlayerStateChanged => _audioPlayer.onPlayerStateChanged;

  Future<void> play(String filePath) async {
    await _audioPlayer.play(DeviceFileSource(filePath));
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<Duration?> getDuration() async {
    return await _audioPlayer.getDuration();
  }

  Future<Duration> getCurrentPosition() async {
    return await _audioPlayer.getCurrentPosition() ?? Duration.zero;
  }

  // 设置播放速度 (0.5 - 2.0)
  Future<void> setPlaybackSpeed(double speed) async {
    await _audioPlayer.setPlaybackRate(speed);
  }

  // 选择音频文件
  Future<FilePickerResult?> pickAudioFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'aac'],
    );
  }

  // 保存音频文件到应用目录
  Future<String?> saveAudioFile(String sourcePath, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio_files');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final destPath = path.join(audioDir.path, fileName);
      final sourceFile = File(sourcePath);
      
      if (await sourceFile.exists()) {
        await sourceFile.copy(destPath);
        return destPath;
      }
    } catch (e) {
      print('Error saving audio file: $e');
    }
    return null;
  }

  // 删除音频文件
  Future<void> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting audio file: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

