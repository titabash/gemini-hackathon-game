import 'package:flutter/foundation.dart';

/// Splits GM narrative text into sentences and manages page-by-page advancement.
///
/// Supports Japanese sentence endings (。！？」) and English endings (.!?).
class TextPagingNotifier {
  final _currentSentenceNotifier = ValueNotifier<String>('');
  final _speakerNotifier = ValueNotifier<String?>(null);
  final _isCompleteNotifier = ValueNotifier<bool>(true);

  List<String> _sentences = [];
  int _index = 0;

  /// The sentence currently displayed in the text box.
  ValueListenable<String> get currentSentence => _currentSentenceNotifier;

  /// The speaker name extracted from the text (e.g. "[Goblin King]" prefix).
  ValueListenable<String?> get speaker => _speakerNotifier;

  /// Whether all sentences have been shown.
  ValueListenable<bool> get isComplete => _isCompleteNotifier;

  /// Whether there is a next sentence available.
  bool get hasNext => _index < _sentences.length - 1;

  /// Feed new text from the GM. Resets paging state.
  void feed(String text, {String? speaker}) {
    _speakerNotifier.value = speaker ?? _extractSpeaker(text);
    final cleaned = _removeSpeakerPrefix(text);
    _sentences = _splitSentences(cleaned);
    _index = 0;
    _isCompleteNotifier.value = _sentences.isEmpty;

    if (_sentences.isNotEmpty) {
      _currentSentenceNotifier.value = _sentences[0];
    } else {
      _currentSentenceNotifier.value = '';
    }
  }

  /// Advance to the next sentence. Returns `true` if advanced, `false` if
  /// already at the last sentence (paging complete).
  bool advance() {
    if (!hasNext) {
      _isCompleteNotifier.value = true;
      return false;
    }
    _index++;
    _currentSentenceNotifier.value = _sentences[_index];
    if (!hasNext) {
      _isCompleteNotifier.value = true;
    }
    return true;
  }

  /// Reset paging state.
  void clear() {
    _sentences = [];
    _index = 0;
    _currentSentenceNotifier.value = '';
    _speakerNotifier.value = null;
    _isCompleteNotifier.value = true;
  }

  void dispose() {
    _currentSentenceNotifier.dispose();
    _speakerNotifier.dispose();
    _isCompleteNotifier.dispose();
  }

  // ---------------------------------------------------------------------------
  // Speaker extraction
  // ---------------------------------------------------------------------------

  /// Extracts a speaker name from a `[Name]` prefix at the start of text.
  static String? _extractSpeaker(String text) {
    final match = RegExp(r'^\[(.+?)\]\s*').firstMatch(text);
    return match?.group(1);
  }

  /// Removes the `[Name]` prefix from text.
  static String _removeSpeakerPrefix(String text) {
    return text.replaceFirst(RegExp(r'^\[.+?\]\s*'), '');
  }

  // ---------------------------------------------------------------------------
  // Sentence splitting
  // ---------------------------------------------------------------------------

  /// Splits text into sentences using both Japanese and English delimiters.
  static List<String> _splitSentences(String text) {
    if (text.trim().isEmpty) return [];

    final sentences = <String>[];
    final buffer = StringBuffer();

    final runes = text.runes.toList();
    for (var i = 0; i < runes.length; i++) {
      final char = String.fromCharCode(runes[i]);
      buffer.write(char);

      if (_isSentenceEnd(char, runes, i)) {
        final sentence = buffer.toString().trim();
        if (sentence.isNotEmpty) {
          sentences.add(sentence);
        }
        buffer.clear();
      }
    }

    // Remaining text
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      sentences.add(remaining);
    }

    return sentences;
  }

  /// Whether the character at [index] marks the end of a sentence.
  static bool _isSentenceEnd(String char, List<int> runes, int index) {
    // Japanese sentence endings
    if (char == '。' || char == '！' || char == '？' || char == '」') {
      return true;
    }

    // English sentence endings: . ! ? followed by whitespace or end of text
    if (char == '.' || char == '!' || char == '?') {
      final isEnd = index == runes.length - 1;
      if (isEnd) return true;
      final next = String.fromCharCode(runes[index + 1]);
      if (next == ' ' || next == '\n' || next == '\r') return true;
    }

    // Newline as separator (paragraph breaks)
    if (char == '\n') return true;

    return false;
  }
}
