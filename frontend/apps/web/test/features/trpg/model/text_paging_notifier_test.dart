import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/features/trpg/model/text_paging_notifier.dart';

void main() {
  late TextPagingNotifier notifier;

  setUp(() {
    notifier = TextPagingNotifier();
  });

  tearDown(() {
    notifier.dispose();
  });

  group('feed with explicit speaker', () {
    test('sets speaker from parameter', () {
      notifier.feed('Hello world.', speaker: 'Alice');
      expect(notifier.speaker.value, 'Alice');
    });

    test('explicit speaker overrides prefix', () {
      notifier.feed('[Bob] Hello world.', speaker: 'Alice');
      expect(notifier.speaker.value, 'Alice');
    });
  });

  group('feed with [Name] prefix speaker extraction', () {
    test('extracts speaker from single paragraph', () {
      notifier.feed('[Goblin King] You shall not pass!');
      expect(notifier.speaker.value, 'Goblin King');
      expect(notifier.currentSentence.value, 'You shall not pass!');
    });

    test('narration without prefix has null speaker', () {
      notifier.feed('The wind howled through the trees.');
      expect(notifier.speaker.value, isNull);
    });
  });

  group('paragraph-level speaker tracking', () {
    test('dialog then narration: speaker changes on advance', () {
      notifier.feed('[NPC] Hello there.\nThe room fell silent.');
      // First page: dialog with speaker
      expect(notifier.speaker.value, 'NPC');
      expect(notifier.currentSentence.value, 'Hello there.');

      // Advance to narration: speaker becomes null
      notifier.advance();
      expect(notifier.speaker.value, isNull);
      expect(notifier.currentSentence.value, 'The room fell silent.');
    });

    test('multiple NPCs: speaker changes per paragraph', () {
      notifier.feed('[Alice] Hi!\n[Bob] Hey!\nSome narration.');
      // First: Alice
      expect(notifier.speaker.value, 'Alice');
      expect(notifier.currentSentence.value, 'Hi!');

      // Second: Bob
      notifier.advance();
      expect(notifier.speaker.value, 'Bob');
      expect(notifier.currentSentence.value, 'Hey!');

      // Third: narration (no speaker)
      notifier.advance();
      expect(notifier.speaker.value, isNull);
      expect(notifier.currentSentence.value, 'Some narration.');
    });

    test('narration only: speaker stays null throughout', () {
      notifier.feed('First sentence.\nSecond sentence.');
      expect(notifier.speaker.value, isNull);

      notifier.advance();
      expect(notifier.speaker.value, isNull);
    });

    test('dialog with multiple sentences in same paragraph', () {
      notifier.feed('[Wizard] Cast the spell. It worked!');
      expect(notifier.speaker.value, 'Wizard');
      expect(notifier.currentSentence.value, 'Cast the spell.');

      notifier.advance();
      expect(notifier.speaker.value, 'Wizard');
      expect(notifier.currentSentence.value, 'It worked!');
    });

    test('Japanese text with paragraph speakers', () {
      notifier.feed('[魔法使い] 呪文を唱えよう。\n風が吹いた。');
      expect(notifier.speaker.value, '魔法使い');
      expect(notifier.currentSentence.value, '呪文を唱えよう。');

      notifier.advance();
      expect(notifier.speaker.value, isNull);
      expect(notifier.currentSentence.value, '風が吹いた。');
    });
  });

  group('advance', () {
    test('returns true when next page exists', () {
      notifier.feed('First. Second.');
      expect(notifier.advance(), isTrue);
    });

    test('returns false at last page', () {
      notifier.feed('Only one.');
      expect(notifier.advance(), isFalse);
    });

    test('isComplete is true after reaching last page', () {
      notifier.feed('First. Second.');
      expect(notifier.isComplete.value, isFalse);
      notifier.advance(); // now at last
      expect(notifier.isComplete.value, isTrue);
    });
  });

  group('clear', () {
    test('resets all state', () {
      notifier.feed('[NPC] Hello.\nWorld.');
      notifier.clear();
      expect(notifier.currentSentence.value, '');
      expect(notifier.speaker.value, isNull);
      expect(notifier.isComplete.value, isTrue);
    });
  });

  group('sentence splitting', () {
    test('splits on English sentence endings', () {
      notifier.feed('Hello. World! How? Fine.');
      expect(notifier.currentSentence.value, 'Hello.');
      expect(notifier.advance(), isTrue);
      expect(notifier.currentSentence.value, 'World!');
      expect(notifier.advance(), isTrue);
      expect(notifier.currentSentence.value, 'How?');
      expect(notifier.advance(), isTrue);
      expect(notifier.currentSentence.value, 'Fine.');
    });

    test('splits on Japanese sentence endings', () {
      notifier.feed('こんにちは。元気ですか？はい！');
      expect(notifier.currentSentence.value, 'こんにちは。');
      expect(notifier.advance(), isTrue);
      expect(notifier.currentSentence.value, '元気ですか？');
      expect(notifier.advance(), isTrue);
      expect(notifier.currentSentence.value, 'はい！');
    });

    test('empty text results in empty state', () {
      notifier.feed('');
      expect(notifier.currentSentence.value, '');
      expect(notifier.isComplete.value, isTrue);
    });
  });
}
