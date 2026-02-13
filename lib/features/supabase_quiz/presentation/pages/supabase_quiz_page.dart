import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/themes/app_theme.dart';
import '../../../../core/preferences/mistakes_preference.dart';
import '../../../../core/widgets/question_cached_image.dart';
import '../../../../core/services/user_mistakes_service.dart';
import '../../../../core/utils/chinese_converter.dart';
import '../../../../core/utils/resources/supabase.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/numbers.dart';
import '../../data/models/question_model.dart';


@RoutePage()
class SupabaseQuizPage extends StatefulWidget {
  const SupabaseQuizPage({
    super.key,
    this.chapterId,
    this.categories,
    this.mistakeIds,
    this.title,
    this.chapterTitle,
    this.onBack,
    this.onMistakesEmpty,
    this.isTraditional = false,
  });

  /// 章节 ID：1-8, 10 标准章节；9 易错题(is_hard)；11 为全真模拟考(走 SimulationExamPage)
  final int? chapterId;

  /// 分类列表（兼容旧逻辑，优先级低于 chapterId）
  final List<String>? categories;

  /// 自定义页面标题，为空则默认显示「答题」
  final String? title;

  /// 章节标题，优先于 title 显示在 AppBar
  final String? chapterTitle;

  /// 错题本模式：题目 ID 列表，非空时仅从这些 ID 中抽题
  final List<String>? mistakeIds;

  /// 嵌入式使用时传入，点击返回时调用此回调而非 Navigator.pop
  final VoidCallback? onBack;

  /// 错题本模式下，当错题全部掌握（列表清空）时回调
  final VoidCallback? onMistakesEmpty;

  /// 是否使用繁体中文显示
  final bool isTraditional;

  bool get _isMistakesMode =>
      mistakeIds != null && mistakeIds!.isNotEmpty;

  @override
  State<SupabaseQuizPage> createState() => _SupabaseQuizPageState();
}

class _SupabaseQuizPageState extends State<SupabaseQuizPage> {
  QuestionModel? _question;
  String? _selectedOption;
  bool _answered = false;
  bool _loading = true;
  String? _error;

  /// 题目历史，用于上一题/下一题导航
  final List<QuestionModel> _questionHistory = [];
  int _currentQuestionIndex = -1;

  /// 错题本模式下剩余的错题 ID（答对后会移除）
  List<String> _remainingMistakeIds = [];

  /// 当前题目图片是否加载失败（失败则不显示图片区域）
  bool _currentQuestionImageFailed = false;

  String _convert(String? input) => convertChinese(input, widget.isTraditional);

