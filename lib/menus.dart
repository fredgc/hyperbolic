import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/l10n_extension.dart';
import "printer.dart";

bool isEditingTextField() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return context.widget is EditableText ||
      context.findAncestorWidgetOfExactType<EditableText>() != null ||
      context.findAncestorWidgetOfExactType<TextField>() != null;
}

class _MenuItemAction extends Action<MyMenuItem> {
  @override
  bool isEnabled(MyMenuItem intent) => !isEditingTextField();

  @override
  Object? invoke(MyMenuItem intent) {
    if (intent.isEnabled) intent.callback?.call();
    return null;
  }
}

class _ChoiceAction<T extends Object> extends Action<_ChoiceIntent<T>> {
  @override
  bool isEnabled(_ChoiceIntent<T> intent) => !isEditingTextField();

  @override
  Object? invoke(_ChoiceIntent<T> intent) {
    intent.menu.value = intent.item;
    return null;
  }
}

class MyShortcutManager {
  List<ShortcutMapper> menus = [];

  void add(ShortcutMapper menu) {
    menus.add(menu);
  }

  void clear() {
    menus.clear();
  }

  Widget build(BuildContext context, Widget child) {
    Map<Type, Action<Intent>> actions = {};
    Map<ShortcutActivator, Intent> shortcuts = {};
    for (var menu in menus) {
      menu.register(actions, shortcuts);
    }

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(actions: actions, child: child),
    );
  }

  void dumpShortcuts() {
    Map<Type, Action<Intent>> actions = {};
    Map<ShortcutActivator, Intent> shortcuts = {};
    for (var menu in menus) {
      menu.register(actions, shortcuts);
    }
    Log.menus.log("GREEN: Here are all the shortcuts -----------------");
    List<ShortcutActivator> keys = shortcuts.keys.toList();
    int compare(a, b) {
      if (a is SingleActivator && b is SingleActivator) {
        int diff = a.trigger.keyLabel.compareTo(b.trigger.keyLabel);
        if (diff == 0) {
          if (a.control == b.control) return 0;
          if (a.control) return -1;
          return 1;
        }
        return diff;
      }
      return a.toString().compareTo(b.toString());
    }

    keys.sort(compare);
    ShortcutActivator? prev;
    for (var s in keys) {
      if (compare(s, prev) == 0) {
        Log.menus.log(" RED: This matches previous.");
      }
      prev = s;
      Intent intent = shortcuts[s]!;
      Action? action = actions[intent.runtimeType];
      Log.menus.log(" Shortcut $s maps to $intent, to action=$action");
    }
  }
}

abstract class ShortcutMapper {
  void register(
    Map<Type, Action<Intent>> actionMap,
    Map<ShortcutActivator, Intent> shortcutMap,
  );
}

abstract class HasShortcut {
  MenuSerializableShortcut? get shortcut;
}

String localizedTitle(BuildContext context, String rawTitle) {
  try {
    final l10n = context.l10n;
    switch (rawTitle) {
      case 'File':
        return l10n.menuFile;
      case 'Edit':
        return l10n.menuEdit;
      case 'View':
        return l10n.menuView;
      case 'Tutorials':
        return l10n.menuTutorials;
      case 'New':
        return l10n.menuNew;
      case 'Open':
        return l10n.menuOpen;
      case 'Reload':
        return l10n.menuReload;
      case 'Save':
        return l10n.menuSave;
      case 'Save As':
        return l10n.menuSaveAs;
      case 'Edit Description':
        return l10n.editDescription;
      case 'Share':
        return l10n.menuShare;
      case 'Log Out':
        return l10n.menuLogOut;
      case 'Undo':
        return l10n.menuUndo;
      case 'Redo':
        return l10n.menuRedo;
      case 'Cut':
        return l10n.menuCut;
      case 'Copy':
        return l10n.menuCopy;
      case 'Paste':
        return l10n.menuPaste;
      case 'Delete':
        return l10n.menuDelete;
      case 'Reset View':
        return l10n.menuResetView;
      case 'Reset Möbius Translation':
        return l10n.menuResetMobius;
      case 'Toggle Axes':
        return l10n.menuToggleAxes;
    }
  } catch (_) {}
  return rawTitle;
}

