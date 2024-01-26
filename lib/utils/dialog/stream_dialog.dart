import 'dart:async';
import 'package:flutter/material.dart';

enum StreamDialogState {
  loginSSOSuccess,
  backupSuccess,
  recoveringSuccess,
}

class StreamDialogBuilder extends StatefulWidget {
  final Future Function() future;
  final Function(StreamDialogState) listen;

  const StreamDialogBuilder({
    super.key,
    required this.future,
    required this.listen,
  });

  @override
  State<StreamDialogBuilder> createState() => _StreamDialogBuilderState();
}

class _StreamDialogBuilderState extends State<StreamDialogBuilder>
    with TickerProviderStateMixin {
  final StreamController<StreamDialogState> streamController =
      StreamController<StreamDialogState>.broadcast();

  late AnimationController loginSSOProgressController;
  late AnimationController backupProgressController;
  late AnimationController recoveringProgressController;

  static const String loginSSOProgress = 'loginSSOProgress';
  static const String backupProgress = 'backupProgress';
  static const String recoveringProgress = 'recoveringProgress';

  bool _isCompletedFunc = false;

  @override
  void initState() {
    _initial();
    streamController.stream.listen((event) {
      widget.listen(event);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _startLoginSSOProgress();
      await widget.future().then((value) {
        _isCompletedFunc = true;
      });
    });

    super.initState();
  }

  void _initial() {
    loginSSOProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    backupProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    recoveringProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  void _startLoginSSOProgress() {
    loginSSOProgressController.addListener(() {
      setState(() {});
      if (loginSSOProgressController.isCompleted) {
        streamController.add(StreamDialogState.loginSSOSuccess);
        _startBackupProgress();
      }
    });
    loginSSOProgressController.forward(from: 0);
  }

  void _startBackupProgress() {
    backupProgressController.addListener(() {
      setState(() {});
      if (backupProgressController.isCompleted) {
        streamController.add(StreamDialogState.backupSuccess);
        _startRecoveringProgress();
      }
    });
    backupProgressController.forward(from: 0);
  }

  void _startRecoveringProgress() {
    recoveringProgressController.addListener(() {
      setState(() {});
      if (_isCompletedFunc) {
        streamController.add(StreamDialogState.recoveringSuccess);
        recoveringProgressController.stop();
        Navigator.of(context).pop();
      }
    });

    recoveringProgressController.repeat();
  }

  @override
  void dispose() {
    loginSSOProgressController.dispose();
    backupProgressController.dispose();
    recoveringProgressController.dispose();
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Setting up your Twake',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Setting up requires extra time so, please, be patient.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: loginSSOProgressController.value,
              semanticsLabel: loginSSOProgress,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: backupProgressController.value,
              semanticsLabel: backupProgress,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: recoveringProgressController.value,
              semanticsLabel: recoveringProgress,
            ),
          ],
        ),
      ),
    );
  }
}
