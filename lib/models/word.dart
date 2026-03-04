class Word {
  final String id;
  final String word;
  final String phonetic;
  final String chineseMeaning;
  final String level;
  bool isKnown;

  Word({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.chineseMeaning,
    required this.level,
    this.isKnown = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'phonetic': phonetic,
      'chineseMeaning': chineseMeaning,
      'level': level,
      'isKnown': isKnown ? 1 : 0,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      word: map['word'],
      phonetic: map['phonetic'],
      chineseMeaning: map['chineseMeaning'],
      level: map['level'],
      isKnown: map['isKnown'] == 1,
    );
  }
}

class AudioFile {
  final String id;
  final String fileName;
  final String filePath;
  final int duration;
  final DateTime createdAt;
  final String? transcriptPath;
  bool isProcessed;

  AudioFile({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.duration,
    required this.createdAt,
    this.transcriptPath,
    this.isProcessed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'transcriptPath': transcriptPath,
      'isProcessed': isProcessed ? 1 : 0,
    };
  }

  factory AudioFile.fromMap(Map<String, dynamic> map) {
    return AudioFile(
      id: map['id'],
      fileName: map['fileName'],
      filePath: map['filePath'],
      duration: map['duration'],
      createdAt: DateTime.parse(map['createdAt']),
      transcriptPath: map['transcriptPath'],
      isProcessed: map['isProcessed'] == 1,
    );
  }
}

class TranscriptWord {
  final String word;
  final double startTime;
  final double endTime;
  final bool isUnknown;

  TranscriptWord({
    required this.word,
    required this.startTime,
    required this.endTime,
    this.isUnknown = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'startTime': startTime,
      'endTime': endTime,
      'isUnknown': isUnknown ? 1 : 0,
    };
  }

  factory TranscriptWord.fromMap(Map<String, dynamic> map) {
    return TranscriptWord(
      word: map['word'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      isUnknown: map['isUnknown'] == 1,
    );
  }
}