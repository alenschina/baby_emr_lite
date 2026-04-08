import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 文案 SnackBar；行为与边距继承 [ThemeData.snackBarTheme]（见 `AppTheme.lightTheme`）。
void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      duration: AppTheme.snackBarDisplayDuration,
      content: Text(message),
    ),
  );
}
