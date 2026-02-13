import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/utils/resources/supabase.dart';
import '../../data/models/handbook_chapter.dart';

@RoutePage()
class HandbookListPage extends StatefulWidget {
  const HandbookListPage({super.key});

  @override
  State<HandbookListPage> createState() => _HandbookListPageState();
}

class _HandbookListPageState extends State<HandbookListPage> {
  List<HandbookChapter> _chapters = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await supabase
          .from('handbook')
          .select('id, title, content')
          .order('display_order', ascending: true);
      if (mounted) {
        setState(() {
          _chapters = (response as List)
              .map((e) => HandbookChapter.fromMap(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _openDetail(HandbookChapter chapter) {
    context.router.push(
      HandbookDetailRoute(title: chapter.title, content: chapter.content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('驾照官方手册 (精简版)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          '加载失败',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loadChapters,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                )
              : _chapters.isEmpty
                  ? Center(
                      child: Text(
                        '暂无内容',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = _chapters[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(chapter.title),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openDetail(chapter),
                        );
                      },
                    ),
    );
  }
}
