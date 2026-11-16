import 'dart:async';
import 'package:flutter/material.dart';

import '../drive.dart';
import '../file_manager.dart';
import '../js_stub.dart' if (dart.library.html) '../js_interface.dart';
import '../l10n/l10n_extension.dart';
import '../settings.dart';
import 'app_widget.dart';

/// Wraps the application during initial file loading or splash display.
class SplashWidget extends StatefulWidget {
  final Settings settings;
  final FileManager fileManager;

  const SplashWidget(this.settings, this.fileManager, {super.key});

  @override
  State<SplashWidget> createState() => _SplashWidgetState();
}

class _SplashWidgetState extends State<SplashWidget> {
  late StreamSubscription _settingsListener;
  late StreamSubscription _fileListener;
  late StreamSubscription _driveListener;

  @override
  void initState() {
    super.initState();
    removeSplashFromWeb();

    _settingsListener = widget.settings.statusStream().listen((_) {
      if (mounted) setState(() {});
    });
    _fileListener = widget.fileManager.statusStream().listen((_) {
      if (mounted) setState(() {});
    });
    _driveListener = widget.fileManager.driveAccess.statusStream().listen((
      status,
    ) {
      if (mounted &&
          status == DriveAccessStatus.authorized &&
          widget.fileManager.current.holder is DriveHolder &&
          widget.fileManager.status == LoadingStatus.error) {
        widget.fileManager.reload();
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _settingsListener.cancel();
    _fileListener.cancel();
    _driveListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    removeSplashFromWeb();
    widget.fileManager.setContext('SplashWidget', context);

    if (widget.fileManager.status == LoadingStatus.loading ||
        widget.fileManager.current.scene == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16.0),
              Text(
                context.l10n.loadingFile(
                  widget.fileManager.current.holder.name,
                ),
                style: const TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.fileManager.status == LoadingStatus.error) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.errorLoadingFile)),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.0,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    context.l10n.failedToLoadFile(
                      widget.fileManager.current.holder.name,
                    ),
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    widget.fileManager.lastError?.toString() ??
                        widget.fileManager.exception?.toString() ??
                        'Unknown error loading file',
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => widget.fileManager.makeNew(),
                        child: Text(context.l10n.newDiagram),
                      ),
                      const SizedBox(width: 12.0),
                      ElevatedButton(
                        onPressed: () => widget.fileManager.reload(),
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppWidget(
      widget.fileManager.current.scene!,
      widget.settings,
      widget.fileManager,
    );
  }
}
