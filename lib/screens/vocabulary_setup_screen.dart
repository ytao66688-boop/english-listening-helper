import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/vocabulary_service.dart';
import 'home_screen.dart';

class VocabularySetupScreen extends StatefulWidget {
  const VocabularySetupScreen({super.key});

  @override
  State<VocabularySetupScreen> createState() => _VocabularySetupScreenState();
}

class _VocabularySetupScreenState extends State<VocabularySetupScreen> {
  List<String> _letters = [];
  String? _selectedLetter;
  List<Word> _words = [];
  Map<String, bool> _knownWords = {};
  bool _isLoading = true;
  int _totalKnown = 0;
  int _totalWords = 0;

  @override
  void initState() {
    super.initState();
    _loadLetters();
    _loadStatistics();
  }

  Future<void> _loadLetters() async {
    // A-Z 字母列表
    _letters = List.generate(26, (index) => String.fromCharCode(65 + index));
    if (_letters.isNotEmpty) {
      _selectLetter(_letters[0]);
    }
  }

  Future<void> _loadStatistics() async {
    final stats = await VocabularyService().getStatistics();
    setState(() {
      _totalKnown = stats['known'] ?? 0;
      _totalWords = stats['total'] ?? 0;
    });
  }

  Future<void> _selectLetter(String letter) async {
    setState(() {
      _isLoading = true;
      _selectedLetter = letter;
    });

    final words = await VocabularyService().getWordsByLetter(letter.toLowerCase());
    
    setState(() {
      _words = words;
      for (var word in words) {
        _knownWords[word.id] = word.isKnown;
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleWordKnown(String wordId, bool isKnown) async {
    await VocabularyService().markWordAsKnown(wordId, isKnown);
    setState(() {
      _knownWords[wordId] = isKnown;
      if (isKnown) {
        _totalKnown++;
      } else {
        _totalKnown--;
      }
    });
  }

  void _finishSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择熟词 (Choose Known Words)'),
        actions: [
          TextButton(
            onPressed: _finishSetup,
            child: const Text(
              '完成',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度显示
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '熟词: $_totalKnown / $_totalWords',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '进度: ${(_totalKnown / (_totalWords > 0 ? _totalWords : 1) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // 字母导航
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _letters.length,
              itemBuilder: (context, index) {
                final letter = _letters[index];
                final isSelected = letter == _selectedLetter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(letter),
                    selected: isSelected,
                    onSelected: (_) => _selectLetter(letter),
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),

          // 说明文字
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '点击单词标记为"已掌握"（绿色 = 已掌握，白色 = 生词）',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // 单词列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _words.isEmpty
                    ? const Center(child: Text('该字母下暂无单词'))
                    : ListView.builder(
                        itemCount: _words.length,
                        itemBuilder: (context, index) {
                          final word = _words[index];
                          final isKnown = _knownWords[word.id] ?? false;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            color: isKnown ? Colors.green.shade50 : Colors.white,
                            child: ListTile(
                              title: Text(
                                word.word,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isKnown ? Colors.green.shade800 : Colors.black,
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
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    word.chineseMeaning,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              trailing: Checkbox(
                                value: isKnown,
                                onChanged: (value) {
                                  _toggleWordKnown(word.id, value ?? false);
                                },
                                activeColor: Colors.green,
                              ),
                              onTap: () {
                                _toggleWordKnown(word.id, !isKnown);
                              },
                            ),
                          );
                        },
                      ),
          ),

          // 底部提示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Text(
                    '提示：可以分批完成，以后随时可以回来继续标记',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishSetup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('进入应用'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}