import 'package:flutter/material.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// What the demo shows before the model is ready: the download, the
/// load, or what went wrong with a way to try again.
class ModelStatus extends StatelessWidget {
  const new({
    required this.progress,
    required this.error,
    required this.onRetry,
    super.key,
  });

  /// The download so far, if one is running.
  final ModelDownloadProgress? progress;

  /// Why the model could not be loaded, if it could not.
  final Object? error;

  /// Starts again after an error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    final (text, fraction) = switch (progress) {
      _ when failure != null => ('Could not get the model: $failure', null),
      ModelDownloadProgress(checking: true) => (
        'Checking the download...',
        null,
      ),
      ModelDownloadProgress(:final fraction) => (
        'Downloading Qwen2.5 1.5B Instruct, about 1.1 GB, once: '
            '${(fraction * 100).floor()}%',
        fraction,
      ),
      null => ('Loading the model...', null),
    };
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (failure == null) LinearProgressIndicator(value: fraction),
          if (failure != null)
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
