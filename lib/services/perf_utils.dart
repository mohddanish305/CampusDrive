import 'package:flutter/material.dart';

class PerfUtils {
  /// Wraps a widget with a [RepaintBoundary].
  ///
  /// Use this for widgets that repaint frequently but don't change their layout,
  /// or for static subtrees that don't need to repaint when their parent repaints.
  ///
  /// Example:
  /// ```dart
  /// PerfUtils.wrapWithRepaintBoundary(
  ///   child: MyComplexWidget(),
  /// )
  /// ```
  static Widget wrapWithRepaintBoundary({required Widget child}) {
    return RepaintBoundary(child: child);
  }

  /// Precaches a list of image assets.
  ///
  /// Call this in `didChangeDependencies` or `main` to ensure images are loaded
  /// before they are displayed, preventing jank.
  static Future<void> precacheImages(
    BuildContext context,
    List<String> assetPaths,
  ) async {
    for (final path in assetPaths) {
      await precacheImage(AssetImage(path), context);
    }
  }
}
