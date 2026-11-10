/// An error reported on a content generator's `errorStream`.
final class ContentGeneratorError implements Exception {
  /// Creates a [ContentGeneratorError].
  const ContentGeneratorError(this.error, [this.stackTrace]);

  /// The error that occurred.
  final Object error;

  /// The stack trace of the error.
  final StackTrace? stackTrace;
}
