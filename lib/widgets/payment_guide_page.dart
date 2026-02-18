import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/chinese_converter.dart';
import '../core/utils/extensions/snack_bar_extension.dart';
import 'manual_sms_verification_widget.dart';

/// 支付引导页：简洁专业，Zelle / 微信支付
class PaymentGuidePage extends StatefulWidget {
  const PaymentGuidePage({
    super.key,
    required this.isTraditional,
    this.onPaidContact,
  });

  final bool isTraditional;
  final VoidCallback? onPaidContact;

  @override
  State<PaymentGuidePage> createState() => _PaymentGuidePageState();
}

class _PaymentGuidePageState extends State<PaymentGuidePage> {
  static const String _zelleAccount = '840-688-0660';
  static const String _wechatId = 'zytop_2026';
  static const String _wechatPayQr = 'assets/wechat.qr.png';

  bool _wechatExpanded = false;
  bool _isVerified = false;
  bool _showVerification = false;

  String _t(String s) => convertChinese(s, widget.isTraditional);

  Future<void> _copyZelleAccount() async {
    await Clipboard.setData(const ClipboardData(text: _zelleAccount));
    if (mounted) {
      context.showSnackBar(
        message: _t('账号已复制到剪贴板'),
        background: Colors.green.shade700,
        foreground: Colors.white,
      );
    }
  }

  void _showWechatQr() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('扫码添加客服')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wechat.qr.png',
              fit: BoxFit.contain,
              width: 220,
              height: 220,
              errorBuilder: (_, __, ___) => Container(
                width: 220,
                height: 220,
                color: Colors.grey.shade200,
                child: Icon(Icons.qr_code_2, size: 120, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t('微信号：$_wechatId'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('关闭')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '👑',
                  style: TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t('解锁 2026 加州驾考通全库'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_showVerification) ...[
                ManualSmsVerificationWidget(
                  onVerified: () {
                    if (mounted) {
                      setState(() => _isVerified = true);
                      Navigator.of(context).pop();
                      widget.onPaidContact?.call(); // 触发解锁回调
                    }
                  },
                ),
              ] else ...[
                _buildZelleModule(theme, colorScheme),
                const SizedBox(height: 20),
                _buildWechatModule(theme, colorScheme),
                const SizedBox(height: 32),
                _buildPrimaryButton(theme, colorScheme),
              ],
              const SizedBox(height: 12),
              _buildSecondaryButton(colorScheme),
              const SizedBox(height: 32),
              Text(
                _t('洛杉矶本地团队开发，2026 考题实时维护，不满意 24 小时内退款'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZelleModule(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/zelle_qr.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 40, color: Color(0xFF6D1ED4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t('Zelle 转账 (免手续费)'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _zelleAccount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _copyZelleAccount,
                icon: const Icon(Icons.copy, size: 18),
                label: Text(_t('复制')),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6D1ED4),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t('备注请填写您的登录手机号'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWechatModule(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _wechatExpanded = !_wechatExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Image.asset(
                  'assets/wechat.qr.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.chat_bubble, size: 40, color: Color(0xFF07C160)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _t('微信扫码 (自动换算汇率)'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  _wechatExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_wechatExpanded) ...[
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                _wechatPayQr,
                fit: BoxFit.contain,
                width: 200,
                height: 200,
                errorBuilder: (_, __, ___) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.qr_code_2, size: 100, color: Colors.grey.shade400),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: () {
          setState(() {
            _showVerification = true;
          });
        },
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD4A017),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _t('已支付，联系客服开启'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(ColorScheme colorScheme) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        _t('暂不开启'),
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
