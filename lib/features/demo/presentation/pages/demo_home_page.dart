import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

import '../../../../features/supabase_quiz/presentation/pages/quiz_wrapper_page.dart';
import '../../../../core/utils/constants/colors.dart';

@RoutePage()
class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SupaQuiz 演示模式'),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary.withOpacity(0.8),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                '演示模式',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '因无法连接 Supabase，登录功能不可用。\n请点击下方按钮使用 Supabase 测验。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QuizWrapperPage(),
                  ),
                ),
                icon: const Icon(Icons.quiz),
                label: const Text('Supabase 测验'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
