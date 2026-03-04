# 英语听力助手

基于 i+1 可理解性输入理论的英语听力学习 App。

## 功能特性

1. **熟词库初始化** - 首次使用时按 A-Z 选择已掌握的单词
2. **音频上传** - 支持 MP3、M4A 格式音频文件
3. **智能播放** - 熟词正常播放，生词自动暂停并显示释义
4. **生词管理** - 随时查看和管理生词库，标记已掌握词汇
5. **数据持久化** - 本地 SQLite 数据库保存学习进度

## 技术栈

- **Flutter** - 跨平台开发框架
- **Dart** - 编程语言
- **SQLite** - 本地数据库
- **audioplayers** - 音频播放
- **Provider** - 状态管理

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── models/
│   └── word.dart         # 数据模型
├── providers/
│   └── app_provider.dart # 全局状态管理
├── services/
│   ├── audio_service.dart     # 音频服务
│   ├── database_service.dart  # 数据库服务
│   └── vocabulary_service.dart # 词汇服务
├── screens/
│   ├── splash_screen.dart           # 启动页
│   ├── vocabulary_setup_screen.dart # 熟词设置
│   ├── home_screen.dart            # 主页
│   ├── player_screen.dart          # 播放器
│   └── unknown_words_screen.dart   # 生词库
└── widgets/
    └── unknown_word_dialog.dart    # 生词弹窗
```

## 如何运行

### 环境要求

- Flutter SDK 3.0.0+
- Android Studio 或 VS Code
- Android SDK（如需打包 APK）

### 步骤

1. **安装依赖**
   ```bash
   flutter pub get
   ```

2. **运行应用**
   ```bash
   flutter run
   ```

3. **打包 APK**
   ```bash
   flutter build apk --release
   ```

   APK 文件将生成在 `build/app/outputs/flutter-apk/app-release.apk`

## 使用说明

### 首次使用

1. 打开应用，进入熟词库初始化界面
2. 按字母顺序浏览单词列表
3. 点击单词或勾选框标记为"已掌握"
4. 点击"进入应用"开始使用

### 日常使用

1. 点击右下角"上传音频"选择听力文件
2. 在音频列表中点击文件开始学习
3. 播放时遇到生词会自动暂停，显示释义
4. 学习后可选择"加入熟词库"或"继续学习"
5. 随时进入"生词库"查看和复习生词

## 注意事项

- 当前版本使用模拟转写数据进行演示
- 实际语音识别需要集成 Whisper 或其他 ASR 服务
- 词汇库基于 PET 考试词汇表

## 后续优化方向

1. 集成真实的本地语音识别（Whisper）
2. 添加更多词汇库（雅思、托福等）
3. 支持播放速度调节
4. 添加学习统计和进度追踪
5. 支持云端同步