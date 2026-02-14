import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../core/user/user_manager.dart';
import '../../../../core/utils/resources/supabase.dart';
import '../../widgets/payment_dialog.dart';
import 'dart:async';

import '../../../../core/preferences/chinese_preference.dart';
import '../../../../core/preferences/mistakes_preference.dart';
import '../../../../core/preferences/streak_preference.dart';
import '../../../../core/services/user_mistakes_service.dart';
import '../../../../core/utils/chinese_converter.dart';
import '../../../../core/utils/constants/numbers.dart';
import '../../../../core/utils/constants/strings.dart' show kAppIconUrl;
import '../supabase_quiz/presentation/pages/simulation_exam_page.dart';
import '../supabase_quiz/presentation/pages/supabase_quiz_page.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showQuiz = false;
  int? _quizChapterId;
  String? _quizTitle;
  bool _isTraditional = false;
  bool _showMistakesQuiz = false;
  List<String> _mistakeIds = [];
  bool _mistakesLoading = false;
  int _mistakeCount = 0;
  bool _showSimulationExam = false;
  int _streakCount = 1;
  bool _isVip = false;

  String _t(String s) => convertChinese(s, _isTraditional);

  @override
  void initState() {
    super.initState();
    ChinesePreference.loadIsTraditional().then((v) {
      if (mounted) setState(() => _isTraditional = v);
    });
    _refreshMistakeCount();
    _initStreak();
    _checkVipStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingChapterAccess();
    });
  }

  /// 从 profiles 表获取当前用户的 VIP 状态
  /// 严格解析：仅当明确为 true 时才算 VIP，避免 "false"/null/异常值 被误判
  static bool _parseIsVip(dynamic raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true' || raw == '1';
    if (raw is int) return raw == 1;
    return false;
  }

  Future<void> _checkVipStatus() async {
    final isVip = await _fetchVipStatus();
    if (mounted) setState(() => _isVip = isVip);
  }

  Future<bool> _fetchVipStatus() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final res = await supabase
          .from('profiles')
          .select('is_vip')
          .eq('id', uid)
          .maybeSingle();
      return _parseIsVip(res?['is_vip']);
    } catch (_) {
      return false;
    }
  }

  Future<void> _initStreak() async {
    final count = await StreakPreference.checkAndUpdateStreak();
    if (mounted) setState(() => _streakCount = count);
  }

  void _refreshMistakeCount() {
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      UserMistakesService.getMistakeCount(uid).then((c) {
        if (mounted) setState(() => _mistakeCount = c);
      });
    } else {
      MistakesPreference.getMistakeCount().then((c) {
        if (mounted) setState(() => _mistakeCount = c);
      });
    }
  }

  void _onTraditionalChanged(bool v) {
    setState(() => _isTraditional = v);
    ChinesePreference.saveIsTraditional(v);
  }

  void _openQuizWithChapter(int chapterId, String title) {
    setState(() {
      _showQuiz = true;
      _showMistakesQuiz = false;
      _quizChapterId = chapterId;
      _quizTitle = title;
    });
  }

  void _closeQuiz() {
    setState(() {
      _showQuiz = false;
      _quizChapterId = null;
      _quizTitle = null;
    });
  }

  Future<void> _openMistakesBook() async {
    setState(() => _mistakesLoading = true);
    final uid = supabase.auth.currentUser?.id;
    final ids = uid != null
        ? await UserMistakesService.getMistakeIds(uid)
        : await MistakesPreference.loadMistakeIds();
    if (mounted) {
      setState(() {
        _mistakesLoading = false;
        _showMistakesQuiz = true;
        _showQuiz = false;
        _mistakeIds = ids;
      });
    }
  }

  void _closeMistakesQuiz() {
    setState(() {
      _showMistakesQuiz = false;
      _mistakeIds = [];
    });
    _refreshMistakeCount();
  }

  void _openSimulationExam() {
    setState(() {
      _showSimulationExam = true;
      _showQuiz = false;
      _showMistakesQuiz = false;
    });
  }

  void _closeSimulationExam() {
    setState(() => _showSimulationExam = false);
  }

  void _showPurchaseDialog(BuildContext context, {Map<String, dynamic>? pendingChapter}) {
    final isTraditional = _isTraditional;
    showDialog<void>(
      context: context,
      builder: (ctx) => PaymentDialog(
        isTraditional: isTraditional,
        onRedeemed: () async {
          await _checkVipStatus();
          if (context.mounted) Navigator.of(context).pop();
          // 交费验证成功后，立即更新 VIP 并开启对应章节
          if (pendingChapter != null && mounted) {
            final id = pendingChapter['id'] as int;
            final type = pendingChapter['type'] as String?;
            final title = _t(pendingChapter['title'] as String);
            if (type == 'simulation') {
              _openSimulationExam();
            } else if (type == 'hardest') {
              _openQuizWithChapter(id, title);
            } else {
              _openQuizWithChapter(id, title);
            }
          }
        },
      ),
    );
  }

  /// 登录回跳后检查待访问章节（从章节点击跳转登录时设置）
  Future<void> _checkPendingChapterAccess() async {
    final userManager = context.read<UserManager>();
    final pending = userManager.consumePendingChapter();
    if (pending == null || !mounted) return;
    final id = pending['id'] as int;
    final type = pending['type'] as String?;
    final title = _t(pending['title'] as String);
    final isVipNow = await _fetchVipStatus();
    if (!mounted) return;
    setState(() => _isVip = isVipNow);
    if (!isVipNow) {
      _showPurchaseDialog(context, pendingChapter: pending);
    } else {
      if (type == 'simulation') {
        _openSimulationExam();
      } else if (type == 'hardest') {
        _openQuizWithChapter(id, title);
      } else {
        _openQuizWithChapter(id, title);
      }
    }
  }

  Future<void> _onChapterTap(BuildContext context, Map<String, dynamic> chapter) async {
    final id = chapter['id'] as int;
    final type = chapter['type'] as String?;
    final title = _t(chapter['title'] as String);

    // 1-3 章：免费对所有客户开放，游客可直接进入
    if (id <= 3) {
      if (type == 'simulation') {
        _openSimulationExam();
        return;
      }
      if (type == 'hardest') {
        _openQuizWithChapter(id, title);
        return;
      }
      _openQuizWithChapter(id, title);
      return;
    }

    // 第四章及以后：新用户点击时 → 登录页 → 验证码通过 → 收费窗口 → 缴费验证 → 开放全部章节
    if (supabase.auth.currentUser == null) {
      context.read<UserManager>().setPendingChapter(chapter);
      if (!context.mounted) return;
      context.router.push(const AuthRoute());
      return;
    }

    final isVipNow = await _fetchVipStatus();
    if (!mounted) return;
    setState(() => _isVip = isVipNow);
    if (!isVipNow) {
      _showPurchaseDialog(context, pendingChapter: chapter);
      return;
    }

    if (type == 'simulation') {
      _openSimulationExam();
      return;
    }
    if (type == 'hardest') {
      _openQuizWithChapter(id, title);
      return;
    }
    _openQuizWithChapter(id, title);
  }

  /// 驾考章节配置（与 Supabase chapters 表对应，按 ID 排序）
  /// 免费内容：Chapter 1-3；VIP 内容：Chapter 4-11
  static final List<Map<String, dynamic>> _chapters = [
    {'id': 1, 'title': '交通标志与信号', 'titleEn': 'Signs', 'subtitle': '红绿灯、停车牌、路面标线', 'icon': Icons.traffic, 'color': Colors.blue, 'isNew': false, 'isFree': true},
    {'id': 2, 'title': '停车与车道', 'titleEn': 'Parking', 'subtitle': '路缘颜色、坡道停车、拼车道', 'icon': Icons.local_parking, 'color': Colors.orange, 'isNew': false, 'isFree': true},
    {'id': 3, 'title': '速度与限速', 'titleEn': 'Speed', 'subtitle': '高速、学区、盲区限速规则', 'icon': Icons.speed, 'color': Colors.indigo, 'isNew': false, 'isFree': true},
    {'id': 4, 'title': '优先权与让行', 'titleEn': 'Right of Way', 'subtitle': '十字路口、行人优先、紧急车辆', 'icon': Icons.directions_car, 'color': Colors.green, 'isNew': false, 'isFree': false},
    {'id': 5, 'title': '酒精与药物', 'titleEn': 'Alcohol', 'subtitle': 'BAC限制、酒驾惩罚、药物影响', 'icon': Icons.wine_bar, 'color': Colors.purple, 'isNew': false, 'isFree': false},
    {'id': 6, 'title': '防御性驾驶', 'titleEn': 'Defensive', 'subtitle': '跟车距离、盲点检查、扫描路况', 'icon': Icons.shield, 'color': Colors.teal, 'isNew': false, 'isFree': false},
    {'id': 7, 'title': '恶劣天气', 'titleEn': 'Weather', 'subtitle': '雨天打滑、雾天灯光、爆胎处理', 'icon': Icons.thunderstorm, 'color': Colors.blueGrey, 'isNew': false, 'isFree': false},
    {'id': 8, 'title': '罚款与扣分', 'titleEn': 'Fines', 'subtitle': '违规扣分、弃置动物罚款', 'icon': Icons.attach_money, 'color': Colors.brown, 'isNew': false, 'isFree': false},
    {'id': 9, 'title': '易错题集锦', 'titleEn': 'Hardest', 'subtitle': '精选高频易错陷阱题', 'type': 'hardest', 'icon': Icons.error_outline, 'color': Colors.redAccent, 'isNew': false, 'isFree': false},
    {'id': 10, 'title': '🔥 2026年新规专项', 'titleEn': 'Latest Regulations', 'subtitle': 'AB 645超速摄像头、Daylighting法案', 'icon': Icons.fiber_new, 'color': Colors.red, 'isNew': true, 'isFree': false, 'highlight2026': true},
    {'id': 11, 'title': '全真模拟考', 'titleEn': 'Marathon Mode', 'subtitle': '随机抽取 36 题，模拟真实考试', 'type': 'simulation', 'icon': Icons.assignment_turned_in, 'color': Colors.deepPurple, 'isNew': false, 'isFree': false},
  ];

  Widget _buildComparisonCard() {
    const amber = Color(0xFFD4A017);
    final items = [
      (_t('题目数量'), _t('其他旧题库 (300-500道)'), _t('ZyLand 912道 - 全加州最全')),
      (_t('新规覆盖'), _t('其他 停留在2024'), _t('ZyLand 2026独家新规专项')),
      (_t('真实程度'), _t('其他 逻辑陈旧'), _t('ZyLand 1:1复刻DMV出题比例')),
      (_t('易用程度'), _t('其他题库-英文或机翻中文'), _t('Zyland（中文简体/繁体）')),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: amber.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_t('对比优势、降维打击'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amber)),
              const SizedBox(height: 12),
              ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.$1, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: Text(e.$2, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Text('✅ ', style: TextStyle(fontSize: 12, color: amber)),
                              Expanded(child: Text(e.$3, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: amber))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVip = _isVip;

    if (_showSimulationExam) {
      return SimulationExamPage(
        onBack: _closeSimulationExam,
        isTraditional: _isTraditional,
      );
    }

    if (_showMistakesQuiz) {
      if (_mistakesLoading) {
        return Scaffold(
          appBar: AppBar(title: Text(_t('我的错题本'))),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (_mistakeIds.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _closeMistakesQuiz,
            ),
            title: Text(_t('我的错题本')),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    _t('太棒了！您暂时没有错题'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _closeMistakesQuiz,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(_t('返回')),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Column(
        children: [
          Material(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _closeMistakesQuiz,
                    tooltip: _t('返回'),
                  ),
                  Text(
                    _t('我的错题本'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: SupabaseQuizPage(
              mistakeIds: _mistakeIds,
              onBack: _closeMistakesQuiz,
              onMistakesEmpty: _closeMistakesQuiz,
              isTraditional: _isTraditional,
            ),
          ),
        ],
      );
    }

    if (_showQuiz) {
      return Column(
        children: [
          Material(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _t('简'),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isTraditional ? Colors.grey : colorScheme.primary,
                    ),
                  ),
                  Switch(
                    value: _isTraditional,
                    onChanged: _onTraditionalChanged,
                  ),
                  Text(
                    _t('繁'),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isTraditional ? colorScheme.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SupabaseQuizPage(
              chapterId: _quizChapterId,
              title: _quizTitle,
              chapterTitle: _quizTitle,
              onBack: _closeQuiz,
              isTraditional: _isTraditional,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await LogoutService.performLogout();
              // 不在此处 replaceAll，由 app_shell 监听 signOut 后统一跳转，确保 auth 状态已清除
            },
            icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.red),
            label: Text(_t('退出登录'), style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: _t('关于/介绍'),
            onPressed: () => context.router.push(const IntroRoute()),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('简'),
                  style: TextStyle(
                    fontSize: 14,
                    color: _isTraditional ? Colors.grey : colorScheme.primary,
                  ),
                ),
                Switch(
                  value: _isTraditional,
                  onChanged: _onTraditionalChanged,
                ),
                Text(
                  _t('繁'),
                  style: TextStyle(
                    fontSize: 14,
                    color: _isTraditional ? colorScheme.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _SocialProofMarquee(),
          Expanded(
            child: Stack(
              children: [
                SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kLargePadding,
                      vertical: kHugePadding,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: kDefaultPadding),
                        Text(
                          _t('加州 C 照通关神器'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 15,
                            ),
                            children: [
                              const TextSpan(text: '全加州'),
                              TextSpan(
                                text: '最全',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const TextSpan(text: '、'),
                              TextSpan(
                                text: '最真',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const TextSpan(text: '考题'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Image.asset(
                          kAppIconUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.directions_car,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: kDefaultPadding),
                        _buildComparisonCard(),
                        const SizedBox(height: kDefaultPadding),
                        _StreakCounter(streakCount: _streakCount),
                        const SizedBox(height: kHugePadding),
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _t('官方承诺：完成全部阶段，笔试不过者，全额退款！'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: kDefaultPadding),
                        _MistakesBookButton(
                          mistakeCount: _mistakeCount,
                          isLoading: _mistakesLoading,
                          isTraditional: _isTraditional,
                          onPressed: _openMistakesBook,
                        ),
                        const SizedBox(height: kDefaultPadding),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _chapters.length,
                          separatorBuilder: (_, __) => const SizedBox(height: kDefaultPadding),
                          itemBuilder: (context, index) {
                            final chapter = _chapters[index];
                            final isFree = chapter['isFree'] == true;
                            final isUnlocked = isFree || isVip;
                            return _ChapterListItem(
                              index: index + 1,
                              chapter: chapter,
                              isUnlocked: isUnlocked,
                              isVip: isVip,
                              mistakeCount: null,
                              mistakesLoading: false,
                              isTraditional: _isTraditional,
                              onTap: () {
                                if (isUnlocked) {
                                  _onChapterTap(context, chapter);
                                } else {
                                  _showPurchaseDialog(context);
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: kDefaultPadding),
                        _HandbookButton(
                    label: _t('📖 驾照官方手册 (精简版)'),
                    subtitle: _t('California DMV Handbook'),
                    onPressed: () => context.router.push(const HandbookListRoute()),
                  ),
                        const SizedBox(height: kHugePadding * 2),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + kSmallPadding,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '开发：Zyland Education',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 社交证明跑马灯
class _SocialProofMarquee extends StatefulWidget {
  const _SocialProofMarquee();

  static const List<String> _fakeNotifications = [
    '恭喜 626****82 刚刚通过了笔试！🎉',
    '用户 909****11 开通了 VIP 会员，解锁了易错题库。',
    '用户 310****55 在模拟考中拿了 100 分！💯',
    '新用户 626****99 刚刚加入了 ZyLand 驾考通。',
    '恭喜 415****33 连续打卡 7 天！',
    '用户 718****21 通过了全真模拟考。',
    '用户 213****67 今日完成 50 道练习题。',
    '新用户 510****44 开通了完整版题库。',
    '恭喜 323****88 易错题全部攻克！',
    '用户 818****12 连续 14 天坚持学习。',
    '恭喜 626****55 第一次模拟考就通过！',
    '用户 917****66 开通了 VIP，解锁全部章节。',
    '新用户 408****22 加入了 ZyLand 驾考通。',
    '用户 619****77 在交通标志章节拿了满分。',
    '恭喜 505****91 连续打卡 3 天！',
    '用户 712****34 刚刚完成了 2026 新法规专题。',
    '新用户 301****58 刚刚加入，开始备考。',
    '用户 818****99 今日错题本清空！',
    '恭喜 426****13 模拟考 36 题全对！',
    '用户 604****71 开通 VIP，开启刷题之旅。',
  ];

  @override
  State<_SocialProofMarquee> createState() => _SocialProofMarqueeState();
}

class _SocialProofMarqueeState extends State<_SocialProofMarquee> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _index = (_index + 1) % _SocialProofMarquee._fakeNotifications.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Row(
        children: [
          Icon(Icons.campaign, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _SocialProofMarquee._fakeNotifications[_index],
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 连续打卡计数
class _StreakCounter extends StatelessWidget {
  const _StreakCounter({required this.streakCount});

  final int streakCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kLargePadding, vertical: kDefaultPadding),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withOpacity(0.8),
        borderRadius: BorderRadius.circular(kSmallBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.red.shade400,
            size: 28,
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(
                color: Colors.black87,
                fontSize: 14,
              ),
              children: streakCount == 1
                  ? [
                      const TextSpan(text: '第 '),
                      const TextSpan(
                        text: '1',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const TextSpan(text: ' 天'),
                    ]
                  : [
                      const TextSpan(text: '已连续坚持 '),
                      TextSpan(
                        text: '$streakCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const TextSpan(text: ' 天'),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 我的错题本入口按钮
class _MistakesBookButton extends StatelessWidget {
  const _MistakesBookButton({
    required this.mistakeCount,
    required this.isLoading,
    required this.isTraditional,
    required this.onPressed,
  });

  final int mistakeCount;
  final bool isLoading;
  final bool isTraditional;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentColor = Color(0xFFD32F2F);
    const textColor = Colors.white;

    return Material(
      color: accentColor,
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      elevation: 4,
      shadowColor: accentColor.withOpacity(0.5),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: kLargePadding,
            vertical: kLargePadding * 1.5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultBorderRadius),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: textColor,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      convertChinese('我的错题本', isTraditional),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mistakeCount > 0
                          ? '${convertChinese('答对即可移出错题本', isTraditional)} ($mistakeCount)'
                          : convertChinese('暂无错题', isTraditional),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: textColor,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandbookButton extends StatelessWidget {
  const _HandbookButton({
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.secondaryContainer.withOpacity(0.6),
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: kLargePadding,
            vertical: kLargePadding * 1.5,
          ),
          child: Row(
            children: [
              Icon(
                Icons.menu_book,
                color: colorScheme.onSecondaryContainer,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 呼吸动画图标（用于第 10 章等高亮章节）
class _BreathingIcon extends StatefulWidget {
  const _BreathingIcon({required this.icon, required this.color, this.size = 28});

  final IconData icon;
  final Color color;
  final double size;

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        );
      },
    );
  }
}

/// 章节列表项：序号、图标、NEW 标签、锁定状态
/// 免费 1-3，VIP 4-11：非 VIP 显示灰锁，VIP 显示金冠
class _ChapterListItem extends StatelessWidget {
  const _ChapterListItem({
    required this.index,
    required this.chapter,
    required this.isUnlocked,
    required this.isVip,
    required this.isTraditional,
    required this.onTap,
    this.mistakeCount,
    this.mistakesLoading = false,
  });

  final int index;
  final Map<String, dynamic> chapter;
  final bool isUnlocked;
  final bool isVip;
  final bool isTraditional;
  final VoidCallback onTap;
  final int? mistakeCount;
  final bool mistakesLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final id = chapter['id'] as int;
    final title = chapter['title'] as String;
    final subtitle = chapter['subtitle'] as String;
    final displayTitle = (id == 9 && mistakeCount != null && mistakeCount! > 0)
        ? '$title ($mistakeCount)'
        : title;
    final icon = chapter['icon'] as IconData? ?? Icons.menu_book;
    final color = chapter['color'] as Color? ?? colorScheme.primary;
    final isNew = chapter['isNew'] == true;
    final highlight2026 = chapter['highlight2026'] == true;
    final isVipChapter = id >= 4;
    final isLocked = isVipChapter && !isVip;
    final baseColor = isUnlocked
        ? colorScheme.onSurface
        : colorScheme.onSurface.withOpacity(0.5);
    final bgColor = highlight2026
        ? Colors.red.withOpacity(0.08)
        : (isLocked
            ? colorScheme.surfaceContainerHighest.withOpacity(0.35)
            : (isUnlocked
                ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
                : colorScheme.surfaceContainerHighest.withOpacity(0.4)));

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: kLargePadding,
                vertical: kLargePadding * 1.5,
              ),
              child: Row(
                children: [
                  // 序号
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 章节图标（第 10 章使用呼吸动画）
                  highlight2026
                      ? _BreathingIcon(icon: icon, color: color, size: 28)
                      : Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!isUnlocked) ...[
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            convertChinese(displayTitle, isTraditional),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                            ),
                          ),
                        ),
                        if (id == 4)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              convertChinese('进阶必读 (Premium)', isTraditional),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else if (isNew && !highlight2026)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NEW',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      convertChinese(subtitle, isTraditional),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: baseColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (mistakesLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isUnlocked)
                isVipChapter && isVip
                    ? Icon(Icons.workspace_premium, color: Colors.amber.shade700, size: 24)
                    : Icon(Icons.arrow_forward_ios, size: 14, color: baseColor)
              else
                Icon(Icons.lock, color: colorScheme.onSurfaceVariant.withOpacity(0.8), size: 24),
            ],
          ),
        ),
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.lock,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            if (highlight2026)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '2026',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 可锁定章节按钮：第 0 章免费，其余需 VIP
class _LockableStageButton extends StatelessWidget {
  const _LockableStageButton({
    required this.chapterIndex,
    required this.isVip,
    required this.label,
    required this.subtitle,
    required this.isHighlight,
    required this.onPressed,
    required this.onLockedTap,
  });

  final int chapterIndex;
  final bool isVip;
  final String label;
  final String subtitle;
  final bool isHighlight;
  final VoidCallback onPressed;
  final void Function(BuildContext) onLockedTap;

  bool get _isLocked => chapterIndex > 0 && !isVip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseColor = _isLocked
        ? colorScheme.onSurface.withOpacity(0.5)
        : (isHighlight ? colorScheme.onPrimaryContainer : colorScheme.onSurface);
    final bgColor = _isLocked
        ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
        : (isHighlight
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withOpacity(0.6));

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      child: InkWell(
        onTap: _isLocked ? () => onLockedTap(context) : onPressed,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: kLargePadding,
            vertical: kLargePadding * 1.5,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isLocked) ...[
                          Icon(
                            Icons.lock,
                            size: 18,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: baseColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!_isLocked)
                Icon(Icons.chevron_right, color: baseColor)
              else
                Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockableMistakesButton extends StatelessWidget {
  const _LockableMistakesButton({
    required this.chapterIndex,
    required this.isVip,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.isLoading,
    required this.onPressed,
    required this.onLockedTap,
  });

  final int chapterIndex;
  final bool isVip;
  final String label;
  final String subtitle;
  final int count;
  final bool isLoading;
  final VoidCallback onPressed;
  final void Function(BuildContext) onLockedTap;

  bool get _isLocked => chapterIndex > 0 && !isVip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayLabel = count > 0 ? '$label ($count)' : label;

    return Material(
      color: _isLocked
          ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
          : colorScheme.tertiaryContainer.withOpacity(0.8),
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      child: InkWell(
        onTap: _isLocked
            ? () => onLockedTap(context)
            : (isLoading ? null : onPressed),
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: kLargePadding,
            vertical: kLargePadding * 1.5,
          ),
          child: Row(
            children: [
              Icon(
                Icons.menu_book,
                color: _isLocked
                    ? colorScheme.onSurface.withOpacity(0.5)
                    : colorScheme.onTertiaryContainer,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isLocked)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.lock,
                              size: 16,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            displayLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isLocked
                                  ? colorScheme.onSurface.withOpacity(0.6)
                                  : colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: (_isLocked
                                ? colorScheme.onSurface
                                : colorScheme.onTertiaryContainer)
                            .withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLocked)
                Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  size: 24,
                )
              else if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockableNewLawsButton extends StatelessWidget {
  const _LockableNewLawsButton({
    required this.chapterIndex,
    required this.isVip,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    required this.onLockedTap,
  });

  final int chapterIndex;
  final bool isVip;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final void Function(BuildContext) onLockedTap;

  bool get _isLocked => chapterIndex > 0 && !isVip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentColor = Color(0xFF9C27B0);

    return Material(
      color: _isLocked
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4)
          : accentColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      child: InkWell(
        onTap: _isLocked ? () => onLockedTap(context) : onPressed,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: kLargePadding,
            vertical: kLargePadding * 1.5,
          ),
          child: Row(
            children: [
              Icon(
                Icons.new_releases,
                color: _isLocked
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                    : accentColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (_isLocked)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.lock,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.8),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isLocked
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6)
                                  : accentColor,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: (_isLocked
                                ? Theme.of(context).colorScheme.onSurface
                                : accentColor)
                            .withOpacity(0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isLocked)
                Icon(
                  Icons.lock_outline,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

