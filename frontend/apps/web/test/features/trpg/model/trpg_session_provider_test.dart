import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/features/trpg/model/trpg_session_provider.dart';

void main() {
  group('resolvePostPagingMode', () {
    test('returns processing when isProcessing=true and hasSurface=false', () {
      final result = TrpgSessionNotifier.resolvePostPagingMode(
        isProcessing: true,
        hasSurface: false,
      );
      expect(result, NovelDisplayMode.processing);
    });

    test('returns processing when isProcessing=true and hasSurface=true', () {
      final result = TrpgSessionNotifier.resolvePostPagingMode(
        isProcessing: true,
        hasSurface: true,
      );
      expect(result, NovelDisplayMode.processing);
    });

    test('returns surface when isProcessing=false and hasSurface=true', () {
      final result = TrpgSessionNotifier.resolvePostPagingMode(
        isProcessing: false,
        hasSurface: true,
      );
      expect(result, NovelDisplayMode.surface);
    });

    test('returns input when isProcessing=false and hasSurface=false', () {
      final result = TrpgSessionNotifier.resolvePostPagingMode(
        isProcessing: false,
        hasSurface: false,
      );
      expect(result, NovelDisplayMode.input);
    });
  });
}
