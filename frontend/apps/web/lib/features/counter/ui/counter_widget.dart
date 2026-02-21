import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:core_i18n/core_i18n.dart';
import '../model/counter_provider.dart';

class CounterWidget extends HookConsumerWidget {
  const CounterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final counterNotifier = ref.read(counterProvider.notifier);

    // AnimationControllerを使ってスケールアニメーションを追加
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );
    final scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticOut),
    );

    // カウンターの値が変わったときにアニメーションを実行
    useEffect(() {
      animationController.forward().then((_) {
        animationController.reverse();
      });
      return null;
    }, [counter.value]);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(t.home.message),
        AnimatedBuilder(
          animation: scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: scaleAnimation.value,
              child: Text(
                '${counter.value}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: counter.value > 10
                          ? Colors.red
                          : counter.value < 0
                              ? Colors.blue
                              : null,
                    ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              onPressed: counterNotifier.decrement,
              tooltip: t.counter.tooltip.decrement,
              child: const Icon(Icons.remove),
            ),
            FloatingActionButton(
              onPressed: counterNotifier.increment,
              tooltip: t.counter.tooltip.increment,
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: counterNotifier.reset,
          child: Text(t.counter.reset),
        ),
      ],
    );
  }
}
