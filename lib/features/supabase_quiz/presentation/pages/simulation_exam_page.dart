import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/preferences/mistakes_preference.dart';
import '../../../../core/widgets/question_cached_image.dart';
import '../../../../core/services/user_mistakes_service.dart';
import '../../../../core/utils/chinese_converter.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/resources/supabase.dart';
import '../../data/models/question_model.dart';

/// 全真模拟考页面 - 模拟加州 DMV 考试
class SimulationExamPage extends StatefulWidget {
  const SimulationExamPage({
    super.key,
    required this.onBack,
    this.isTraditional = false,
  });

  final VoidCallback onBack;
  final bool isTraditional;

  @override
  State<SimulationExamPage> createState() => _SimulationExamPageState();
}

class _SimulationExamPageState extends State<SimulationExamPage> {
  static const int _totalQuestions = 36;
  static const int _maxWrongAllowed = 6;
  static const int _examDurationMinutes = 20;

  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  int _wrongCount = 0;
  bool _loading = true;
  String? _error;
  bool _examFinished = false;
  bool? _passed;
  bool _answered = false;
  String? _selectedOption;

  Timer? _timer;
  int _remainingSeconds = _examDurationMinutes * 60;
  bool _timeUp = false;

  String _t(String s) => convertChinese(s, widget.isTraditional);

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds <= 0 || _examFinished) {
          _timer?.cancel();
          if (_remainingSeconds <= 0 && !_examFinished) {
            _timeUp = true;
            _finishExam();
          }
          return;
        }
        _remainingSeconds--;
      });
    });
  }

  void _finishExam() {
    setState(() {
      _examFinished = true;
      _passed = _wrongCount <= _maxWrongAllowed;
    });
    _timer?.cancel();
  }

  /// 智能组卷：4 个部分并行请求，加权算法
  /// Part A: 交通标志 6 题 | Part B: 核心驾驶 20 题 | Part C: 酒精药物 4 题 | Part D: 2026 新规 6 题
  Future<void> _loadQuestions() async {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _fetchPart(1, 6),
        _fetchPartIn([2, 3, 4, 5, 6, 7], 20),
        _fetchPart(8, 4),
        _fetchPart(10, 6),
      ]);

      final rawList = <Map<String, dynamic>>[];
      for (final part in results) {
        rawList.addAll(part);
      }

      if (rawList.length < _totalQuestions) {
        setState(() {
          _loading = false;
          _error = _t('题库题目不足，无法组成 $_totalQuestions 道模拟考题');
        });
        return;
      }

      rawList.shuffle();
      final questions = rawList
          .take(_totalQuestions)
          .map((e) => QuestionModel.fromMap(e))
          .toList();

      setState(() {
        _questions = questions;
        _loading = false;
        _currentIndex = 0;
        _wrongCount = 0;
        _examFinished = false;
        _passed = null;
        _remainingSeconds = _examDurationMinutes * 60;
        _timeUp = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _t('加载失败: $e');
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPart(int chapterId, int count) async {
    final response = await supabase
        .from('questions')
        .select()
        .eq('chapter_id', chapterId)
        .limit(200);
    final list = List<Map<String, dynamic>>.from(response);
    list.shuffle();
    return list.take(count).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPartIn(
    List<int> chapterIds,
    int count,
  ) async {
    final response = await supabase
        .from('questions')
        .select()
        .inFilter('chapter_id', chapterIds)
        .limit(300);
    final list = List<Map<String, dynamic>>.from(response);
    list.shuffle();
    return list.take(count).toList();
  }

  void _onSelectOption(String option) {
    if (_answered) return;

    final q = _questions[_currentIndex];
    final correct = q.isCorrect(option);

    setState(() {
      _answered = true;
      _selectedOption = option;
    });

    if (!correct) {
      MistakesPreference.addMistakeId(q.id);
      final uid = supabase.auth.currentUser?.id;
      if (uid != null) {
        UserMistakesService.addMistake(uid, q.id);
      }
      _showWrongAnswerDialog(q, option);
    } else {
      _advanceToNext();
    }
  }

  void _showWrongAnswerDialog(QuestionModel q, String selected) {
    final newWrongCount = _wrongCount + 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.red, size: 28),
            const SizedBox(width: 8),
            Text(_t('回答错误')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('正确答案是 ${q.correctOption}'),
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (q.explanation.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _t('解析'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t(q.explanation),
                  style: TextStyle(color: Colors.grey[800], height: 1.5),
                ),
              ],
              if (newWrongCount >= _maxWrongAllowed + 1) ...[
                const SizedBox(height: 16),
                Text(
                  _t('错题已达 7 道，考试未通过'),
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _advanceToNext(wrongIncrement: 1);
            },
            child: Text(_t('知道了')),
          ),
        ],
      ),
    );
  }

  void _advanceToNext({int wrongIncrement = 0}) {
    final newWrong = _wrongCount + wrongIncrement;

    if (newWrong >= _maxWrongAllowed + 1) {
      setState(() {
        _wrongCount = newWrong;
        _examFinished = true;
        _passed = false;
      });
      _timer?.cancel();
      return;
    }

    if (_currentIndex + 1 >= _questions.length) {
      setState(() {
        _wrongCount = newWrong;
        _examFinished = true;
        _passed = newWrong <= _maxWrongAllowed;
      });
      _timer?.cancel();
      return;
    }

    setState(() {
      _wrongCount = newWrong;
      _currentIndex++;
      _answered = false;
      _selectedOption = null;
    });
  }

  int get _correctCount => (_currentIndex + 1) - _wrongCount;

  Color _getOptionColor(String option) {
    if (!_answered) return Colors.grey[300]!;
    final q = _questions[_currentIndex];
    final isCorrect = q.correctOption == option;
    final isSelected = _selectedOption == option;
    if (isCorrect) return AppColors.green;
    if (isSelected && !isCorrect) return AppColors.red;
    return Colors.grey[300]!;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onBack,
          ),
          title: Text(_t('全真模拟考')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onBack,
          ),
          title: Text(_t('全真模拟考')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loadQuestions,
                  child: Text(_t('重试')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_examFinished) {
      return _buildResultPage();
    }

    return _buildQuestionPage();
  }

  Widget _buildResultPage() {
    final totalAnswered = _currentIndex + 1;
    final correctCount = _correctCount;
    final passed = _passed ?? false;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_t('模拟考结果')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_timeUp)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _t('时间到！'),
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            Icon(
              passed ? Icons.celebration : Icons.cancel,
              size: 80,
              color: passed ? AppColors.green : AppColors.red,
            ),
            const SizedBox(height: 24),
            Text(
              passed ? _t('PASS') : _t('FAIL'),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: passed ? AppColors.green : AppColors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t('得分: $correctCount / $totalAnswered'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!passed) ...[
              const SizedBox(height: 8),
              Text(
                _t('错题数: $_wrongCount (最多允许 $_maxWrongAllowed 题)'),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onBack,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: Text(_t('返回首页')),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loadQuestions,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_t('再考一次')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage() {
    final q = _questions[_currentIndex];
    final theme = Theme.of(context);
    final options = [
      ('A', _t(q.optionA)),
      ('B', _t(q.optionB)),
      ('C', _t(q.optionC)),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirm(),
        ),
        title: Text(_t('全真模拟考')),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _t('进度: ${_currentIndex + 1} / $_totalQuestions'),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  _t('剩余错误机会: ${_maxWrongAllowed - _wrongCount}'),
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    color: _remainingSeconds <= 60 ? AppColors.red : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if ((q.fullImageUrl ?? '').isNotEmpty)
                            _buildQuestionImage(q),
                          Text(
                            _t(q.question),
                            textAlign: TextAlign.start,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...options.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionButton(
                          option: e.$1,
                          text: e.$2,
                          color: _getOptionColor(e.$1),
                          onTap: () => _onSelectOption(e.$1),
                          disabled: _answered,
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionImage(QuestionModel q) {
    final url = q.fullImageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 200,
        child: Center(
          child: QuestionCachedImage(
            imageUrl: url,
            height: 200,
          ),
        ),
      ),
    );
  }

  void _showExitConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('确认退出？')),
        content: Text(_t('退出后本次模拟考进度将丢失，确定要退出吗？')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('继续考试')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onBack();
            },
            child: Text(_t('退出')),
          ),
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
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
