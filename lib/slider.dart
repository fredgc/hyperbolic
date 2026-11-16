import 'package:flutter/material.dart';

import 'l10n/l10n_extension.dart';
import "printer.dart";
import 'settings.dart';

class MySlider with ChangeNotifier {
  String name;
  double _value;
  double get value => _value;
  double min;
  double max;
  double speed = 0.0;
  final double speedDelta = 2.0;
  bool allowAnimate;
  bool stickAtZero = true;

  int currentSticky = -1;
  int nextSticky = -1;
  double currentTimeAtStickyPoint = 0;
  List<double> sticky = [];

  VoidCallback? startAnimation;
  Color backgroundColor = Colors.black;
  Color textColor = Colors.white;
  Color gridColor = Colors.red;
  Size size = const Size(0, 0);
  bool loop = false;

  int paintCounter = 0;
  int buildCounter = 0;

  static int _debugCounter = 0;
  final int _debugId = ++_debugCounter;

  MySlider(
    this.name,
    this.min,
    this.max,
    this._value, {
    this.allowAnimate = true,
  }) {
    speed = 0.0;
    if (min >= max) {
      max = min + 0.1;
    }
  }

  static SavableDouble stickyDelay = SavableDouble(
    "sticky_delay",
    "Sticky delay",
    0.1,
    tip: "How long in seconds a slider should dwell on a sticky point",
  );
  static SavableDouble stickyRadius = SavableDouble(
    "sticky_radius",
    "Sticky radius",
    1.0,
    tip: "How close the slider should be to a sticky point before snapping",
  );

  static void initSettings(Settings settings) {
    settings.add(stickyDelay);
    settings.add(stickyRadius);
    settings.add(EndOfGroup());
  }

  @override
  String toString() {
    return "Slider-$_debugId $name (${zzz(value)})";
  }

  void setSticky(Iterable<double> iterable) {
    sticky = [];
    addSticky(iterable);
  }

  void addSticky(Iterable<double> iterable) {
    Set<double> set = Set.from(sticky);
    set.addAll(iterable);
    sticky = set.toList();
    sticky.sort();
    findNextSticky();
    notifyListeners();
  }

  void autoRange() {
    if (sticky.isEmpty) return;
    min = sticky[0];
    max = sticky.last;
    if (_value < min) min = _value;
    if (_value > max) max = _value;
    if (max - min < 1.0e-9) {
      min -= 1.0e-3;
      max += 1.0e-3;
      return;
    }
    double buffer = (max - min) * 0.05;
    min -= buffer;
    max += buffer;
  }

  double valueToPixel(double x) {
    return size.width * (x - min) / (max - min);
  }

  double pixelToValue(double px) {
    return min + (px / size.width) * (max - min);
  }

  double pixelToVelocity(double px) {
    if (size.width == 0) return min;
    return (px / size.width) * (max - min);
  }

  String debugPrint() {
    return "SL ${zzz(value)}(sp=${zzz(speed)}, p$paintCounter,b$buildCounter), ";
  }

  set value(double x) {
    currentSticky = -1;
    if (stickyRadius.value > 0) {
      final double stickyWidth = (max - min) * stickyRadius.value * 0.01;
      int stickyPoint = 0;
      for (int i = 1; i < sticky.length; i++) {
        if ((x - sticky[i]).abs() < (x - sticky[stickyPoint]).abs()) {
          stickyPoint = i;
        }
        if ((x - sticky[stickyPoint]).abs() < stickyWidth) {
          x = sticky[stickyPoint];
          currentSticky = stickyPoint;
          currentTimeAtStickyPoint = 0.0;
        }
      }
      if (currentSticky < 0 && stickAtZero && x.abs() < stickyWidth) {
        x = 0;
      }
    }
    _value = x;
    clamp();
    findNextSticky();
    notifyListeners();
  }

  bool updateTime(double dt, {bool notifyOnChange = true}) {
    if (speed == 0) {
      return false;
    }
    if (currentSticky >= 0) {
      currentTimeAtStickyPoint += dt;
      if (currentTimeAtStickyPoint > stickyDelay.value) {
        dt = currentTimeAtStickyPoint - stickyDelay.value;
        currentTimeAtStickyPoint = 0;
        currentSticky = -1;
        findNextSticky();
      } else {
        return true;
      }
    }
    double dh = speed * dt;
    double range = (max - min);
    if (dh.abs() > range) {
      Log.errors.log("RED: dh is very big: ${zzz(dh)}");
      speed = 0.0;
      dh = 0;
      return false;
    }
    if (hitsNextSticky(dh)) {
      currentSticky = nextSticky;
      _value = sticky[currentSticky];
      currentTimeAtStickyPoint = 0.0;
    } else {
      _value += dh;
    }
    if (loop) {
      if (_value > max) _value = min;
      if (_value < min) _value = max;
    } else {
      if (clamp()) setSpeed(0.0);
    }
    if (notifyOnChange) notifyListeners();
    return true;
  }

  bool hitsNextSticky(double dh) {
    if (nextSticky < 0) return false;
    double a = speed > 0 ? _value : (_value + dh);
    double b = speed > 0 ? (_value + dh) : _value;
    double x = sticky[nextSticky];
    return (a <= x && x <= b);
  }

  void findNextSticky() {
    if (stickyDelay.value <= 0.0 || sticky.isEmpty) {
      nextSticky = -1;
      return;
    }
    if (speed > 0) {
      for (int i = 0; i < sticky.length; i++) {
        if (_value < sticky[i]) {
          nextSticky = i;
          return;
        }
      }
      nextSticky = -1;
    } else {
      for (int i = sticky.length - 1; i >= 0; i--) {
        if (_value > sticky[i]) {
          nextSticky = i;
          return;
        }
      }
      nextSticky = -1;
    }
  }

