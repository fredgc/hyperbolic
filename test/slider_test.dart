import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyperbolic/slider.dart';

// ignore: must_be_immutable
class SliderHolder extends StatelessWidget {
  final MySlider slider;
  final String title;

  AnimationController controller;
  int ticks = 0;
  double previousClock = 0.0;
  AnimationStatus status = AnimationStatus.dismissed;

  SliderHolder({
    super.key,
    required this.title,
    required this.slider,
    required WidgetTester ticker,
  }) : controller = AnimationController(
         duration: const Duration(seconds: 10),
         upperBound: 10,
         vsync: ticker,
       ) {
    controller.view.addListener(hearTick);
    controller.addStatusListener((status) {
      this.status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slider Demo',
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: slider.build(context)),
      ),
    );
  }

  void start() {
    previousClock = 0.0;
    controller.reset();
    controller.forward();
  }

  void hearTick() {
    ticks++;
    double dt = controller.value - previousClock;
    slider.updateTime(dt);
    previousClock = controller.value;
  }
}

void main() {
  testWidgets('Slider builds', (tester) async {
    final String title = 'This is the title';
    final String name = 'parameter';
    var slider = MySlider(name, 0.0, 1.0, 0.0);
    SliderHolder holder = SliderHolder(
      title: title,
      slider: slider,
      ticker: tester,
    );
    await tester.pumpWidget(holder);
    await tester.pumpAndSettle();

    final titleFinder = find.text(title);
    final labelFinder = find.textContaining(name);

    expect(titleFinder, findsOneWidget);
    expect(labelFinder, findsOneWidget);

    holder.start();
    expect(holder.status, AnimationStatus.forward);

    final double epsilon = 0.01;
    slider.setSpeed(0.1);

    expect(slider.value, closeTo(0.0, epsilon));
    await tester.pumpFrames(holder, const Duration(seconds: 5));
    expect(slider.value, closeTo(0.5, epsilon));
    expect(holder.status, AnimationStatus.forward);
    await tester.pumpFrames(holder, const Duration(seconds: 5));
    expect(slider.value, closeTo(1.0, epsilon));
    await tester.pumpFrames(holder, const Duration(seconds: 5));
    expect(slider.value, closeTo(1.0, epsilon));
    expect(holder.status, AnimationStatus.completed);
  });
}
