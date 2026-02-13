import 'package:flutter/material.dart';

import '../../../../core/preferences/chinese_preference.dart';
import 'supabase_quiz_page.dart';

/// 包装 SupabaseQuizPage，通过 onBack 回调执行 Navigator.pop，
/// 避免在答题页内直接调用 Navigator.pop 与 AutoRoute 的断言冲突。
class QuizWrapperPage extends StatefulWidget {
  const QuizWrapperPage({super.key, this.categories});

  /// 分类列表，为空或 null 表示全真模拟考
  final List<String>? categories;

  @override
  State<QuizWrapperPage> createState() => _QuizWrapperPageState();
}

class _QuizWrapperPageState extends State<QuizWrapperPage> {
  bool _isTraditional = false;

  @override
  void initState() {
    super.initState();
    ChinesePreference.loadIsTraditional().then((v) {
      if (mounted) setState(() => _isTraditional = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SupabaseQuizPage(
      categories: widget.categories,
      onBack: () => Navigator.of(context).pop(),
      isTraditional: _isTraditional,
    );
  }
}
