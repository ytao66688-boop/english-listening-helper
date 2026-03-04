import 'package:flutter/material.dart';
import '../services/vocabulary_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isFirstLaunch = true;
  bool _isVocabularyInitialized = false;
  bool _isLoading = true;

  bool get isFirstLaunch => _isFirstLaunch;
  bool get isVocabularyInitialized => _isVocabularyInitialized;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // 初始化词汇库
    await VocabularyService().initializeVocabulary();
    _isVocabularyInitialized = true;

    // 检查是否是首次启动（这里简化处理，实际应该用SharedPreferences）
    // TODO: 从SharedPreferences读取
    _isFirstLaunch = true;

    _isLoading = false;
    notifyListeners();
  }

  void setFirstLaunchComplete() {
    _isFirstLaunch = false;
    notifyListeners();
  }
}