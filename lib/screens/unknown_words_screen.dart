import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/vocabulary_service.dart';

class UnknownWordsScreen extends StatefulWidget {
  const UnknownWordsScreen({super.key});

  @override
  State<UnknownWordsScreen> createState() => _UnknownWordsScreenState();
}

class _UnknownWordsScreenState extends State<UnknownWordsScreen> {
  List<Word> _unknownWords = [];
  bool _isLoading = true;
  String? _selectedLetter;
  List<String> _letters = [];

  @override
  void initState() {
    super.initState();
    _loadUnknownWords();
    _letters = List.generate(26, (index) => String.fromCharCode(65 + index));
  }

  Future<void> _loadUnknownWords() async {
    setState(() => _isLoading = true);
    
    final words = await VocabularyService().getUnknownWords();
    
    setState(() {
      _unknownWords = words;
      _isLoading = false;
    });
  }

  List<Word> get _filteredWords {
    if (_selectedLetter == null) return _unknownWords;
    return _unknownWords
        .where((w) => w.word.toUpperCase().startsWith(_selectedLetter!))
        .toList();
  }

  Future<void> _markAsKnown(Word word) async {
    await VocabularyService().markWordAsKnown(word.id, true);
    
    setState(() {
      _unknownWords.removeWhere((w) => w.id == word.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${word.word}" 已加入熟词库'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            await VocabularyService().markWordAsKnown(word.id, false);
            _loadUnknownWords();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生词库 Unknown Words'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('统计 Statistics'),
                  content: FutureBuilder<Map<String, int>>(
                    future: VocabularyService().getStatistics(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final stats = snapshot.data!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatRow('总词汇 Total', stats['total'] ?? 0),
                          _buildStatRow('熟词 Known', stats['known'] ?? 0, Colors.green),
                          _buildStatRow('生词 Unknown', stats['unknown'] ?? 0, Colors.orange),
                          const Divider(),
                          Text(
                            '掌握率: ${((stats['known'] ?? 0) / (stats['total'] ?? 1) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              '统计',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 字母筛选
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _letters.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedLetter == null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('全部'),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedLetter = null;
                        });
                      },
                    ),
                  );
                }
                final letter = _letters[index - 1];
                final isSelected = letter == _selectedLetter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(letter),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedLetter = letter;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // 提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '点击"掌握"将单词加入熟词库，听力播放时将不再暂停',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 生词列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '太棒了！没有生词了',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '继续学习，掌握更多词汇！',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredWords.length,
                        itemBuilder: (context, index) {
                          final word = _filteredWords[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                word.word,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word.phonetic,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(word.chineseMeaning),
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () => _markAsKnown(word),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('掌握'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}