/// ゲームセッションのステータス（DB session_status enum に対応）
enum SessionStatus {
  active,
  completed,
  abandoned;

  /// DB の snake_case 文字列からパース
  static SessionStatus fromString(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionStatus.active,
    );
  }
}
