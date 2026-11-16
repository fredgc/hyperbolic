import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constraints/constraints.dart';
import '../edit.dart';
import '../file_manager.dart';
import '../l10n/l10n_extension.dart';
import '../menus.dart';
import '../objects/objects.dart';
import '../scene/scene_painters.dart';
import '../scene/scene_view.dart';
import '../script.dart';
import '../settings.dart';
import '../sign_in_button.dart';
import '../slider.dart';
import '../splitter.dart';
import '../transform.dart';
import '../tutorial_widget.dart';
import 'number_panel.dart';
import 'tap_to_edit.dart';

/// The main workspace scaffold containing the top menu bar, tool strip,
/// Poincaré disk canvas, responsive splitter, and numeric parameter panel.
class AppWidget extends StatefulWidget {
  final Settings settings;
  final SceneView sceneViewer;
  final FileManager fileManager;
  final MyUndoManager undoManager;
  final MyMenu fileMenu;
  final MyMenu tutorialMenu;
  final EditMenu editMenu;

  AppWidget(this.sceneViewer, this.settings, this.fileManager, {super.key})
    : undoManager = sceneViewer.undoManager,
      fileMenu = fileManager.makeMenu(),
      tutorialMenu = fileManager.makeTutorialMenu(),
      editMenu = EditMenu(sceneViewer, sceneViewer.undoManager);

  @override
  State<AppWidget> createState() => AppWidgetState();
}

class AppWidgetState extends State<AppWidget> {
  final MyMenu viewMenu = MyMenu('View');
  final MyShortcutManager shortcutManager = MyShortcutManager();
  late StreamSubscription _fileListener;
  late StreamSubscription _settingsListener;
  late final MySlider _numberSlider;
  NumberObject? _boundNumber;
  final Map<ToolGroup, HyperbolicTool> _groupActiveTool = {
    for (final g in ToolGroup.values) g: g.tools.first,
  };

  bool get isEditingText => isEditingTextField();

  void selectTool(HyperbolicTool tool) {
    final selectedObj = widget.sceneViewer.selected;
    if ((tool == HyperbolicTool.measureCoordinateX ||
            tool == HyperbolicTool.measureCoordinateY) &&
        selectedObj is PointObject) {
      final coord = tool == HyperbolicTool.measureCoordinateY ? 'y' : 'x';
      widget.sceneViewer.createCoordinateMeasurement(selectedObj.id, coord);
      return;
    }
    if (tool == HyperbolicTool.extendLine &&
        selectedObj is LineObject &&
        selectedObj.lineStyle != LineStyle.fullLine) {
      widget.sceneViewer.extendLine(selectedObj);
      return;
    }
    final group = ToolGroup.forTool(tool);
    setState(() {
      _groupActiveTool[group] = tool;
    });
    widget.sceneViewer.currentTool.value = tool;
    widget.sceneViewer.cancelActiveCreation();
    if (tool != HyperbolicTool.select) {
      widget.sceneViewer.selected = null;
    }
    widget.sceneViewer.updateDefaultNameForCurrentTool();
    widget.sceneViewer.requestRepaintScene();
  }

  void handleEscape() {
    if (widget.sceneViewer.creationFirstPoint != null) {
      widget.sceneViewer.cancelActiveCreation();
    } else if (widget.sceneViewer.selected != null) {
      widget.sceneViewer.selected = null;
      widget.sceneViewer.requestRepaintScene();
    } else {
      selectTool(HyperbolicTool.select);
    }
  }

  void _setupShortcuts() {
    shortcutManager.clear();
    shortcutManager.add(widget.fileMenu);
    shortcutManager.add(widget.tutorialMenu);
    shortcutManager.add(widget.editMenu);
    shortcutManager.add(viewMenu);
    shortcutManager.add(ToolShortcutMapper(this));
  }

