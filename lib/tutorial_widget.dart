import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import 'l10n/l10n_extension.dart';

import 'scene/scene_view.dart';
import 'script.dart';
import 'transform.dart';

/// Parses LaTeX syntax in Markdown into 'latex' AST elements.
class TutorialLatexInlineSyntax extends md.InlineSyntax {
  TutorialLatexInlineSyntax()
    : super(
        r'(\$\$((?:\\.|[^\\$])+?)\$\$)|'
        r'(\\\[((?:\\.|[^\\])+?)\\\])|'
        r'(\\\(((?:\\.|[^\\])+?)\\\))|'
        r'''(\$([^\s$](?:\\.|[^\\\n$])*?[^\s$]|\S)\$)(?=[\s)\],;:?!"'~.\-’”»›）］｝！？。，：；]|$)''',
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match.group(0) ?? '';
    final bool isDisplay = raw.startsWith(r'$$') || raw.startsWith(r'\[');
    final int delimiterLength =
        (raw.startsWith(r'$$') ||
            raw.startsWith(r'\[') ||
            raw.startsWith(r'\('))
        ? 2
        : 1;
    final equation = raw.substring(
      delimiterLength,
      raw.length - delimiterLength,
    );

    final element = md.Element.text('latex', equation);
    element.attributes['MathStyle'] = isDisplay ? 'display' : 'text';
    parser.addNode(element);
    return true;
  }
}

/// Renders 'latex' AST elements using [Math.tex] from flutter_math_fork.
class TutorialLatexElementBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;
  final double? textScaleFactor;

  TutorialLatexElementBuilder({this.textStyle, this.textScaleFactor});

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final String text = element.textContent;
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isDisplay = element.attributes['MathStyle'] == 'display';
    final mathStyle = isDisplay ? MathStyle.display : MathStyle.text;
    final effectiveStyle = textStyle ?? parentStyle ?? preferredStyle;

    final Widget mathWidget = Math.tex(
      text,
      textStyle: effectiveStyle,
      mathStyle: mathStyle,
      textScaleFactor: textScaleFactor,
      onErrorFallback: (err) => Text(text, style: effectiveStyle),
    );

    if (isDisplay) {
      return Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: mathWidget,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: [
          WidgetSpan(alignment: PlaceholderAlignment.middle, child: mathWidget),
        ],
      ),
    );
  }
}

/// Floating, draggable, and minimizable tutorial overlay card.
class TutorialCard extends StatefulWidget {
  final TutorialController controller;
  final VoidCallback onClose;
  final VoidCallback? onFinish;

  const TutorialCard({
    super.key,
    required this.controller,
    required this.onClose,
    this.onFinish,
  });

  @override
  State<TutorialCard> createState() => _TutorialCardState();
}

class _TutorialCardState extends State<TutorialCard> {
  Offset _offset = Offset.zero;
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final controller = widget.controller;

