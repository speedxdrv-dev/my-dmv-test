import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/user/user_manager.dart';
import '../core/utils/chinese_converter.dart';
import '../core/utils/constants/colors.dart';
import '../core/utils/extensions/snack_bar_extension.dart';
import '../core/utils/resources/supabase.dart';

/// 高端商业感付费弹窗
class PaymentDialog extends StatefulWidget {
  const PaymentDialog({
    super.key,
    required this.isTraditional,
    required this.onRedeemed,
  });

  final bool isTraditional;
  final Future<void> Function() onRedeemed;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _accountNameController = TextEditingController();
  bool _redeemLoading = false;
  bool _showPaymentArea = false;
  bool _isVip = false;
  bool _hasPendingRequest = false;
  bool _vipCheckLoading = true;
  bool _vipRequestLoading = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const String _zelleRecipient = 'ZyLand Education';
  static const String _zelleAccount = '840-668-0660';
  static const String _wechatId = 'zytop_2026';

  static const _brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A237E),
      Color(0xFF0D47A1),
      Color(0xFF0277BD),
    ],
  );

  static const _ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4A017),
      Color(0xFFF5C842),
    ],
  );

  String _t(String s) => convertChinese(s, widget.isTraditional);

  @override
  void initState() {
    super.initState();
    _checkVipStatus();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    _scaleController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  /// 检查 profiles.is_vip 与 vip_requests 的 pending 状态
  Future<void> _checkVipStatus() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _vipCheckLoading = false);
      return;
    }
    try {
      // profiles 主键为 id，vip_requests 关联列为 user_id
      final profileRes = await supabase
          .from('profiles')
          .select('is_vip')
          .eq('id', uid)
          .maybeSingle();
      final isVip = profileRes?['is_vip'] == true || profileRes?['is_vip'] == 'true';

      final pendingRes = await supabase
          .from('vip_requests')
          .select('id')
          .eq('user_id', uid)
          .eq('status', 'pending')
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isVip = isVip;
          _hasPendingRequest = pendingRes != null;
          _vipCheckLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _vipCheckLoading = false);
    }
  }

  Future<void> _submitVipRequest() async {
    final accountName = _accountNameController.text.trim();
    if (accountName.isEmpty) return;

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) {
        context.showSnackBar(
          message: _t('请先登录'),
          background: Colors.red,
          foreground: Colors.white,
        );
      }
      return;
    }

    setState(() => _vipRequestLoading = true);
    try {
      await supabase.from('vip_requests').insert({
        'user_id': uid,
        'account_name': accountName,
        'status': 'pending',
      });
      if (!mounted) return;
      setState(() => _vipRequestLoading = false);
      context.showSnackBar(
        message: _t('申请已提交，请等待管理员审核'),
        background: AppColors.green,
        foreground: Colors.white,
      );
      await _checkVipStatus();
    } catch (e) {
      if (mounted) {
        setState(() => _vipRequestLoading = false);
        context.showSnackBar(
          message: _t('提交失败，请重试'),
          background: Colors.red,
          foreground: Colors.white,
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      context.showSnackBar(
        message: _t('已复制: ') + label,
        background: AppColors.green,
        foreground: Colors.white,
      );
    }
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) return;

    setState(() => _redeemLoading = true);
    try {
      final res = await supabase.rpc('redeem_activation_code', params: {'p_code': code});
      final map = res as Map<String, dynamic>? ?? {};
      final ok = map['ok'] == true;
      final error = map['error'] as String?;

      if (!mounted) return;
      setState(() => _redeemLoading = false);

      if (ok) {
        final uid = supabase.auth.currentUser?.id;
        if (uid != null) {
          await context.read<UserManager>().loadVipStatus(uid);
        }
        context.showSnackBar(
          message: _t('恭喜！VIP 权限已永久激活'),
          background: AppColors.green,
          foreground: Colors.white,
          atTop: true,
        );
        await widget.onRedeemed();
      } else {
        context.showSnackBar(
          message: error ?? _t('兑换失败'),
          background: Colors.red,
          foreground: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _redeemLoading = false);
        context.showSnackBar(
          message: _t('兑换失败：') + (e.toString().split('\n').first),
          background: Colors.red,
          foreground: Colors.white,
        );
      }
    }
  }

  void _togglePaymentArea() {
    setState(() => _showPaymentArea = !_showPaymentArea);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        alignment: Alignment.center,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 顶部品牌渐变装饰区
                  Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: _brandGradient,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/logo.png',
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(
                          _t('ZyLand'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 主内容区
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 主标题
                        Text(
                          _t('加州 2026 驾考通 · 全库解锁'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // 文案
                        Text(
                          _t('🎉 恭喜完成前三章试炼！'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _t('剩余 500+ 真题、全真模拟考、错题集已为您准备就绪。'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _t('今日加入，享洛杉矶华人社群专属优惠价。'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // 卖点列表
                        _buildBenefitRow(_t('942道 2026 DMV 最新真题')),
                        const SizedBox(height: 10),
                        _buildBenefitRow(_t('1:1 复刻考场随机算法')),
                        const SizedBox(height: 10),
                        _buildBenefitRow(_t('永久有效，含后续所有规更新')),
                        const SizedBox(height: 10),
                        _buildBenefitRow(_t('专属错题集与考前冲刺模拟')),
                        const SizedBox(height: 20),
                        // 价格显示
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _t('限时特惠：'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '\$9.99',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                              Text(
                                _t(' (原价 \$19.99)'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 状态 A: VIP | 状态 B: 申请中 | 状态 C: 未购买
                        if (_vipCheckLoading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_isVip)
                          _buildStatusCard(
                            theme,
                            icon: Icons.check_circle,
                            text: _t('您已是 VIP 会员，享有全库题库权限'),
                            color: AppColors.green,
                          )
                        else if (_hasPendingRequest)
                          _buildStatusCard(
                            theme,
                            icon: Icons.hourglass_empty,
                            text: _t('申请审核中，请耐心等待管理员核对'),
                            color: Colors.orange.shade700,
                          )
                        else ...[
                          // 第一通道：立即开启通关之路
                          SizedBox(
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _ctaGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4A017).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _togglePaymentArea,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseAnimation,
                                          builder: (_, child) => Transform.scale(
                                            scale: _showPaymentArea ? 1.0 : _pulseAnimation.value,
                                            child: Icon(Icons.rocket_launch, color: Colors.white.withOpacity(0.95), size: 22),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _t('立即开启通关之路'),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 展开的支付区域（微信/ Zelle + 提交激活申请）
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: _buildPaymentArea(theme, colorScheme),
                            crossFadeState: _showPaymentArea
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 250),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // 视觉分割
                        Row(
                          children: [
                            Expanded(child: Divider(color: colorScheme.outlineVariant)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                _t('—— 已有激活码？直接兑换 ——'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: colorScheme.outlineVariant)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 第二通道：激活码兑换
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _codeController,
                                  focusNode: _codeFocusNode,
                                  maxLength: 8,
                                  style: theme.textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: _t('请输入 8 位激活码'),
                                    hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 4,
                                    ),
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              TextButton(
                                onPressed: _redeemLoading || _codeController.text.length != 8
                                    ? null
                                    : _redeemCode,
                                child: _redeemLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(_t('兑换')),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 底部小字
                        Text(
                          _t('一次付费，终身使用'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(_t('暂不解锁')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentArea(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t('转账请备注手机号，1分钟内极速开通'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 微信二维码
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _t('微信支付'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/wechat.qr.png',
                          fit: BoxFit.contain,
                          height: 140,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.qr_code_2,
                            size: 100,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t('扫码添加 $_wechatId'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => _copyToClipboard(_wechatId, _t('微信号')),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(_t('复制微信号'), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 140,
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
                const SizedBox(width: 16),
                // Zelle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Zelle 支付'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/zelle_qr.png',
                          fit: BoxFit.contain,
                          height: 100,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.account_balance_wallet,
                            size: 60,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t('收款人: $_zelleRecipient'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _t('账号: $_zelleAccount'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _copyToClipboard(_zelleAccount, _t('Zelle 账号')),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(_t('复制账号'), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 提交激活申请
            const SizedBox(height: 20),
            Divider(color: colorScheme.outlineVariant.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              _t('提交激活申请'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accountNameController,
              enabled: !_hasPendingRequest,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: _t('请输入您的 Zelle 姓名或转账备注，以便我们对账'),
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _hasPendingRequest || _vipRequestLoading ||
                        _accountNameController.text.trim().isEmpty
                    ? null
                    : _submitVipRequest,
                style: FilledButton.styleFrom(
                  backgroundColor: _hasPendingRequest
                      ? colorScheme.outlineVariant
                      : colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _vipRequestLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _hasPendingRequest ? _t('审核中') : _t('提交申请'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, {required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
