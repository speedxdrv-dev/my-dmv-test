import 'package:pinyin/pinyin.dart';

/// 简繁中文转换工具
///
/// 若 [isTraditional] 为 true，将简体转为繁体；否则原样返回。
/// 使用 pinyin 包的 ChineseHelper（纯 Dart，支持 Web）。
String convertChinese(String? input, bool isTraditional) {
  if (input == null || input.isEmpty) return input ?? '';
  if (!isTraditional) return input;
  try {
    return ChineseHelper.convertToTraditionalChinese(input);
  } catch (_) {
    return input;
  }
}
