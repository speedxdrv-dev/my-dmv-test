import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/numbers.dart';

extension SnackBarExtension on BuildContext {
  void showSnackBar({
    required String message,
    Color? background,
    Color? foreground,
    bool atTop = false,
  }) {
    final margin = atTop
        ? EdgeInsets.only(
            bottom: MediaQuery.of(this).size.height - 100,
            left: 16,
            right: 16,
          )
        : null;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: foreground),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: background ?? AppColors.red,
        showCloseIcon: true,
        closeIconColor: foreground,
        margin: margin,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        ),
      ),
    );
  }
}
