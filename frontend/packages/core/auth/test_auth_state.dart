import 'lib/models/auth_state.dart';

void main() {
  const state = AuthState.unauthenticated();
  // ignore: avoid_print
  print(state.isAuthenticated);
}
