import 'package:flutter/material.dart';

import '../edit.dart';
import '../l10n/l10n_extension.dart';
import '../name.dart';
import '../objects/objects.dart';
import '../scene/scene_view.dart';

/// Panel displaying the list of all Number objects with editable values,
/// units, lock toggles, and animated interactive sliders.
class NumberPanel extends StatefulWidget {
  final SceneView scene;

  const NumberPanel({super.key, required this.scene});

  @override
  State<NumberPanel> createState() => _NumberPanelState();
}

class _NumberPanelState extends State<NumberPanel> {
  String _shortUnit(NumberUnit unit) {
    switch (unit) {
      case NumberUnit.distance:
        return 'ρ';
      case NumberUnit.angleRadians:
        return 'rad';
      case NumberUnit.angleDegrees:
        return '°';
      case NumberUnit.coordinate:
        return '';
      case NumberUnit.scalar:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.scene.repaintCounter,
        widget.scene.currentTool,
      ]),
      builder: (context, child) {
        final numbers = widget.scene.data.objects
            .whereType<NumberObject>()
            .toList();
        final activeTool = widget.scene.currentTool.value;
        final isMeasureToolActive = ToolGroup.measure.tools.contains(
          activeTool,
        );

        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Number Constructor menu
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 18.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        context.l10n.parametersTitle,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isMeasureToolActive
                            ? Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withOpacity(0.3)
                            : null,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isMeasureToolActive
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.5)
                              : Theme.of(context).dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMeasureToolActive)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 6.0,
                                right: 2.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    activeTool.icon,
                                    size: 15.0,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    activeTool.localizedLabel(context.l10n),
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 24.0,
                              minHeight: 28.0,
                            ),
                            style: IconButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            tooltip: context.l10n.addFreeParameterTooltip,
                            onPressed: _addFreeNumber,
                          ),
                          PopupMenuButton<Object>(
                            key: const ValueKey('number_constructor_menu'),
                            icon: const Icon(Icons.arrow_drop_down, size: 16.0),
                            tooltip: context.l10n.toolGroupOptionsTooltip(
                              ToolGroup.measure.localizedLabel(context.l10n),
                            ),
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
                            onSelected: _onNumberConstructorSelected,
                            itemBuilder: (context) => [
                              PopupMenuItem<Object>(
                                value: 'free_number',
                                child: Row(
                                  children: [
                                    const Icon(Icons.add, size: 18.0),
                                    const SizedBox(width: 8.0),
                                    Text(context.l10n.addFreeParameterTooltip),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              for (final tool in ToolGroup.measure.tools)
                                PopupMenuItem<Object>(
                                  value: tool,
                                  child: Row(
                                    children: [
                                      Icon(
                                        tool.icon,
                                        size: 18.0,
                                        color: activeTool == tool
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
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
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable list
              Expanded(
                child: numbers.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.noParametersMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12.0,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: numbers.length,
                        itemBuilder: (context, index) {
                          final numObj = numbers[index];
                          final isSelected = widget.scene.selected == numObj;
                          return _buildNumberTile(numObj, isSelected);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumberTile(NumberObject numObj, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor.withOpacity(0.3),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () {
          widget.scene.selectObject(numObj);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            children: [
              // Color dot
              Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: Color(numObj.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8.0),

              // Name
              Expanded(
                child: Text(
                  numObj.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Value display
              Text(
                _shortUnit(numObj.unit).isNotEmpty
                    ? '${numObj.value.toStringAsFixed(3)} ${_shortUnit(numObj.unit)}'
                    : numObj.value.toStringAsFixed(3),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13.0,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8.0),

              // Lock button
              Tooltip(
                message: numObj.locked
                    ? context.l10n.unlockTooltip
                    : context.l10n.lockTooltip,
                child: InkWell(
                  onTap: () {
                    final prev = numObj.locked;
                    widget.scene.undoManager.add(
                      UndoCallback(
                        '${!prev ? "Lock" : "Unlock"} ${numObj.name}',
                        undoCallback: () {
                          numObj.locked = prev;
                          widget.scene.requestRepaintScene();
                        },
                        redoCallback: () {
                          numObj.locked = !prev;
                          widget.scene.requestRepaintScene();
                        },
                      ),
                    );
                    widget.scene.fileManager.maybeChange();
                    widget.scene.requestRepaintScene();
                  },
                  child: Icon(
                    numObj.locked ? Icons.lock : Icons.lock_open,
                    size: 16.0,
                    color: numObj.locked
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6.0),

              // Delete button
              Tooltip(
                message: context.l10n.deleteParameterTooltip,
                child: InkWell(
                  onTap: () {
                    final removedConstraints = widget
                        .scene
                        .data
                        .graph
                        .constraints
                        .where(
                          (c) =>
                              c.inputIds.contains(numObj.id) ||
                              c.outputIds.contains(numObj.id),
                        )
                        .toList();
                    if (widget.scene.selected == numObj) {
                      widget.scene.selected = null;
                    }
                    widget.scene.undoManager.add(
                      UndoCallback(
                        'Delete ${numObj.name}',
                        undoCallback: () {
                          widget.scene.data.graph.addObject(numObj);
                          for (final c in removedConstraints) {
                            widget.scene.data.graph.addConstraint(c);
                          }
                          widget.scene.data.graph.evaluateAll();
                          widget.scene.requestRepaintScene();
                        },
                        redoCallback: () {
                          widget.scene.data.graph.removeObject(numObj.id);
                          widget.scene.requestRepaintScene();
                        },
                      ),
                    );
                    widget.scene.fileManager.maybeChange();
                    widget.scene.requestRepaintScene();
                  },
                  child: Icon(
                    Icons.close,
                    size: 16.0,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNumberConstructorSelected(Object value) {
    if (value == 'free_number') {
      _addFreeNumber();
      return;
    }
    if (value is HyperbolicTool) {
      final selectedObj = widget.scene.selected;
      if ((value == HyperbolicTool.measureCoordinateX ||
              value == HyperbolicTool.measureCoordinateY) &&
          selectedObj is PointObject) {
        final coord = value == HyperbolicTool.measureCoordinateY ? 'y' : 'x';
        widget.scene.createCoordinateMeasurement(selectedObj.id, coord);
        return;
      }
      widget.scene.currentTool.value = value;
      widget.scene.cancelActiveCreation();
      widget.scene.selected = null;
      widget.scene.updateDefaultNameForCurrentTool();
      widget.scene.requestRepaintScene();
    }
  }

  void _addFreeNumber() {
    final name = NameGuess.nextAvailableName(
      'r1',
      widget.scene.data.objects.map((o) => o.name),
    );
    final id = SceneView.nextObjectId('num');
    final numObj = NumberObject(
      id: id,
      name: name,
      value: 1.0,
      min: 0.0,
      max: 5.0,
      unit: NumberUnit.distance,
    );

    widget.scene.undoManager.add(
      UndoCallback(
        'Add Parameter $name',
        undoCallback: () {
          widget.scene.data.graph.removeObject(id);
          widget.scene.requestRepaintScene();
        },
        redoCallback: () {
          widget.scene.data.graph.addObject(numObj);
          widget.scene.selectObject(numObj);
          widget.scene.requestRepaintScene();
        },
      ),
    );
    widget.scene.fileManager.maybeChange();
    widget.scene.requestRepaintScene();
  }
}