  @override
  void initState() {
    super.initState();
    widget.sceneViewer.ensureToolListener();
    _setupViewMenu();
    _setupShortcuts();
    _numberSlider = MySlider('', -10.0, 10.0, 0.0);
    _numberSlider.allowAnimate = false;
    _numberSlider.addListener(_onSliderChanged);

    _fileListener = widget.fileManager.statusStream().listen((_) {
      if (mounted) setState(() {});
    });
    _settingsListener = widget.settings.statusStream().listen((_) {
      if (mounted) {
        widget.sceneViewer.updateSettings();
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(AppWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.sceneViewer.ensureToolListener();
    oldWidget.editMenu.disposeMenu();
    widget.fileMenu.isExpanded = oldWidget.fileMenu.isExpanded;
    widget.tutorialMenu.isExpanded = oldWidget.tutorialMenu.isExpanded;
    widget.editMenu.isExpanded = oldWidget.editMenu.isExpanded;
    _setupViewMenu();
    _setupShortcuts();
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.sceneViewer.ensureToolListener();
    _setupViewMenu();
    _setupShortcuts();
  }

  void _onSliderChanged() {
    if (_boundNumber != null &&
        !_boundNumber!.locked &&
        (_boundNumber!.value - _numberSlider.value).abs() > 1e-9) {
      final newVal = _numberSlider.value;
      final graph = widget.sceneViewer.data.graph;
      final cid = _boundNumber!.constraintId;
      bool handled = false;
      if (cid != null) {
        final c = graph.constraints
            .whereType<CoordinateMeasurementConstraint>()
            .where((cn) => cn.id == cid)
            .firstOrNull;
        if (c != null) {
          final pt = graph.getPoint(c.pointId);
          if (pt != null && !pt.locked) {
            final newPt = c.coordinate == 'x'
                ? HyperbolicPoint(newVal, pt.point.y)
                : c.coordinate == 'y'
                ? HyperbolicPoint(pt.point.x, newVal)
                : pt.point;
            if (newPt.magnitudeSquared < 1.0) {
              graph.dragPoint(c.pointId, newPt);
            }
          }
          handled = true;
        }
      }
      if (!handled) {
        graph.setNumberValue(_boundNumber!.id, newVal);
      }
      if ((_numberSlider.value - _boundNumber!.value).abs() > 1e-6) {
        _numberSlider.value = _boundNumber!.value;
      }
      widget.fileManager.maybeChange();
      widget.sceneViewer.requestRepaintScene();
    }
  }

  void _syncSliderWithSelection() {
    final sel = widget.sceneViewer.selected;
    if (sel is NumberObject) {
      _boundNumber = sel;
      _numberSlider.name = sel.name;
      _numberSlider.min = sel.min;
      _numberSlider.max = sel.max;
      _numberSlider.value = sel.value;
      _numberSlider.allowAnimate = !sel.locked;
    } else {
      _boundNumber = null;
      _numberSlider.name = '';
      _numberSlider.value = 0.0;
      _numberSlider.allowAnimate = false;
    }
  }

  void _setupViewMenu() {
    viewMenu.items = [
      MyMenuItem(
        'Reset View',
        callback: () {
          widget.sceneViewer.transform.resetView();
          widget.sceneViewer.requestRepaintScene();
        },
      ),
      MyMenuItem(
        'Reset Möbius Translation',
        callback: () {
          widget.sceneViewer.transform.resetAll();
          widget.sceneViewer.requestRepaintScene();
        },
      ),
      MyMenuItem(
        'Toggle Axes',
        callback: () {
          widget.sceneViewer.showAxes.value =
              !widget.sceneViewer.showAxes.value;
          widget.sceneViewer.requestRepaintScene();
        },
      ),
    ];
  }

  @override
  void dispose() {
    widget.editMenu.disposeMenu();
    _numberSlider.removeListener(_onSliderChanged);
    _numberSlider.dispose();
    _fileListener.cancel();
    _settingsListener.cancel();
    super.dispose();
  }

  bool _isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 840;

  @override
  Widget build(BuildContext context) {
    widget.fileManager.setContext('AppWidget', context);
    final isNarrow = _isNarrow(context);
    Widget content = PopScope(
      canPop: !widget.fileManager.unsaved.value,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final saved = await widget.fileManager.checkSave(context);
        if (saved && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(isNarrow: isNarrow),
        drawer: Builder(builder: (BuildContext c) => makeMenuDrawer(c)),
        body: Column(
          children: [
            if (isNarrow) _buildCombinedToolbar(),
            Expanded(child: _buildSplitLayout()),
          ],
        ),
      ),
    );
    return shortcutManager.build(
      context,
      FocusScope(
        autofocus: true,
        child: Focus(autofocus: true, child: content),
      ),
    );
  }

  Widget _sceneTitle() {
    final currentTitle = widget.sceneViewer.data.title.isNotEmpty
        ? widget.sceneViewer.data.title
        : widget.fileManager.current.holder.title;
    return TapToEditText('Title', currentTitle, widget.undoManager, (value) {
      if (currentTitle != value) {
        widget.undoManager.add(
          Change<String>('Title', currentTitle, value, (v) {
            setState(() {
              widget.sceneViewer.data.title = v;
              widget.fileManager.current.holder.title = v;
              widget.fileManager.unsaved.value = widget.undoManager.isUnsaved;
            });
          }),
        );
      }
    }, key: const ValueKey('title_text_view'));
  }

  PreferredSizeWidget _buildAppBar({required bool isNarrow}) {
    return AppBar(
      toolbarHeight: 40.0,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            key: const ValueKey('drawer-menu-btn'),
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      titleSpacing: 0.0,
      title: isNarrow
          ? _sceneTitle()
          : Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180.0),
                  child: _sceneTitle(),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildToolbarStrip(),
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, size: 20.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          constraints: const BoxConstraints(),
          tooltip: context.l10n.settingsTooltip,
          onPressed: () => context.push('/settings'),
        ),
        const LanguageMenuButton(buttonKey: ValueKey('language-switcher-btn')),
        PopupMenuButton<String>(
          icon: const Icon(Icons.help_outline, size: 20.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          constraints: const BoxConstraints(),
          tooltip: context.l10n.helpAndGuidesTooltip,
          onSelected: (String route) => context.push(route),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: '/about',
              child: Text(
                '${context.l10n.aboutHyperbolic} v${widget.settings.fullVersion}',
              ),
            ),
            PopupMenuItem<String>(
              value: '/help?page=overview.html',
              child: Text(context.l10n.helpOverview),
            ),
            PopupMenuItem<String>(
              value: '/help?page=objects.html',
              child: Text(context.l10n.helpObjectsGuide),
            ),
            PopupMenuItem<String>(
              value: '/help?page=controls.html',
              child: Text(context.l10n.helpControlsGuide),
            ),
            if (Settings.kDebugEnabled && Settings.debugEnabled)
              PopupMenuItem<String>(
                value: '/help?page=dev/README.html',
                child: Text(context.l10n.helpDeveloperDocs),
              ),
          ],
        ),
        const SizedBox(width: 8.0),
      ],
    );
  }

