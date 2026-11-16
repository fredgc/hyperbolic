import 'package:flutter/material.dart';
import 'printer.dart';

class SplitterWidget extends StatefulWidget {
  final Widget Function(BuildContext) top;
  final Widget Function(BuildContext) bottom;
  final void Function(double) setter;
  final double initialSize;
  final Color background;
  final Color outline;
  final Axis direction;

  const SplitterWidget({
    required this.top,
    required this.bottom,
    required this.setter,
    required this.initialSize,
    this.background = Colors.black,
    this.outline = Colors.green,
    this.direction = Axis.vertical,
    super.key,
  });

  @override
  State<SplitterWidget> createState() => SplitterWidgetState();
}

class SplitterWidgetState extends State<SplitterWidget> {
  static const double _minimumSize = 5;
  late double _splitSize;

  @override
  void initState() {
    super.initState();
    _splitSize = widget.initialSize;
  }

  BoxDecoration decoration() {
    return BoxDecoration(
      color: widget.background,
      border: Border.all(width: 2.0, color: widget.outline),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 20;
    final isHorizontal = widget.direction == Axis.horizontal;

    Widget icon = CircleAvatar(
      radius: iconSize / 2.0,
      backgroundColor: widget.outline,
      child: Icon(
        isHorizontal ? Icons.drag_indicator : Icons.drag_handle,
        color: widget.background,
        size: iconSize,
      ),
    );

    if (isHorizontal) {
      return Stack(
        children: [
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: decoration(),
                  child: ClipRect(child: widget.top(context)),
                ),
              ),
              Container(
                width: _splitSize,
                decoration: decoration(),
                child: ClipRect(child: widget.bottom(context)),
              ),
            ],
          ),
          Positioned(
            right: _splitSize - iconSize / 2.0,
            top: 20,
            child: GestureDetector(
              child: icon,
              onScaleStart: (info) {
                Log.mouseScale.log("ICON. horizontal scale start.");
              },
              onScaleUpdate: (info) {
                if (context.size != null) {
                  setState(() {
                    _splitSize -= info.focalPointDelta.dx;
                    double maximumSize = context.size!.width - 2 * _minimumSize;
                    _splitSize = _splitSize.clamp(_minimumSize, maximumSize);
                    widget.setter(_splitSize);
                    Log.mouseScale.log("split_size = ${zzz(_splitSize)}");
                  });
                }
              },
              onScaleEnd: (info) {
                Log.mouseScale.log(
                  "ICON -- end split_size = ${zzz(_splitSize)}",
                );
              },
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: decoration(),
                child: ClipRect(child: widget.top(context)),
              ),
            ),
            Container(
              height: _splitSize,
              decoration: decoration(),
              child: ClipRect(child: widget.bottom(context)),
            ),
          ],
        ),
        Positioned(
          right: 3,
          bottom: _splitSize - iconSize / 2.0,
          child: GestureDetector(
            child: icon,
            onScaleStart: (info) {
              Log.mouseScale.log("ICON. vertical scale start.");
            },
            onScaleUpdate: (info) {
              if (context.size != null) {
                setState(() {
                  _splitSize -= info.focalPointDelta.dy;
                  double maximumSize = context.size!.height - 2 * _minimumSize;
                  _splitSize = _splitSize.clamp(_minimumSize, maximumSize);
                  widget.setter(_splitSize);
                  Log.mouseScale.log("split_size = ${zzz(_splitSize)}");
                });
              }
            },
            onScaleEnd: (info) {
              Log.mouseScale.log("ICON -- end split_size = ${zzz(_splitSize)}");
            },
          ),
        ),
      ],
    );
  }
}
