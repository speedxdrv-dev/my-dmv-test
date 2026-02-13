import 'package:flutter/material.dart';

import '../core/utils/chinese_converter.dart';

/// 核心优势对比模块 - 独立文件确保 Web 生产构建中正确渲染
class AdvantageComparisonCard extends StatelessWidget {
  const AdvantageComparisonCard({
    super.key,
    required this.isTraditional,
  });

  final bool isTraditional;

  String _t(String s) => convertChinese(s, isTraditional);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const zylandAmber = Color(0xFFD4A017);

    final items = [
      (_t('题目数量'), _t('其他旧题库 (300-500道)'), _t('ZyLand 912道 - 全加州最全')),
      (_t('新规覆盖'), _t('其他 停留在2024'), _t('ZyLand 2026独家新规专项')),
      (_t('真实程度'), _t('其他 逻辑陈旧'), _t('ZyLand 1:1复刻DMV出题比例')),
      (_t('易用程度'), _t('其他题库-英文或机翻中文'), _t('Zyland（中文简体/繁体）')),
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color.lerp(
          colorScheme.surface,
          zylandAmber,
          0.08,
        ) ?? colorScheme.surface,
        border: Border.all(
          width: 1,
          color: Color.lerp(zylandAmber, colorScheme.surface, 0.7) ?? zylandAmber,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t('对比优势、降维打击'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4A017),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((e) => _buildRow(e.$1, e.$2, e.$3, zylandAmber)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String other, String zyland, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  other,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('✅ ', style: TextStyle(fontSize: 12, color: accent)),
                    Expanded(
                      child: Text(
                        zyland,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