  Drawer makeMenuDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Row(
            children: [
              IconButton(
                key: const ValueKey('closeDrawerButton'),
                icon: const Icon(Icons.close),
                tooltip: context.l10n.menuCloseMenu,
                onPressed: () => Scaffold.of(context).closeDrawer(),
              ),
              Expanded(
                child: Text(
                  widget.sceneViewer.data.title.isNotEmpty
                      ? widget.sceneViewer.data.title
                      : widget.fileManager.current.holder.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(context.l10n.settingsTitle),
            onTap: () {
              Scaffold.of(context).closeDrawer();
              context.push('/settings');
            },
          ),
          const Divider(),
          widget.fileMenu.buildDrawerList(context),
          widget.tutorialMenu.buildDrawerList(context),
          widget.editMenu.buildDrawerList(context),
          viewMenu.buildDrawerList(context),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.aboutHyperbolic),
            onTap: () {
              Scaffold.of(context).closeDrawer();
              context.push('/about');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(context.l10n.helpAndDocs),
            onTap: () {
              Scaffold.of(context).closeDrawer();
              context.push('/help?page=overview.html');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditControls(SceneObject? obj) {
    widget.sceneViewer.ensureToolListener();
    final colors = SceneView.colorList.value;
    final activeColorValue = obj != null
        ? obj.color
        : widget.sceneViewer.currentColor.toARGB32();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (obj != null)
          TapToEditText(
            '${obj.id}_name',
            obj.name.isEmpty ? '(unnamed)' : obj.name,
            widget.undoManager,
            (newName) {
              if (obj.name != newName) {
                final oldName = obj.name;
                widget.undoManager.add(
                  Change<String>('Rename $oldName', oldName, newName, (v) {
                    obj.name = v;
                    widget.fileManager.maybeChange();
                    widget.sceneViewer.requestRepaintScene();
                  }),
                );
              }
            },
            key: ValueKey('${obj.id}_name'),
          )
        else if (widget.sceneViewer.currentTool.value.defaultNamePrefix != null)
          TapToEditText(
            'next_object_name',
            widget.sceneViewer.currentName.value,
            widget.undoManager,
            (newName) {
              final trimmed = newName.trim();
              if (trimmed.isNotEmpty) {
                widget.sceneViewer.currentName.value = trimmed;
              }
            },
            key: const ValueKey('next_object_name'),
          )
        else
          TapToEditText(
            'object_name',
            '-none-',
            widget.undoManager,
            (_) {},
            key: const ValueKey('object_name'),
          ),
        const SizedBox(width: 4.0),
        MenuAnchor(
          key: const ValueKey('Color-Chooser'),
          builder: (context, controller, child) {
            return IconButton(
              tooltip: 'Color',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: Icon(Icons.palette, color: Color(activeColorValue)),
            );
          },
          menuChildren: [
            for (int i = 0; i < colors.length; i++)
              MenuItemButton(
                key: ValueKey('Color-Chooser-$i'),
                onPressed: () {
                  if (obj != null) {
                    if (obj.color != colors[i].toARGB32()) {
                      final oldCol = obj.color;
                      final newCol = colors[i].toARGB32();
                      widget.undoManager.add(
                        Change<int>('Color ${obj.name}', oldCol, newCol, (v) {
                          obj.color = v;
                          widget.fileManager.maybeChange();
                          widget.sceneViewer.requestRepaintScene();
                        }),
                      );
                      obj.color = newCol;
                      widget.fileManager.maybeChange();
                      widget.sceneViewer.requestRepaintScene();
                    }
                  }
                  widget.sceneViewer.currentColorIndex.value = i;
                  widget.sceneViewer.requestRepaintScene();
                },
                child: Icon(Icons.palette, color: colors[i]),
              ),
          ],
        ),
        if (obj is LineObject && obj.lineStyle != LineStyle.fullLine)
          IconButton(
            key: const ValueKey('extend_line_btn'),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.open_in_full, size: 20.0),
            tooltip: 'Extend to Line (E)',
            onPressed: () => widget.sceneViewer.extendLine(obj),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(
            obj != null && obj.locked ? Icons.lock : Icons.lock_open,
            size: 20.0,
            color: obj != null && obj.locked
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          tooltip: obj != null
              ? (obj.locked
                    ? context.l10n.unlockTooltip
                    : context.l10n.lockTooltip)
              : context.l10n.lockTooltip,
          onPressed: obj != null ? widget.sceneViewer.toggleLockSelected : null,
        ),
      ],
    );
  }

  Widget _wrapTutorialHighlight(
    String highlightId,
    Widget child, {
    bool foreground = false,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  }) {
    return ValueListenableBuilder<TutorialController?>(
      valueListenable: widget.fileManager.activeTutorial,
      builder: (context, controller, _) {
        if (controller == null) return child;
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return TutorialHighlight(
              highlightId: highlightId,
              activeHighlightId: controller.currentHighlightId,
              foreground: foreground,
              borderRadius: borderRadius,
              child: child,
            );
          },
        );
      },
    );
  }