class MyMenu with ChangeNotifier implements ShortcutMapper {
  final String title;
  List<MyMenuItem> items = [];
  bool isExpanded = false;
  MyMenu(this.title);

  @override
  void register(
    Map<Type, Action<Intent>> actionMap,
    Map<ShortcutActivator, Intent> shortcutMap,
  ) {
    for (var item in items) {
      item.register(actionMap, shortcutMap);
    }
  }

  void rebuild() {
    notifyListeners();
  }

  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext context, Widget? child) {
        return SubmenuButton(
          menuChildren: items
              .map((item) => item.makeMenuButton(context))
              .toList(),
          child: Text(localizedTitle(context, title)),
        );
      },
    );
  }

  Widget buildDrawerList(
    BuildContext context, [
    bool? initiallyExpanded,
    Widget Function(BuildContext, Widget)? titleWrapper,
    Widget Function(BuildContext, MyMenuItem, Widget)? itemWrapper,
  ]) {
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext context, Widget? child) {
        Widget titleWidget = Text(localizedTitle(context, title));
        if (titleWrapper != null) {
          titleWidget = titleWrapper(context, titleWidget);
        }
        return ExpansionTile(
          title: titleWidget,
          initiallyExpanded: initiallyExpanded ?? isExpanded,
          onExpansionChanged: (expanded) {
            isExpanded = expanded;
            notifyListeners();
          },
          childrenPadding: const EdgeInsets.only(left: 10),
          children: items.map((item) {
            Widget btn = item.makeMenuButton(context);
            if (itemWrapper != null) {
              btn = itemWrapper(context, item, btn);
            }
            return btn;
          }).toList(),
        );
      },
    );
  }
}

class MyMenuItem extends Intent implements ShortcutMapper, HasShortcut {
  @override
  final MenuSerializableShortcut? shortcut;
  final VoidCallback? callback;
  final String name;
  final String tip;

  final bool Function()? isEnabledCallback;
  bool get isEnabled =>
      isEnabledCallback == null ? true : isEnabledCallback!.call();

  const MyMenuItem.logical(
    this.name, {
    this.callback,
    this.shortcut,
    this.tip = "",
    this.isEnabledCallback,
  });

  MyMenuItem(
    this.name, {
    this.callback,
    LogicalKeyboardKey? key,
    this.tip = "",
    this.isEnabledCallback,
  }) : shortcut = key == null ? null : SingleActivator(key, control: true);

  @override
  void register(
    Map<Type, Action<Intent>> actionMap,
    Map<ShortcutActivator, Intent> shortcutMap,
  ) {
    if (shortcut == null) return;
    actionMap[MyMenuItem] = _MenuItemAction();
    shortcutMap[shortcut!] = this;
  }

  Widget makeMenuButtonNoTip(BuildContext context) {
    return MenuItemButton(
      overflowAxis: Axis.vertical,
      shortcut: shortcut,
      onPressed: !isEnabled
          ? null
          : () {
              Scaffold.of(context).closeDrawer();
              onPressed();
            },
      child: Text(
        localizedTitle(context, name),
        softWrap: false,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isEnabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
        ),
      ),
    );
  }

  Widget makeMenuButton(BuildContext context) {
    if (tip.isEmpty) {
      return makeMenuButtonNoTip(context);
    } else {
      return Tooltip(
        message: tip,
        waitDuration: const Duration(seconds: 3),
        child: makeMenuButtonNoTip(context),
      );
    }
  }

  static void callCallback(Intent intent) {
    MyMenuItem here = intent as MyMenuItem;
    if (here.isEnabled) here.callback?.call();
  }

  void onPressed() {
    if (isEnabled) callback?.call();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => name;
}

class MyMenuSpacer extends MyMenuItem {
  MyMenuSpacer() : super("");

  @override
  Widget makeMenuButton(BuildContext context) => const Divider();
}

Widget toText(Object t) {
  return Text(t.toString(), softWrap: false, overflow: TextOverflow.ellipsis);
}

String empty(Object t) => "";

