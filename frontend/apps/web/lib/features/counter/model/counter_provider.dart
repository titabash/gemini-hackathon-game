import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../entities/counter/model/counter_model.dart';

part 'counter_provider.g.dart';

@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  CounterModel build() {
    return const CounterModel(value: 0);
  }

  void increment() {
    state = state.increment();
  }

  void decrement() {
    state = state.decrement();
  }

  void reset() {
    state = const CounterModel(value: 0);
  }
}