  Widget _buildToolGroupButton(ToolGroup group, HyperbolicTool activeTool) {
    final currentGroupTool = _groupActiveTool[group] ?? group.tools.first;
    final isGroupActive = group.tools.contains(activeTool);
    final groupLabel = group.localizedLabel(context.l10n);

    return Container(
      decoration: BoxDecoration(
        color: isGroupActive
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isGroupActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _wrapTutorialHighlight(
            'tool.${currentGroupTool.name}',
            ChoiceChip(
              key: ValueKey('tool_chip_${group.name}'),
              tooltip: currentGroupTool.shortcutKey != null
                  ? '${currentGroupTool.localizedLabel(context.l10n)} (${currentGroupTool.shortcutKey})'
                  : currentGroupTool.localizedLabel(context.l10n),
              avatar: isGroupActive
                  ? Icon(currentGroupTool.icon, size: 16.0)
                  : null,
              label: isGroupActive
                  ? Text(
                      currentGroupTool.localizedLabel(context.l10n),
                      style: const TextStyle(fontSize: 12.0),
                    )
                  : Icon(
                      currentGroupTool.icon,
                      size: 16.0,
                      semanticLabel: currentGroupTool.localizedLabel(
                        context.l10n,
                      ),
                    ),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              labelPadding: isGroupActive
                  ? const EdgeInsets.only(right: 4.0)
                  : EdgeInsets.zero,
              selected: activeTool == currentGroupTool,
              onSelected: (selected) {
                selectTool(currentGroupTool);
              },
            ),
          ),
          if (group.tools.length > 1)
            PopupMenuButton<Object>(
              key: ValueKey('tool_group_menu_${group.name}'),
              icon: const Icon(Icons.arrow_drop_down, size: 16.0),
              tooltip: context.l10n.toolGroupOptionsTooltip(groupLabel),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 18.0,
                minHeight: 28.0,
              ),
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                minimumSize: const Size(18.0, 28.0),
              ),
              onSelected: (value) {
                if (value == 'reset_view') {
                  widget.sceneViewer.transform.resetAll();
                  widget.sceneViewer.requestRepaintScene();
                } else if (value is HyperbolicTool) {
                  selectTool(value);
                }
              },
              itemBuilder: (context) {
                return [
                  for (final tool in group.tools)
                    PopupMenuItem<Object>(
                      value: tool,
                      child: Row(
                        children: [
                          Icon(
                            tool.icon,
                            size: 18.0,
                            color: activeTool == tool
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            tool.shortcutKey != null
                                ? '${tool.localizedLabel(context.l10n)} (${tool.shortcutKey})'
                                : tool.localizedLabel(context.l10n),
                            style: TextStyle(
                              fontWeight: activeTool == tool
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: activeTool == tool
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (group == ToolGroup.navigate) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem<Object>(
                      value: 'reset_view',
                      child: Row(
                        children: [
                          const Icon(Icons.restart_alt, size: 18.0),
                          const SizedBox(width: 8.0),
                          Text(context.l10n.resetViewTooltip),
                        ],
                      ),
                    ),
                  ],
                ];
              },
            ),
        ],
      ),
    );
  }

  Widget _buildToolbarStrip() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.sceneViewer.repaintCounter,
        widget.sceneViewer.currentTool,
        widget.sceneViewer.currentColorIndex,
        widget.sceneViewer.currentName,
      ]),
      builder: (context, _) {
        final activeTool = widget.sceneViewer.currentTool.value;
        final activeGroup = ToolGroup.forTool(activeTool);
        _groupActiveTool[activeGroup] = activeTool;
        final obj = widget.sceneViewer.selected;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final group in ToolGroup.canvasGroups) ...[
                _buildToolGroupButton(group, activeTool),
                const SizedBox(width: 4.0),
              ],
              const SizedBox(width: 4.0),
              const SizedBox(
                height: 24.0,
                child: VerticalDivider(width: 1.0, thickness: 1.0),
              ),
              const SizedBox(width: 8.0),
              _buildEditControls(obj),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCombinedToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: _buildToolbarStrip(),
    );
  }

  Widget _buildSplitLayout() {
    final media = MediaQuery.of(context);
    final isLandscape = media.size.width > media.size.height;

    return SplitterWidget(
      direction: isLandscape ? Axis.horizontal : Axis.vertical,
      top: (context) => _buildCanvasWithSlider(),
      bottom: (context) => NumberPanel(scene: widget.sceneViewer),
      setter: (size) {},
      initialSize: isLandscape ? 300.0 : 200.0,
      background: Theme.of(context).colorScheme.surface,
      outline: Theme.of(context).dividerColor.withOpacity(0.4),
    );
  }

  Widget _buildCanvasWithSlider() {
    return Column(
      children: [
        Expanded(child: _buildCanvas()),
        _buildBottomSlider(),
      ],
    );
  }

  Widget _buildBottomSlider() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.sceneViewer.repaintCounter,
        widget.sceneViewer.currentTool,
      ]),
      builder: (context, _) {
        _syncSliderWithSelection();
        final isEnabled = _boundNumber != null && !_boundNumber!.locked;
        final prompt =
            widget.sceneViewer.localizedPrompt(context.l10n) ??
            widget.sceneViewer.currentPrompt;
        final activeTool = widget.sceneViewer.currentTool.value;

        final sliderContainer = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.35),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
          ),
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.45,
            child: IgnorePointer(
              ignoring: !isEnabled || prompt != null,
              child: MySlider.buildTable(context, [_numberSlider]),
            ),
          ),
        );

        if (prompt == null) {
          return sliderContainer;
        }

        return Stack(
          children: [
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: sliderContainer,
            ),
            Positioned.fill(
              child: Container(
                key: const ValueKey('constructor_prompt_banner'),
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      activeTool.icon,
                      size: 18.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      activeTool.localizedLabel(context.l10n),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      ' — ',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        prompt,
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.sceneViewer.creationFirstObjId != null)
                      TextButton.icon(
                        onPressed: widget.sceneViewer.cancelActiveCreation,
                        icon: const Icon(Icons.cancel_outlined, size: 16.0),
                        label: Text(
                          context.l10n.cancel,
                          style: const TextStyle(fontSize: 12.0),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCanvas() {
    return ValueListenableBuilder<TutorialController?>(
      valueListenable: widget.fileManager.activeTutorial,
      builder: (context, controller, _) {
        Widget canvasWidget = AnimatedBuilder(
          animation: widget.sceneViewer.repaintCounter,
          builder: (context, child) {
            return MouseRegion(
              onExit: (_) => widget.sceneViewer.onPointerLeave(),
              child: Listener(
                key: const ValueKey('poincare_canvas'),
                onPointerDown: widget.sceneViewer.onPointerDown,
                onPointerMove: widget.sceneViewer.onPointerMove,
                onPointerUp: widget.sceneViewer.onPointerUp,
                onPointerSignal: widget.sceneViewer.onPointerSignal,
                onPointerPanZoomUpdate:
                    widget.sceneViewer.onPointerPanZoomUpdate,
                child: CustomPaint(
                  key: const ValueKey('disk_painter'),
                  painter: DiskPainter(
                    widget.sceneViewer,
                    repaint: widget.sceneViewer.repaintCounter,
                  ),
                  size: Size.infinite,
                ),
              ),
            );
          },
        );

        if (controller != null) {
          canvasWidget = TutorialCanvasOverlay(
            scene: widget.sceneViewer,
            controller: controller,
            child: canvasWidget,
          );
        }

        return Stack(
          children: [
            Positioned.fill(child: canvasWidget),
            if (controller != null)
              Positioned(
                top: 16,
                right: 16,
                child: TutorialCard(
                  controller: controller,
                  onClose: () =>
                      widget.fileManager.closeTutorial(keepScene: false),
                  onFinish: widget.fileManager.finishTutorial,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ToolIntent extends Intent {
  final HyperbolicTool tool;
  const _ToolIntent(this.tool);
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _LockIntent extends Intent {
  const _LockIntent();
}

class _DeleteIntent extends Intent {
  const _DeleteIntent();
}

class _ResetViewIntent extends Intent {
  const _ResetViewIntent();
}

class _NonEditingCallbackAction<T extends Intent> extends CallbackAction<T> {
  final AppWidgetState appState;
  _NonEditingCallbackAction(this.appState, {required super.onInvoke});

  @override
  bool isEnabled(T intent) => !appState.isEditingText;
}

class ToolShortcutMapper implements ShortcutMapper {
  final AppWidgetState appState;
  ToolShortcutMapper(this.appState);

  @override
  void register(
    Map<Type, Action<Intent>> actionMap,
    Map<ShortcutActivator, Intent> shortcutMap,
  ) {
    actionMap[_ToolIntent] = _NonEditingCallbackAction<_ToolIntent>(
      appState,
      onInvoke: (intent) {
        appState.selectTool(intent.tool);
        return null;
      },
    );
    actionMap[_EscapeIntent] = _NonEditingCallbackAction<_EscapeIntent>(
      appState,
      onInvoke: (intent) {
        appState.handleEscape();
        return null;
      },
    );
    actionMap[_LockIntent] = _NonEditingCallbackAction<_LockIntent>(
      appState,
      onInvoke: (intent) {
        appState.widget.sceneViewer.toggleLockSelected();
        return null;
      },
    );
    actionMap[_DeleteIntent] = _NonEditingCallbackAction<_DeleteIntent>(
      appState,
      onInvoke: (intent) {
        appState.widget.sceneViewer.deleteSelected();
        return null;
      },
    );
    actionMap[_ResetViewIntent] = _NonEditingCallbackAction<_ResetViewIntent>(
      appState,
      onInvoke: (intent) {
        appState.widget.sceneViewer.transform.resetAll();
        appState.widget.sceneViewer.requestRepaintScene();
        return null;
      },
    );

    // Escape -> select tool / deselect / cancel creation
    shortcutMap[const SingleActivator(LogicalKeyboardKey.escape)] =
        const _EscapeIntent();

    // Tools
    final toolKeys = <LogicalKeyboardKey, HyperbolicTool>{
      LogicalKeyboardKey.keyL: HyperbolicTool.line,
      LogicalKeyboardKey.keyS: HyperbolicTool.segment,
      LogicalKeyboardKey.keyP: HyperbolicTool.point,
      LogicalKeyboardKey.keyC: HyperbolicTool.circle,
      LogicalKeyboardKey.keyR: HyperbolicTool.ray,
      LogicalKeyboardKey.keyE: HyperbolicTool.extendLine,
      LogicalKeyboardKey.keyM: HyperbolicTool.midpoint,
      LogicalKeyboardKey.keyI: HyperbolicTool.intersection,
      LogicalKeyboardKey.keyD: HyperbolicTool.measureDistance,
      LogicalKeyboardKey.keyA: HyperbolicTool.measureAngle,
      LogicalKeyboardKey.keyH: HyperbolicTool.moveDisk,
    };

    for (final entry in toolKeys.entries) {
      shortcutMap[SingleActivator(entry.key)] = _ToolIntent(entry.value);
    }

    // Lock toggle: K
    shortcutMap[const SingleActivator(LogicalKeyboardKey.keyK)] =
        const _LockIntent();

    // Reset view: Home
    shortcutMap[const SingleActivator(LogicalKeyboardKey.home)] =
        const _ResetViewIntent();

    // Delete keys
    shortcutMap[const SingleActivator(LogicalKeyboardKey.delete)] =
        const _DeleteIntent();
    shortcutMap[const SingleActivator(LogicalKeyboardKey.backspace)] =
        const _DeleteIntent();
  }
}