  bool clamp() {
    if (_value > max) {
      _value = max;
      return true;
    }
    if (_value < min) {
      _value = min;
      return true;
    }
    return false;
  }

  void setSpeed(double s) {
    speed = s;
    if (speed.abs() < 0.001 * (max - min)) speed = 0.0;
    if (speed != 0.0) {
      startAnimation?.call();
    }
    findNextSticky();
  }

  void incrementSpeed(double percent) {
    if (allowAnimate) {
      setSpeed(speed + (max - min) * percent * 0.01);
    }
  }

  void scaleStart(ScaleStartDetails info) {
    setSpeed(0.0);
    value = pixelToValue(info.localFocalPoint.dx);
  }

  void scaleUpdate(ScaleUpdateDetails info) {
    value = pixelToValue(info.localFocalPoint.dx);
  }

  void scaleEnd(ScaleEndDetails info) {
    double v = pixelToVelocity(info.velocity.pixelsPerSecond.dx);
    if (allowAnimate) setSpeed(v);
  }

  void tapUp(TapUpDetails info) {
    value = pixelToValue(info.localPosition.dx);
    setSpeed(0.0);
  }

  void paint(Canvas canvas, Size size) {
    paintCounter++;
    this.size = size;
    Paint background = Paint()..color = backgroundColor;
    Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    canvas.drawRect(rect, background);

    var x = valueToPixel(value);

    final style = TextStyle(color: textColor);
    var span = TextSpan(text: zzz(value), style: style);
    var painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    painter.layout();
    Offset offset = (x < size.width / 2)
        ? Offset(x + 10, 2)
        : Offset(x - 10 - painter.width, 2);
    rect = Rect.fromLTWH(
      offset.dx - 2,
      offset.dy - 2,
      painter.width + 4,
      painter.height + 4,
    );

    Paint grid = Paint()..color = gridColor;
    double mid = painter.height + (size.height - painter.height) / 2.0;
    rect = Rect.fromLTWH(0.0, mid - 1.0, size.width, 2.0);
    canvas.drawRect(rect, grid);

    for (double x in sticky) {
      Offset c = Offset(valueToPixel(x), mid);
      canvas.drawCircle(c, 2.0, grid);
    }

    Paint handlePaint = Paint()..color = textColor;
    rect = Rect.fromLTWH(x - 2, 0.0, 4.0, size.height);
    RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.0));
    canvas.drawRRect(rrect, handlePaint);

    painter.paint(canvas, offset);
  }

  Widget build(BuildContext context) {
    buildCounter++;
    ThemeData theme = Theme.of(context);
    backgroundColor = theme.colorScheme.surface;
    textColor = theme.colorScheme.onSurface;
    gridColor = theme.colorScheme.primary;
    return IntrinsicHeight(
      child: Row(
        children: <Widget>[
          Text("$name: "),
          Opacity(
            opacity: allowAnimate ? 1.0 : 0.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_left),
              tooltip: context.l10n.sliderDecreaseSpeedTooltip,
              onPressed: () {
                incrementSpeed(-speedDelta);
              },
            ),
          ),
          Expanded(
            child: GestureDetector(
              onScaleStart: scaleStart,
              onScaleUpdate: scaleUpdate,
              onScaleEnd: scaleEnd,
              onTapUp: tapUp,
              child: ClipRect(
                child: CustomPaint(
                  painter: SliderPainter(slider: this, repaint: this),
                  child: Container(),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: allowAnimate ? 1.0 : 0.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_right),
              tooltip: context.l10n.sliderIncreaseSpeedTooltip,
              onPressed: () {
                incrementSpeed(speedDelta);
              },
            ),
          ),
        ],
      ),
    );
  }

  static Table buildTable(
    BuildContext context,
    List<MySlider> sliders, {
    String? highlightId,
    double highlightPulse = 1.0,
  }) {
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
        3: IntrinsicColumnWidth(),
      },
      children: sliders.map((f) {
        return TableRow(children: f.buildRow(context));
      }).toList(),
    );
  }

  List<Widget> buildRow(BuildContext context, {double highlightPulse = 0.0}) {
    buildCounter++;
    ThemeData theme = Theme.of(context);
    backgroundColor = theme.colorScheme.surface;
    textColor = theme.colorScheme.onSurface;
    gridColor = theme.colorScheme.primary;
    return <Widget>[
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Text(" $name:", style: TextStyle(color: textColor)),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Opacity(
          opacity: allowAnimate ? 1.0 : 0.0,
          child: IconButton(
            color: gridColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_left),
            tooltip: context.l10n.sliderDecreaseSpeedTooltip,
            onPressed: () {
              incrementSpeed(-speedDelta);
            },
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.fill,
        child: GestureDetector(
          key: ValueKey("canvas-$name"),
          onScaleStart: scaleStart,
          onScaleUpdate: scaleUpdate,
          onScaleEnd: scaleEnd,
          onTapUp: tapUp,
          child: ClipRect(
            child: CustomPaint(
              painter: SliderPainter(slider: this, repaint: this),
              child: Container(),
            ),
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Opacity(
          opacity: allowAnimate ? 1.0 : 0.0,
          child: IconButton(
            color: gridColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_right),
            tooltip: context.l10n.sliderIncreaseSpeedTooltip,
            onPressed: () {
              incrementSpeed(speedDelta);
            },
          ),
        ),
      ),
    ];
  }
}

class SliderPainter extends CustomPainter {
  final MySlider slider;
  SliderPainter({required this.slider, super.repaint});

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return this != oldDelegate;
  }

  @override
  void paint(Canvas canvas, Size size) {
    slider.paint(canvas, size);
  }
}
