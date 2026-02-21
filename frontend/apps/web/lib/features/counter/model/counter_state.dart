import 'package:flutter/foundation.dart';
import '../../../entities/counter/model/counter_model.dart';

class CounterState extends ChangeNotifier {
  CounterModel _counter = const CounterModel(value: 0);

  int get value => _counter.value;

  void increment() {
    _counter = _counter.increment();
    notifyListeners();
  }

  void decrement() {
    _counter = _counter.decrement();
    notifyListeners();
  }

  void reset() {
    _counter = const CounterModel(value: 0);
    notifyListeners();
  }
}
