import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/config/themes/app_theme.dart';

@RoutePage()
class HandbookDetailPage extends StatelessWidget {
  const HandbookDetailPage({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.5) ??
        const TextStyle(fontSize: 16, height: 1.5);

    final styleSheet = MarkdownStyleSheet(
      h1: notoSansTcWithFallback(
        textStyle: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
      h2: notoSansTcWithFallback(
        textStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
      h3: notoSansTcWithFallback(
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
      h4: notoSansTcWithFallback(
        textStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
      ),
      p: notoSansTcWithFallback(textStyle: baseStyle),
      listBullet: notoSansTcWithFallback(textStyle: baseStyle),
      blockquote: notoSansTcWithFallback(
        textStyle: baseStyle.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: Markdown(
        data: content,
        styleSheet: styleSheet,
        padding: const EdgeInsets.all(20),
        selectable: true,
      ),
    );
  }
}
