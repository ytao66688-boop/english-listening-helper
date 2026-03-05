import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';
import '../models/word.dart';
import 'player_screen.dart';
import 'unknown_words_screen.dart';
import 'vocabulary_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _audioFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  Future<void> _loadAudioFiles() async {
    setState(() => _isLoading = true);
    
    final db = await DatabaseService.instance.database;
    final files = await db.query(
      'audio_files',
      orderBy: 'createdAt DESC',
    );
    
    setState(() {
      _audioFiles = files;
      _isLoading = false;
    });
  }

  Future<void> _uploadAudio() async {
    final audioService = context.read<AudioService>();
    final result = await audioService.pickAudioFile();
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('正在处理音频...'),
              ],
            ),
          ),
        );

        try {
          final fileName = file.name;
          final savedPath = await audioService.saveAudioFile(
            file.path!,
            fileName,
          );

          if (savedPath != null) {
            // 保存到数据库
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            final db = await DatabaseService.instance.database;
            await db.insert('audio_files', {
              'id': id,
              'fileName': fileName,
              'filePath': savedPath,
              'duration': 0, // TODO: 获取实际时长
              'createdAt': DateTime.now().toIso8601String(),
              'isProcessed': 0,
            });

            Navigator.of(context).pop(); // 关闭加载对话框
            
            // 跳转到播放器进行语音识别
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlayerScreen(audioId: id),
              ),
            ).then((_) => _loadAudioFiles());
          }
        } catch (e) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAudio(String id, String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 删除文件
      await context.read<AudioService>().deleteAudioFile(filePath);
      
      // 删除数据库记录
      final db = await DatabaseService.instance.database;
      await db.delete('audio_files', where: 'id = ?', whereArgs: [id]);
      await db.delete('transcripts', where: 'audioId = ?', whereArgs: [id]);
      await db.delete('study_records', where: 'audioId = ?', whereArgs: [id]);

      _loadAudioFiles();
    }
  }

  void _openPlayer(String audioId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(audioId: audioId),
      ),
    ).then((_) => _loadAudioFiles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('英语听力助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UnknownWordsScreen(),
                ),
              );
            },
            tooltip: '生词库',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VocabularySetupScreen(),
                ),
              );
            },
            tooltip: '熟词设置',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _audioFiles.isEmpty
              ? _buildEmptyState()
              : _buildAudioList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadAudio,
        icon: const Icon(Icons.upload_file),
        label: const Text('上传音频'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audio_file,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有音频文件',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角上传MP3或M4A文件',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _audioFiles.length,
      itemBuilder: (context, index) {
        final audio = _audioFiles[index];
        final isProcessed = audio['isProcessed'] == 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isProcessed ? Colors.green : Colors.orange,
              child: Icon(
                isProcessed ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
            ),
            title: Text(
              audio['fileName'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              isProcessed ? '已处理' : '未处理',
              style: TextStyle(
                color: isProcessed ? Colors.green : Colors.orange,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAudio(
                audio['id'],
                audio['filePath'],
              ),
            ),
            onTap: () => _openPlayer(audio['id']),
          ),
        );
      },
    );
  }
}