        if (controller.isCompleted) {
          return Transform.translate(
            offset: _offset,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tutorial Completed!",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Great job! You have completed all steps in ${controller.tutorial.title}. You can now continue playing with the scene.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const ValueKey('tutorial-finish-btn'),
                      onPressed: widget.onFinish ?? widget.onClose,
                      child: const Text("Finish (Keep Scene)"),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_isMinimized) {
          return Transform.translate(
            offset: _offset,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _offset += details.delta;
                });
              },
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: colorScheme.surfaceVariant,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _isMinimized = false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.tutorialStepCounterCompact(
                            controller.currentStepIndex + 1,
                            controller.tutorial.steps.length,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.open_in_full,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final step = controller.currentStep;
        if (step == null) return const SizedBox.shrink();

        final isSatisfied = controller.isCurrentStepSatisfied;
        final isContinueEnabled = controller.isContinueEnabled;

        return Transform.translate(
          offset: _offset,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSatisfied
                    ? Colors.green.shade600
                    : colorScheme.outline.withOpacity(0.3),
                width: isSatisfied ? 2.0 : 1.0,
              ),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 360,
                maxHeight:
                    (MediaQuery.maybeSizeOf(context)?.height ?? 600) - 32,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Drag Handle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      setState(() {
                        _offset += details.delta;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "TUTORIAL",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.tutorialStepCounter(
                              controller.currentStepIndex + 1,
                              controller.tutorial.steps.length,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          tooltip: context.l10n.tutorialMinimizeTooltip,
                          onPressed: () => setState(() => _isMinimized = true),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: context.l10n.tutorialResetStepTooltip,
                          onPressed: controller.resetCurrentStep,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: context.l10n.tutorialCloseTooltip,
                          onPressed: widget.onClose,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: controller.progress,
                      minHeight: 4,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSatisfied
                            ? Colors.green.shade600
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Step Title & Body (Scrollable if overflowing screen)
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          MarkdownBody(
                            data: step.body,
                            shrinkWrap: true,
                            extensionSet: md.ExtensionSet.gitHubFlavored,
                            blockSyntaxes: [LatexBlockSyntax()],
                            inlineSyntaxes: [TutorialLatexInlineSyntax()],
                            builders: {
                              'latex': TutorialLatexElementBuilder(
                                textStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.35,
                                ),
                              ),
                            },
                            styleSheet: MarkdownStyleSheet.fromTheme(theme)
                                .copyWith(
                                  p: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 8),

                          // Directives Status Checklist
                          for (final d in step.directives.where(
                            (d) => !d.isSetupAction,
                          ))
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    d.isSatisfied(controller.scene)
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: d.isSatisfied(controller.scene)
                                        ? Colors.green.shade600
                                        : colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      d.statusText(controller.scene),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            d.isSatisfied(controller.scene)
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                        color: d.isSatisfied(controller.scene)
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      if (controller.currentStepIndex > 0)
                        OutlinedButton(
                          onPressed: controller.previousStep,
                          child: Text(context.l10n.tutorialBack),
                        ),
                      const Spacer(),
                      if (controller.canDoItForMe)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: TextButton(
                            key: const ValueKey('tutorial-do-it-for-me-btn'),
                            onPressed: controller.doItForMe,
                            child: Text(context.l10n.tutorialDoItForMe),
                          ),
                        ),
                      ElevatedButton(
                        key: const ValueKey('tutorial-next-btn'),
                        onPressed: isContinueEnabled
                            ? controller.nextStep
                            : null,
                        child: Text(
                          controller.currentStepIndex <
                                  controller.tutorial.steps.length - 1
                              ? context.l10n.tutorialContinue
                              : context.l10n.tutorialFinish,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Provides a repeating pulse animation value from 0.0 to 1.0.
class TutorialPulseBuilder extends StatefulWidget {
  final bool enabled;
  final Widget Function(BuildContext context, double pulse) builder;

  const TutorialPulseBuilder({
    super.key,
    required this.enabled,
    required this.builder,
  });

  @override
  State<TutorialPulseBuilder> createState() => _TutorialPulseBuilderState();
}

class _TutorialPulseBuilderState extends State<TutorialPulseBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(TutorialPulseBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (!widget.enabled) {
      _animController.stop();
      _animController.value = 0.0;
    } else if (TutorialHighlight.shouldAnimate()) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else {
      _animController.stop();
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.builder(context, 0.0);
    }
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final pulse = Curves.easeInOut.transform(_animController.value);
        return widget.builder(context, pulse);
      },
    );
  }
}

/// Wraps a control widget with an animated pulsing highlight border and glow.
class TutorialHighlight extends StatefulWidget {
  static bool? forceAnimationInTests;

  static bool shouldAnimate() {
    if (forceAnimationInTests != null) return forceAnimationInTests!;
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return !bindingName.contains('TestWidgetsFlutterBinding');
  }

  final String highlightId;
  final String? activeHighlightId;
  final Widget child;
  final BorderRadius borderRadius;
  final bool foreground;

  const TutorialHighlight({
    super.key,
    required this.highlightId,
    required this.activeHighlightId,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.foreground = false,
  });

  @override
  State<TutorialHighlight> createState() => _TutorialHighlightState();
}

class _TutorialHighlightState extends State<TutorialHighlight> {
  bool get _isHighlighted =>
      widget.activeHighlightId != null &&
      widget.activeHighlightId == widget.highlightId;

  @override
  Widget build(BuildContext context) {
    return TutorialPulseBuilder(
      enabled: _isHighlighted,
      builder: (context, pulse) {
        if (!_isHighlighted || pulse <= 0.01) {
          return widget.child;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accentColor = isDark
            ? Colors.amberAccent.shade400
            : Colors.deepOrangeAccent.shade400;

        return Container(
          decoration: BoxDecoration(
            color: widget.foreground
                ? accentColor.withOpacity(0.14 * pulse)
                : accentColor.withOpacity(0.35 * pulse),
            border: Border.all(
              color: accentColor.withOpacity(pulse),
              width: 2.5,
            ),
            borderRadius: widget.borderRadius,
            boxShadow: (!widget.foreground && pulse > 0.05)
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.55 * pulse),
                      blurRadius: 8.0 * pulse,
                      spreadRadius: 1.5 * pulse,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Renders a pulsing target ring directly on the Poincaré disk canvas
/// when [controller.highlightedPoint] is non-null.
class TutorialCanvasOverlay extends StatelessWidget {
  final SceneView scene;
  final TutorialController controller;
  final Widget child;

  const TutorialCanvasOverlay({
    super.key,
    required this.scene,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, scene.repaintCounter]),
      builder: (context, _) {
        final targetPoint = controller.highlightedPoint;
        if (targetPoint == null) return child;

        return TutorialPulseBuilder(
          enabled: true,
          builder: (context, pulse) {
            return CustomPaint(
              foregroundPainter: _TutorialCanvasHighlightPainter(
                scene: scene,
                targetPoint: targetPoint,
                pulse: pulse,
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}

class _TutorialCanvasHighlightPainter extends CustomPainter {
  final SceneView scene;
  final HyperbolicPoint targetPoint;
  final double pulse;

  _TutorialCanvasHighlightPainter({
    required this.scene,
    required this.targetPoint,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = pulse.clamp(0.0, 1.0);
    if (p <= 0.01) return;

    final transform = scene.transform;
    final viewPt = transform.diskToView(targetPoint);
    final screenPt = transform.viewToScreen(viewPt);

    final glowPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.5 * p)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 + 8.0 * (1.0 - p);

    final radius = 16.0 + 10.0 * (1.0 - p);
    canvas.drawCircle(screenPt, radius, glowPaint);

    final centerPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(p)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(screenPt, 4.0, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _TutorialCanvasHighlightPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.targetPoint != targetPoint;
}