class ListChooser<T extends Object> extends ValueNotifier<T>
    implements ShortcutMapper {
  final List<T> possible;
  final Icon Function(T)? makeIcon;
  final Widget Function(T) makeButton;
  final String Function(T) tooltip;
  final String message;
  final Key? key;

  ListChooser(
    this.possible, {
    this.key,
    T? initial,
    this.makeButton = toText,
    this.tooltip = empty,
    this.makeIcon,
    this.message = "",
  }) : super(initial ?? possible[0]);

  void _toggle(MenuController controller) {
    if (controller.isOpen) {
      controller.close();
    } else {
      controller.open();
    }
  }

  MenuItemButton makeChild(T item) {
    MenuSerializableShortcut? shortcut = (item is HasShortcut)
        ? item.shortcut
        : null;
    return MenuItemButton(
      key: ValueKey("$T-Chooser-$item"),
      shortcut: shortcut,
      onPressed: () {
        value = item;
      },
      child: makeIcon == null ? makeButton(item) : makeIcon!.call(item),
    );
  }

  List<MenuItemButton> buildChildren() {
    return possible.map((v) => makeChild(v)).toList();
  }

  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      key: key ?? ValueKey("$T-Chooser"),
      valueListenable: this,
      builder: (BuildContext context, T v1, Widget? child) {
        return MenuAnchor(
          builder:
              (BuildContext context, MenuController controller, Widget? child) {
                return makeIcon == null
                    ? Tooltip(
                        message: message,
                        waitDuration: const Duration(seconds: 3),
                        child: TextButton(
                          onPressed: () => _toggle(controller),
                          child: makeButton(value),
                        ),
                      )
                    : IconButton(
                        tooltip: message,
                        onPressed: () => _toggle(controller),
                        icon: makeIcon!.call(value),
                      );
              },
          menuChildren: buildChildren(),
        );
      },
    );
  }

  @override
  void register(
    Map<Type, Action<Intent>> actionMap,
    Map<ShortcutActivator, Intent> shortcutMap,
  ) {
    for (T item in possible) {
      if (item is HasShortcut) {
        HasShortcut item2 = item as HasShortcut;
        if (item2.shortcut == null) continue;
        MenuSerializableShortcut shortcut = item2.shortcut!;
        actionMap[_ChoiceIntent<T>] = _ChoiceAction<T>();
        shortcutMap[shortcut] = _ChoiceIntent(this, item);
      }
    }
  }

  void setValue(Intent intent) {
    _ChoiceIntent x = intent as _ChoiceIntent;
    x.menu.value = x.item;
  }
}

class RadioItem<T extends Object> extends MyMenuItem {
  final T item;
  final ValueNotifier<T> group;

  RadioItem(
    super.name,
    this.item,
    this.group, {
    super.callback,
    super.tip = "",
    super.isEnabledCallback,
  });

  @override
  Widget makeMenuButtonNoTip(BuildContext context) {
    MenuSerializableShortcut? sk = shortcut;
    if (item is HasShortcut) {
      HasShortcut item2 = item as HasShortcut;
      sk = item2.shortcut;
    }
    return RadioMenuButton<T>(
      value: item,
      shortcut: sk,
      groupValue: group.value,
      onChanged: (T? v) {
        Scaffold.maybeOf(context)?.closeDrawer();
        group.value = v!;
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 135),
        child: Text(
          name,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class RadioChooser<T extends Object> extends ListChooser<T> {
  RadioChooser(
    super.possible, {
    super.initial,
    super.makeButton = toText,
    super.tooltip = empty,
    super.makeIcon,
    super.message = "",
  });

  List<RadioItem<T>> makeItems() {
    return possible
        .map(
          (item) => RadioItem(item.toString(), item, this, tip: tooltip(item)),
        )
        .toList();
  }
}

void errorCallback() {
  Log.menus.log("RED: wrong callback.");
}

class ChoiceItem extends MyMenuItem {
  ChoiceItem(
    super.name, {
    super.callback = errorCallback,
    super.key,
    super.tip = "",
    super.isEnabledCallback,
  });
}

class _ChoiceIntent<T extends Object> extends Intent {
  final ListChooser<T> menu;
  final T item;
  const _ChoiceIntent(this.menu, this.item);
}

class RangeChooser extends ListChooser<int> {
  RangeChooser(
    int length, {
    super.key,
    super.initial = 0,
    super.makeButton = toText,
    super.tooltip = empty,
    super.makeIcon,
    super.message = "",
  }) : super([for (int i = 0; i < length; i++) i]);
}
