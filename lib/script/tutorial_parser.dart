import 'package:flutter/foundation.dart';

import '../objects/objects.dart';
import '../scene/scene_view.dart';
import '../transform.dart';
import 'tutorial_step.dart';

/// A parsed tutorial lesson.
class Tutorial {
  final String title;
  final String description;
  final List<TutorialStep> steps;
  final bool allowDoItForMe;

  Tutorial({
    required this.title,
    this.description = '',
    required this.steps,
    this.allowDoItForMe = true,
  });

  factory Tutorial.fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    String title = 'Hyperbolic Tutorial';
    final descLines = <String>[];
    final steps = <TutorialStep>[];
    bool allowDoItForMe = true;

    String? currentStepTitle;
    final currentStepBody = <String>[];
    final currentStepDirectives = <TutorialDirective>[];
    final pendingDirectiveLines = <String>[];
    int stepCount = 0;

    void flushPendingDirectives() {
      if (pendingDirectiveLines.isEmpty) return;
      final combined = pendingDirectiveLines.join(' ');
      pendingDirectiveLines.clear();
      final parsed = _parseDirectives(
        combined,
        onDisableAuto: () => allowDoItForMe = false,
      );
      currentStepDirectives.addAll(parsed);
    }

    void finalizeCurrentStep() {
      flushPendingDirectives();
      if (currentStepTitle != null) {
        final hasInteractive = currentStepDirectives.any(
          (d) => !d.isSetupAction,
        );
        if (!hasInteractive) {
          currentStepDirectives.add(AcknowledgeDirective());
        }

        steps.add(
          TutorialStep(
            stepNumber: stepCount,
            title: currentStepTitle!,
            body: currentStepBody.join('\n').trim(),
            directives: List.from(currentStepDirectives),
          ),
        );
      }
      currentStepBody.clear();
      currentStepDirectives.clear();
    }

    for (var rawLine in lines) {
      final line = rawLine.trim();

      if (line.startsWith('>')) {
        pendingDirectiveLines.add(line.substring(1).trim());
        continue;
      }

      flushPendingDirectives();

      if (line.startsWith('# ') && currentStepTitle == null) {
        title = line.substring(2).trim();
      } else if (line.startsWith('## ')) {
        finalizeCurrentStep();
        stepCount++;
        currentStepTitle = line.substring(3).trim();
        final match = RegExp(
          r'^(Step\s+\d+:?|\d+\.?)\s*(.*)',
          caseSensitive: false,
        ).firstMatch(currentStepTitle!);
        if (match != null && match.group(2)!.isNotEmpty) {
          currentStepTitle = match.group(2)!.trim();
        }
      } else {
        if (currentStepTitle == null) {
          if (line.isNotEmpty) descLines.add(line);
        } else {
          currentStepBody.add(rawLine);
        }
      }
    }
    finalizeCurrentStep();

