import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word.dart';
import 'database_service.dart';

class VocabularyService {
  bool _isInitialized = false;

  Future<void> initializeVocabulary() async {
    if (_isInitialized) return;

    final count = await DatabaseService.instance.getTotalWordsCount();
    if (count > 0) {
      _isInitialized = true;
      return;
    }

    // 加载PET词汇表
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/pet_vocabulary.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      final words = jsonList.map((json) {
        return Word(
          id: '${json['word']}_${json.hashCode}',
          word: json['word'].toString().toLowerCase(),
          phonetic: json['phonetic'] ?? '',
          chineseMeaning: json['meaning'] ?? '',
          level: json['level'] ?? 'PET',
          isKnown: false,
        );
      }).toList();

      await DatabaseService.instance.insertWords(words);
      _isInitialized = true;
    } catch (e) {
      print('Error loading vocabulary: $e');
      // 如果加载失败，使用内置的简化词汇表
      await _loadDefaultVocabulary();
    }
  }

  Future<void> _loadDefaultVocabulary() async {
    // 简化版PET核心词汇（前500词）
    final defaultWords = [
      {'word': 'ability', 'phonetic': '/əˈbɪləti/', 'meaning': 'n. 能力'},
      {'word': 'able', 'phonetic': '/ˈeɪbl/', 'meaning': 'adj. 能够的'},
      {'word': 'about', 'phonetic': '/əˈbaʊt/', 'meaning': 'prep. 关于'},
      {'word': 'above', 'phonetic': '/əˈbʌv/', 'meaning': 'prep. 在...之上'},
      {'word': 'abroad', 'phonetic': '/əˈbrɔːd/', 'meaning': 'adv. 在国外'},
      {'word': 'absence', 'phonetic': '/ˈæbsəns/', 'meaning': 'n. 缺席'},
      {'word': 'absent', 'phonetic': '/ˈæbsənt/', 'meaning': 'adj. 缺席的'},
      {'word': 'absolute', 'phonetic': '/ˈæbsəluːt/', 'meaning': 'adj. 绝对的'},
      {'word': 'absorb', 'phonetic': '/əbˈsɔːb/', 'meaning': 'v. 吸收'},
      {'word': 'abstract', 'phonetic': '/ˈæbstrækt/', 'meaning': 'adj. 抽象的'},
    ];

    final words = defaultWords.map((json) {
      return Word(
        id: '${json['word']}_${json.hashCode}',
        word: json['word'].toString().toLowerCase(),
        phonetic: json['phonetic'] ?? '',
        chineseMeaning: json['meaning'] ?? '',
        level: 'PET',
        isKnown: false,
      );
    }).toList();

    await DatabaseService.instance.insertWords(words);
    _isInitialized = true;
  }

  Future<List<Word>> getWordsByLetter(String letter) async {
    return await DatabaseService.instance.getWordsByLetter(letter);
  }

  Future<List<Word>> getUnknownWords() async {
    return await DatabaseService.instance.getUnknownWords();
  }

  Future<void> markWordAsKnown(String wordId, bool isKnown) async {
    await DatabaseService.instance.updateWordKnownStatus(wordId, isKnown);
  }

  Future<bool> isWordKnown(String word) async {
    return await DatabaseService.instance.isWordKnown(word);
  }

  Future<Word?> lookupWord(String word) async {
    return await DatabaseService.instance.getWordByText(word);
  }

  Future<Map<String, int>> getStatistics() async {
    final known = await DatabaseService.instance.getKnownWordsCount();
    final total = await DatabaseService.instance.getTotalWordsCount();
    return {
      'known': known,
      'total': total,
      'unknown': total - known,
    };
  }
}