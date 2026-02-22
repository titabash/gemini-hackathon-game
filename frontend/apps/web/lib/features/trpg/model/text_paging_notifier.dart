import 'package:flutter/foundation.dart';

/// A single page of text with an optional speaker.
class _Page {
  const _Page({required this.text, this.speaker});
  final String text;
  final String? speaker;
}

/// Splits GM narrative text into sentences and manages page-by-page advancement.
///
/// Supports Japanese sentence endings (。！？」) and English endings (.!?).
/// Each paragraph (separated by `\n`) may have its own `[Speaker]` prefix;
/// the speaker updates as the user advances through pages.
class TextPagingNotifier {
  final _currentSentenceNotifier = ValueNotifier<String>('');
  final _speakerNotifier = ValueNotifier<String?>(null);
  final _isCompleteNotifier = ValueNotifier<bool>(true);

  List<_Page> _pages = [];
  int _index = 0;

  /// The sentence currently displayed in the text box.
  ValueListenable<String> get currentSentence => _currentSentenceNotifier;

  /// The speaker name extracted from the current page's paragraph.
  ValueListenable<String?> get speaker => _speakerNotifier;

  /// Whether all sentences have been shown.
  ValueListenable<bool> get isComplete => _isCompleteNotifier;

  /// Whether there is a next sentence available.
  bool get hasNext => _index < _pages.length - 1;

  /// Feed new text from the GM. Resets paging state.
  ///
  /// Text is split into paragraphs by `\n`. Each paragraph is checked for a
  /// `[Speaker]` prefix. Paragraphs are then split into sentences to form
  /// individual pages, each inheriting the paragraph's speaker.
  ///
  /// If [speaker] is provided, it is used for the entire text and paragraph
  /// `[Speaker]` prefixes are not extracted.
  void feed(String text, {String? speaker}) {
    _pages = _buildPages(text, explicitSpeaker: speaker);
    _index = 0;
    _isCompleteNotifier.value = _pages.isEmpty;

    if (_pages.isNotEmpty) {
      _currentSentenceNotifier.value = _pages[0].text;
      _speakerNotifier.value = _pages[0].speaker;
    } else {
      _currentSentenceNotifier.value = '';
      _speakerNotifier.value = null;
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
    _currentSentenceNotifier.value = _pages[_index].text;
    _speakerNotifier.value = _pages[_index].speaker;
    if (!hasNext) {
      _isCompleteNotifier.value = true;
    }
    return true;
  }

  /// Reset paging state.
  void clear() {
    _pages = [];
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
  // Page building (paragraph → sentences with speaker)
  // ---------------------------------------------------------------------------

  /// Builds a flat list of [_Page]s from text.
  ///
  /// 1. Split text into paragraphs by `\n`.
  /// 2. For each paragraph, extract an optional `[Speaker]` prefix.
  /// 3. Split the paragraph into sentences.
  /// 4. Each sentence becomes a [_Page] with the paragraph's speaker.
  static List<_Page> _buildPages(String text, {String? explicitSpeaker}) {
    if (text.trim().isEmpty) return [];

    final paragraphs = text.split('\n');
    final pages = <_Page>[];

    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;

      final String? paragraphSpeaker;
      final String cleanedText;

      if (explicitSpeaker != null) {
        paragraphSpeaker = explicitSpeaker;
        cleanedText = _removeSpeakerPrefix(trimmed);
      } else {
        paragraphSpeaker = _extractSpeaker(trimmed);
        cleanedText = _removeSpeakerPrefix(trimmed);
      }

      final sentences = _splitSentences(cleanedText);
      for (final sentence in sentences) {
        pages.add(_Page(text: sentence, speaker: paragraphSpeaker));
      }
    }

    return pages;
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

    return false;
  }
}
