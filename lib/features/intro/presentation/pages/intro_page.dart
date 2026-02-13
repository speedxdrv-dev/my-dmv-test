import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/config/themes/app_theme.dart';
import '../../../../core/preferences/intro_preference.dart';
import '../../../../core/utils/resources/supabase.dart';
import '../../../../widgets/advantage_comparison_card.dart';

@RoutePage()
class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  void _onStart(BuildContext context) async {
    await IntroPreference.saveIntroSeen(true);
    if (!context.mounted) return;
    if (supabase.auth.currentUser != null) {
      appRouter.replaceAll([const HomeRoute(), const HomePageRoute()]);
    } else {
      appRouter.replaceAll([const HomeRoute(), const AuthRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF00296B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_car_filled,
                        size: 52,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '2026 加州驾照\n笔试通关神器',
                            textAlign: TextAlign.center,
                            style: notoSansTcWithFallback(
                              textStyle: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '一次考过，拒绝重来！',
                            textAlign: TextAlign.center,
                            style: notoSansTcWithFallback(
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '全加州最全，最真考题',
                            textAlign: TextAlign.center,
                            style: notoSansTcWithFallback(
                              textStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureItem(
                            icon: Icons.new_releases_rounded,
                            color: Colors.purple,
                            title: '2026 新规专区',
                            desc:
                                '独家收录 AB 413 停车法、测速监控等最新考点，拒绝因新题挂科。',
                          ),
                          _buildFeatureItem(
                            icon: Icons.timer_outlined,
                            color: Colors.orange,
                            title: '全真模拟考场',
                            desc:
                                '复刻真实考试逻辑：36 题、6 次容错、支持「跳过」战术。',
                          ),
                          _buildFeatureItem(
                            icon: Icons.menu_book_rounded,
                            color: Colors.blue,
                            title: '精编中文「红宝书」',
                            desc:
                                '告别晦涩难懂的官方 PDF。为您提炼 8 章核心干货，只讲必考点。',
                          ),
                          _buildFeatureItem(
                            icon: Icons.translate_rounded,
                            color: Colors.green,
                            title: '繁简自由切换',
                            desc: '一键切换简体/繁体中文，怎么舒服怎么看。',
                          ),
                          _buildFeatureItem(
                            icon: Icons.school_rounded,
                            color: Colors.teal,
                            title: '博士团队，倾情打造',
                            desc: 'Exan博士团队精心研发，专业靠谱的驾考辅导。',
                          ),
                          const SizedBox(height: 20),
                          const AdvantageComparisonCard(isTraditional: false),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () => _onStart(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00296B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
          child: Text(
            '开始我的通关之旅',
            style: notoSansTcWithFallback(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: notoSansTcWithFallback(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: notoSansTcWithFallback(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
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
