import 'package:core_utils/core_utils.dart';
import '../../../entities/counter/model/counter_model.dart';

abstract class CounterApi {
  Future<CounterModel> getCounter();
  Future<CounterModel> saveCounter(CounterModel counter);
  Future<void> resetCounter();
}

class MockCounterApi implements CounterApi {
  CounterModel _counter = const CounterModel(value: 0);

  @override
  Future<CounterModel> getCounter() async {
    Logger.info('MockCounterApi: Getting counter value');
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    return _counter;
  }

  @override
  Future<CounterModel> saveCounter(CounterModel counter) async {
    Logger.info('MockCounterApi: Saving counter value: ${counter.value}');
    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // Simulate network delay
    _counter = counter;
    return _counter;
  }

  @override
  Future<void> resetCounter() async {
    Logger.info('MockCounterApi: Resetting counter');
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); // Simulate network delay
    _counter = const CounterModel(value: 0);
  }
}

// 実際のAPI実装用のクラス（将来的に使用）
class HttpCounterApi implements CounterApi {
  HttpCounterApi({required this.baseUrl});

  final String baseUrl;

  @override
  Future<CounterModel> getCounter() async {
    // TODO: Implement HTTP GET request
    throw UnimplementedError('HTTP API not implemented yet');
  }

  @override
  Future<CounterModel> saveCounter(CounterModel counter) async {
    // TODO: Implement HTTP POST request
    throw UnimplementedError('HTTP API not implemented yet');
  }

  @override
  Future<void> resetCounter() async {
    // TODO: Implement HTTP DELETE request
    throw UnimplementedError('HTTP API not implemented yet');
  }
}
