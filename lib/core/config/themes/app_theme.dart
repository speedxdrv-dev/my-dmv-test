import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'light_color_scheme.dart';

/// 繁体中文字体回退：当 Noto Sans TC 未加载或缺字时使用系统字体
const List<String> _tcFontFallback = [
  'Microsoft JhengHei', // Windows 繁体
  'PingFang TC', // macOS 繁体
  'Noto Sans SC', // 若有安装则可用
  'sans-serif',
];

/// 为 TextStyle 添加繁体中文字体回退
TextStyle _withTcFallback(TextStyle style) =>
    style.copyWith(fontFamilyFallback: _tcFontFallback);

/// 带繁体中文字体回退的 Noto Sans TC 样式
TextStyle notoSansTcWithFallback({TextStyle? textStyle}) =>
    _withTcFallback(GoogleFonts.notoSansTc(textStyle: textStyle));

/// 为 TextTheme 中所有样式添加繁体中文字体回退
TextTheme _textThemeWithFallback(TextTheme theme) => TextTheme(
      displayLarge: _withTcFallback(theme.displayLarge!),
      displayMedium: _withTcFallback(theme.displayMedium!),
      displaySmall: _withTcFallback(theme.displaySmall!),
      headlineLarge: _withTcFallback(theme.headlineLarge!),
      headlineMedium: _withTcFallback(theme.headlineMedium!),
      headlineSmall: _withTcFallback(theme.headlineSmall!),
      titleLarge: _withTcFallback(theme.titleLarge!),
      titleMedium: _withTcFallback(theme.titleMedium!),
      titleSmall: _withTcFallback(theme.titleSmall!),
      bodyLarge: _withTcFallback(theme.bodyLarge!),
      bodyMedium: _withTcFallback(theme.bodyMedium!),
      bodySmall: _withTcFallback(theme.bodySmall!),
      labelLarge: _withTcFallback(theme.labelLarge!),
      labelMedium: _withTcFallback(theme.labelMedium!),
      labelSmall: _withTcFallback(theme.labelSmall!),
    );

abstract class AppTheme {
  /// 使用 Noto Sans TC 支持简体与繁体中文，避免繁体字显示为方框
  static final ThemeData lightTheme = ThemeData(
    fontFamily: GoogleFonts.notoSansTc().fontFamily,
    textTheme: _textThemeWithFallback(
      GoogleFonts.notoSansTcTextTheme(
        const TextTheme(
          titleLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    primaryTextTheme: _textThemeWithFallback(
      GoogleFonts.notoSansTcTextTheme(
        const TextTheme(
          titleLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    colorScheme: lightColorScheme,
  );

  // static ThemeData darkTheme = ThemeData(
  //   colorScheme: darkColorScheme,
  // );
}