  @override
  void initState() {
    super.initState();
    if (widget._isMistakesMode) {
      _remainingMistakeIds = List.from(widget.mistakeIds!);
    }
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _error = null;
      _question = null;
      _selectedOption = null;
      _answered = false;
      _currentQuestionImageFailed = false;
    });

    try {
      dynamic response;

      if (widget._isMistakesMode) {
        if (_remainingMistakeIds.isEmpty) {
          setState(() {
            _loading = false;
            _question = null;
            _error = _convert('恭喜！错题本已清空');
          });
          return;
        }
        response = await supabase
            .from('questions')
            .select()
            .inFilter('id', _remainingMistakeIds);
      } else {
        final chapterId = widget.chapterId;

        if (chapterId != null) {
          // 按 chapterId 查询
          if (chapterId == 9) {
            // 易错题模式：筛选 is_hard = TRUE
            response = await supabase
                .from('questions')
                .select()
                .eq('is_hard', true)
                .limit(1000)
                .order('id', ascending: true);
          } else if (chapterId >= 1 && (chapterId <= 8 || chapterId == 10)) {
            // 标准章节 (1-8, 10)：WHERE chapter_id = chapterId
            response = await supabase
                .from('questions')
                .select()
                .eq('chapter_id', chapterId)
                .limit(1000)
                .order('id', ascending: true);
          } else {
            response = await supabase.from('questions').select().limit(1000).order('id', ascending: true);
          }
        } else {
          // 兼容旧逻辑：categories
          final categories = widget.categories;
          final isFullMock = categories == null || categories.isEmpty;
          if (isFullMock) {
            response = await supabase
                .from('questions')
                .select()
                .limit(1000)
                .order('id', ascending: true);
          } else {
            response = await supabase
                .from('questions')
                .select()
                .inFilter('category', categories)
                .limit(1000)
                .order('id', ascending: true);
          }
        }
      }

      if (response.isEmpty) {
        setState(() {
          _loading = false;
          _error = widget._isMistakesMode
              ? '太棒了！您暂时没有错题'
              : widget.chapterId == 9
                  ? _convert('暂无易错题，请先完成其他章节')
                  : _convert('当前章节暂无题目');
        });
        return;
      }

      var list = response is List ? List<Map<String, dynamic>>.from(response) : [response as Map<String, dynamic>];
      if (list.isEmpty) {
        setState(() {
          _loading = false;
          _error = '题库为空';
        });
        return;
      }

      final randomIndex = DateTime.now().millisecondsSinceEpoch % list.length;
      final data = list[randomIndex];
      final newQuestion = QuestionModel.fromMap(data);

      setState(() {
        _question = newQuestion;
        _questionHistory.add(newQuestion);
        _currentQuestionIndex = _questionHistory.length - 1;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error =
            '加载失败: $e\n\n若题目已添加，请检查 questions 表的 RLS 策略是否允许读取。';
      });
    }
  }

  void _goToPrevious() {
    if (_currentQuestionIndex <= 0) return;
    setState(() {
      _currentQuestionIndex--;
      _question = _questionHistory[_currentQuestionIndex];
      _selectedOption = null;
      _answered = false;
      _currentQuestionImageFailed = false;
    });
  }

  void _goToNext() {
    if (_currentQuestionIndex < _questionHistory.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _question = _questionHistory[_currentQuestionIndex];
        _selectedOption = null;
        _answered = false;
        _currentQuestionImageFailed = false;
      });
    } else {
      _loadQuestion();
    }
  }

  void _onSelectOption(String option) {
    if (_answered) return;
    final correct = _question!.isCorrect(option);
    setState(() {
      _selectedOption = option;
      _answered = true;
    });

    if (!correct) {
      MistakesPreference.addMistakeId(_question!.id);
      final uid = supabase.auth.currentUser?.id;
      if (uid != null) {
        UserMistakesService.addMistake(uid, _question!.id);
      }
    } else if (widget._isMistakesMode) {
      _remainingMistakeIds.remove(_question!.id);
      MistakesPreference.removeMistakeId(_question!.id);
      final uid = supabase.auth.currentUser?.id;
      if (uid != null) {
        UserMistakesService.removeMistake(uid, _question!.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_convert('已掌握！移除出错题本')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Color _getOptionColor(String option) {
    if (!_answered) return Colors.grey[300]!;
    final isCorrect = _question!.correctOption == option;
    final isSelected = _selectedOption == option;
    if (isCorrect) return AppColors.green;
    if (isSelected && !isCorrect) return AppColors.red;
    return Colors.grey[300]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, size: 24, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              _convert(widget.chapterTitle ?? widget.title ?? '答题'),
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadQuestion,
            tooltip: _convert('下一题'),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + kSmallPadding,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _convert('开发：Zyland Education'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.onBack != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            // 延迟执行，避免在 pop 回调中直接调用 onBack（可能触发 Navigator.pop）
            // 导致与 Navigator 内部状态冲突引发 !popResult 断言
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onBack!();
            });
          }
        },
        child: scaffold,
      );
    }
    return scaffold;
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final isMistakesCleared = widget._isMistakesMode &&
          _error!.contains('清空');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMistakesCleared ? Icons.celebration : Icons.error_outline,
                size: 64,
                color: isMistakesCleared ? AppColors.green : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isMistakesCleared ? AppColors.green : Colors.grey[700],
                  fontWeight: isMistakesCleared ? FontWeight.bold : null,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isMistakesCleared
                    ? () => (widget.onBack ?? widget.onMistakesEmpty)?.call()
                    : _loadQuestion,
                icon: Icon(isMistakesCleared ? Icons.arrow_back : Icons.refresh),
                label: Text(_convert(isMistakesCleared ? '返回' : '重试')),
              ),
            ],
          ),
        ),
      );
    }

    if (_question == null) {
      return Center(child: Text(_convert('暂无题目')));
    }

    final q = _question!;
    final options = [
      ('A', _convert(q.optionA)),
      ('B', _convert(q.optionB)),
      ('C', _convert(q.optionC)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if ((q.fullImageUrl ?? '').isNotEmpty && !_currentQuestionImageFailed) ...[
                    SizedBox(
                      height: 165,
                      child: Center(
                        child: QuestionCachedImage(
                          imageUrl: q.fullImageUrl!,
                          height: 165,
                          onError: () {
                            if (mounted) {
                              setState(() => _currentQuestionImageFailed = true);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _convert(q.question),
                    textAlign: TextAlign.start,
                    style: notoSansTcWithFallback(
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionButton(
                  option: e.$1,
                  text: e.$2,
                  color: _getOptionColor(e.$1),
                  onTap: () => _onSelectOption(e.$1),
                  disabled: _answered,
                ),
              )),
          if (_answered) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.green.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          q.isCorrect(_selectedOption!)
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: q.isCorrect(_selectedOption!)
                              ? AppColors.green
                              : AppColors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _convert(q.isCorrect(_selectedOption!)
                                ? '回答正确！'
                                : '回答错误，正确答案是 ${q.correctOption}'),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: q.isCorrect(_selectedOption!)
                                  ? AppColors.green
                                  : AppColors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _convert('解析'),
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _convert(q.explanation),
                        textAlign: TextAlign.start,
                        style: notoSansTcWithFallback(
                          textStyle: TextStyle(
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentQuestionIndex > 0 ? _goToPrevious : null,
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: Text(_convert('上一题')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _goToNext,
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: Text(_convert('下一题')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.text,
    required this.color,
    required this.onTap,
    required this.disabled,
  });

  final String option;
  final String text;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    style: notoSansTcWithFallback(
                      textStyle: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
