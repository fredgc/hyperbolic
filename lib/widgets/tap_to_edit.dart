import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../edit.dart';
import '../printer.dart';

class TapToEditText extends StatefulWidget {
  final String name;
  final String text;
  final Function(String value) callback;
  final MyUndoManager manager;
  const TapToEditText(
    this.name,
    this.text,
    this.manager,
    this.callback, {
    super.key,
  });

  @override
  State<TapToEditText> createState() => TapToEditTextState();
}

class TapToEditTextState extends State<TapToEditText> {
  bool _isActive = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  TapToEditTextState();

  static int _debugCounter = 0;
  final int _debugId = ++_debugCounter;
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      "TapToEditState-$_debugId-${widget.name}, '${widget.text}' (${_controller.text})";

  @override
  void didUpdateWidget(TapToEditText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _controller.text = widget.text;
      _isActive = false;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) {
      return InkWell(
        child: Text(
          widget.text,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        onTap: () {
          setState(() {
            Log.textEdit.log('ORANGE: Tapped on field $this.');
            _controller.text = widget.text;
            _isActive = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isActive) {
              _focusNode.requestFocus();
            }
          });
        },
      );
    }
    return Focus(
      onKeyEvent: _onKeyEvent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48),
        child: IntrinsicWidth(
          child: TextField(
            focusNode: _focusNode,
            autofocus: true,
            controller: _controller,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
              border: const UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
            ),
            onTapOutside: (_) {
              _focusNode.unfocus();
            },
            onSubmitted: (value) => setState(() {
              changeValue(value);
              _isActive = false;
            }),
          ),
        ),
      ),
      onFocusChange: (hasFocus) {
        if (!hasFocus && _isActive) {
          setState(() {
            changeValue(_controller.text);
            _isActive = false;
          });
        }
      },
    );
  }

  void changeValue(String value) {
    if (widget.text == value) {
      return;
    }
    widget.callback(value);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _isActive = false;
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