    return Tutorial(
      title: title,
      description: descLines.join('\n').trim(),
      steps: steps,
      allowDoItForMe: allowDoItForMe,
    );
  }

  static List<TutorialDirective> _parseDirectives(
    String text, {
    required VoidCallback onDisableAuto,
  }) {
    final results = <TutorialDirective>[];
    int pos = 0;
    final int len = text.length;

    while (pos < len) {
      while (pos < len &&
          (text[pos] == ' ' ||
              text[pos] == '\t' ||
              text[pos] == ';' ||
              text[pos] == ',')) {
        pos++;
      }
      if (pos >= len) break;

      final rem = text.substring(pos);

      // Disable auto
      final noAutoMatch = RegExp(
        r'^(?:no_auto|disable_auto|allow_auto\s*=\s*false)\b',
        caseSensitive: false,
      ).firstMatch(rem);
      if (noAutoMatch != null) {
        onDisableAuto();
        pos += noAutoMatch.end;
        continue;
      }

      // Reset
      final resetMatch = RegExp(
        r'^reset\b',
        caseSensitive: false,
      ).firstMatch(rem);
      if (resetMatch != null) {
        results.add(ResetDirective());
        pos += resetMatch.end;
        continue;
      }

      // OK / Next / Continue
      final okMatch = RegExp(
        r'^(?:ok|next|continue)\b',
        caseSensitive: false,
      ).firstMatch(rem);
      if (okMatch != null) {
        results.add(AcknowledgeDirective());
        pos += okMatch.end;
        continue;
      }

      // Setup
      final setupMatch = RegExp(
        r'^setup\s*:\s*',
        caseSensitive: false,
      ).firstMatch(rem);
      if (setupMatch != null) {
        pos += setupMatch.end;
        pos = _consumeSetupDirective(text, pos, results);
        continue;
      }

      // Tool directive: tool = <name>
      final toolMatch = RegExp(
        r'^tool\s*=\s*([a-zA-Z_]+)\b',
        caseSensitive: false,
      ).firstMatch(rem);
      if (toolMatch != null) {
        final toolName = toolMatch.group(1)!;
        final tool = _parseTool(toolName);
        if (tool != null) {
          results.add(ToolDirective(tool));
        }
        pos += toolMatch.end;
        continue;
      }

      // Add directive: add = point(...)
      final addMatch = RegExp(
        r'^(?:add|place)\s*=\s*point\b',
        caseSensitive: false,
      ).firstMatch(rem);
      if (addMatch != null) {
        pos += addMatch.end;
        Map<String, String> args = {};
        pos = _consumeOptionalParenArgs(text, pos, (parsed) => args = parsed);

        final x = double.tryParse(args['x'] ?? '0.0') ?? 0.0;
        final y = double.tryParse(args['y'] ?? '0.0') ?? 0.0;
        final tol =
            double.tryParse(args['tol'] ?? args['tolerance'] ?? '0.3') ?? 0.3;
        final name = args['name'];

        results.add(
          AddPointDirective(
            targetPoint: HyperbolicPoint(x, y),
            targetName: name,
            tolerance: tol,
          ),
        );
        continue;
      }

      // Select directive: select = <name>
      final selectMatch = RegExp(
        r'^select\s*=\s*(?:"([^"]+)"|'
        r"'([^']+)'"
        r'|([^\s,;()]+))',
        caseSensitive: false,
      ).firstMatch(rem);
      if (selectMatch != null) {
        final target =
            (selectMatch.group(1) ??
                    selectMatch.group(2) ??
                    selectMatch.group(3)!)
                .trim();
        results.add(SelectDirective(target));
        pos += selectMatch.end;
        continue;
      }

      // Drag directive: drag = <name>(x=..., y=..., tol=...)
      final dragMatch = RegExp(
        r'^drag\s*=\s*(?:"([^"]+)"|'
        r"'([^']+)'"
        r'|([^\s,;()]+))',
        caseSensitive: false,
      ).firstMatch(rem);
      if (dragMatch != null) {
        final target =
            (dragMatch.group(1) ?? dragMatch.group(2) ?? dragMatch.group(3)!)
                .trim();
        pos += dragMatch.end;
        Map<String, String> args = {};
        pos = _consumeOptionalParenArgs(text, pos, (parsed) => args = parsed);

        final x = double.tryParse(args['x'] ?? '0.0') ?? 0.0;
        final y = double.tryParse(args['y'] ?? '0.0') ?? 0.0;
        final tol =
            double.tryParse(args['tol'] ?? args['tolerance'] ?? '0.25') ?? 0.25;

        results.add(
          DragDirective(
            targetName: target,
            targetPoint: HyperbolicPoint(x, y),
            tolerance: tol,
          ),
        );
        continue;
      }

      // Slider directive: slider = <name>(val=..., tol=...) or <name> = <value>
      final sliderMatch = RegExp(
        r'^(?:slider\s*=\s*)?(?:"([^"]+)"|'
        r"'([^']+)'"
        r'|([a-zA-Z0-9_]+))\s*(?:=|\()\s*',
        caseSensitive: false,
      ).firstMatch(rem);
      if (sliderMatch != null) {
        final target =
            (sliderMatch.group(1) ??
                    sliderMatch.group(2) ??
                    sliderMatch.group(3)!)
                .trim();
        pos += sliderMatch.end;
        if (rem[sliderMatch.end - 1] == '(') {
          Map<String, String> args = {};
          pos = _consumeParenBody(text, pos, (parsed) => args = parsed);
          final val =
              double.tryParse(args['val'] ?? args['value'] ?? '1.0') ?? 1.0;
          final tol =
              double.tryParse(args['tol'] ?? args['tolerance'] ?? '0.15') ??
              0.15;
          results.add(
            SliderDirective(
              targetName: target,
              targetValue: val,
              tolerance: tol,
            ),
          );
        } else {
          // simple value: e.g. = 2.5
          final valMatch = RegExp(
            r'^([+-]?\d+(?:\.\d+)?)\b',
          ).firstMatch(text.substring(pos));
          if (valMatch != null) {
            final val = double.parse(valMatch.group(1)!);
            pos += valMatch.end;
            results.add(SliderDirective(targetName: target, targetValue: val));
          }
        }
        continue;
      }

      // Unrecognized token, advance 1 character to avoid infinite loops
      pos++;
    }

    return results;
  }

  static HyperbolicTool? _parseTool(String raw) {
    final lower = raw.toLowerCase().replaceAll('_', '');
    for (final tool in HyperbolicTool.values) {
      if (tool.name.toLowerCase() == lower) return tool;
      if (tool.name.toLowerCase().replaceAll('_', '') == lower) return tool;
    }
    if (lower == 'movedisk' || lower == 'move' || lower == 'translate') {
      return HyperbolicTool.moveDisk;
    }
    if (lower == 'pan' || lower == 'panzoom' || lower == 'zoom') {
      return HyperbolicTool.panZoom;
    }
    if (lower == 'dist' || lower == 'distance') {
      return HyperbolicTool.measureDistance;
    }
    if (lower == 'angle') {
      return HyperbolicTool.measureAngle;
    }
    return null;
  }

  static int _consumeSetupDirective(
    String text,
    int startPos,
    List<TutorialDirective> out,
  ) {
    final items = <SetupItem>[];
    int pos = startPos;
    final int len = text.length;

    while (pos < len) {
      while (pos < len &&
          (text[pos] == ' ' ||
              text[pos] == '\t' ||
              text[pos] == ',' ||
              text[pos] == ';')) {
        pos++;
      }
      if (pos >= len) break;

      final rem = text.substring(pos);

      // point(name="A", x=0.0, y=0.0, locked=true)
      final ptMatch = RegExp(
        r'^point\s*\(',
        caseSensitive: false,
      ).firstMatch(rem);
      if (ptMatch != null) {
        pos += ptMatch.end;
        Map<String, String> args = {};
        pos = _consumeParenBody(text, pos, (parsed) => args = parsed);
        final name = args['name'] ?? 'P';
        final x = double.tryParse(args['x'] ?? '0.0') ?? 0.0;
        final y = double.tryParse(args['y'] ?? '0.0') ?? 0.0;
        final locked = (args['locked'] ?? 'false').toLowerCase() == 'true';
        items.add(SetupPointItem(name: name, x: x, y: y, locked: locked));
        continue;
      }

      // line(name="AB", p1="A", p2="B", style="segment")
      final lnMatch = RegExp(
        r'^line\s*\(',
        caseSensitive: false,
      ).firstMatch(rem);
      if (lnMatch != null) {
        pos += lnMatch.end;
        Map<String, String> args = {};
        pos = _consumeParenBody(text, pos, (parsed) => args = parsed);
        final name = args['name'] ?? 'L';
        final p1 = args['p1'] ?? 'A';
        final p2 = args['p2'] ?? 'B';
        final style = (args['style'] ?? '').toLowerCase() == 'segment'
            ? LineStyle.segment
            : LineStyle.fullLine;
        items.add(
          SetupLineItem(name: name, p1Name: p1, p2Name: p2, style: style),
        );
        continue;
      }

      // circle(name="C1", center="A", point="B")
      final circMatch = RegExp(
        r'^circle\s*\(',
        caseSensitive: false,
      ).firstMatch(rem);
      if (circMatch != null) {
        pos += circMatch.end;
        Map<String, String> args = {};
        pos = _consumeParenBody(text, pos, (parsed) => args = parsed);
        final name = args['name'] ?? 'C';
        final center = args['center'] ?? 'A';
        final pt = args['point'] ?? 'B';
        items.add(
          SetupCircleItem(name: name, centerName: center, pointName: pt),
        );
        continue;
      }

      // number(name="N1", value=1.5)
      final numMatch = RegExp(
        r'^number\s*\(',
        caseSensitive: false,
      ).firstMatch(rem);
      if (numMatch != null) {
        pos += numMatch.end;
        Map<String, String> args = {};
        pos = _consumeParenBody(text, pos, (parsed) => args = parsed);
        final name = args['name'] ?? 'N';
        final val =
            double.tryParse(args['val'] ?? args['value'] ?? '1.0') ?? 1.0;
        items.add(SetupNumberItem(name: name, value: val));
        continue;
      }

      // End of setup items
      break;
    }

    if (items.isNotEmpty) {
      out.add(SetupDirective(items));
    }
    return pos;
  }

  static int _consumeOptionalParenArgs(
    String text,
    int pos,
    void Function(Map<String, String>) onParsed,
  ) {
    int p = pos;
    final int len = text.length;
    while (p < len && (text[p] == ' ' || text[p] == '\t')) {
      p++;
    }
    if (p < len && text[p] == '(') {
      return _consumeParenBody(text, p + 1, onParsed);
    }
    onParsed({});
    return pos;
  }

  static int _consumeParenBody(
    String text,
    int startInsideParen,
    void Function(Map<String, String>) onParsed,
  ) {
    int pos = startInsideParen;
    final int len = text.length;
    int depth = 1;
    final buffer = StringBuffer();

    while (pos < len && depth > 0) {
      final ch = text[pos];
      if (ch == '(') {
        depth++;
        buffer.write(ch);
      } else if (ch == ')') {
        depth--;
        if (depth > 0) buffer.write(ch);
      } else {
        buffer.write(ch);
      }
      pos++;
    }

    final inside = buffer.toString().trim();
    final args = <String, String>{};
    if (inside.isNotEmpty) {
      final parts = inside.split(RegExp(r',\s*'));
      for (final part in parts) {
        final eqIdx = part.indexOf('=');
        if (eqIdx != -1) {
          final k = part.substring(0, eqIdx).trim().toLowerCase();
          var v = part.substring(eqIdx + 1).trim();
          if ((v.startsWith('"') && v.endsWith('"')) ||
              (v.startsWith("'") && v.endsWith("'"))) {
            v = v.substring(1, v.length - 1);
          }
          args[k] = v;
        } else {
          // Positional argument fallback: e.g. point(0.2, 0.3)
          if (!args.containsKey('x')) {
            args['x'] = part.trim();
          } else if (!args.containsKey('y')) {
            args['y'] = part.trim();
          }
        }
      }
    }

    onParsed(args);
    return pos;
  }
}
