class CounterModel {
  const CounterModel({required this.value});

  final int value;

  CounterModel copyWith({int? value}) {
    return CounterModel(value: value ?? this.value);
  }

  CounterModel increment() {
    return copyWith(value: value + 1);
  }

  CounterModel decrement() {
    return copyWith(value: value - 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterModel &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CounterModel(value: $value)';
}
