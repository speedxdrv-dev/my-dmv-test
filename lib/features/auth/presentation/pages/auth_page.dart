import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/preferences/chinese_preference.dart';
import '../../../../core/utils/chinese_converter.dart';
import '../../../../core/utils/extensions/snack_bar_extension.dart';
import '../../../../core/utils/constants/numbers.dart';
import '../../../../core/utils/constants/strings.dart'
    show kAppIconUrl, kLoginBackgroundImage;
import '../../../../core/widgets/custom_elevated_button.dart';
import '../../../../core/widgets/text_field.dart';
import '../../data/repositories/authentication_repository.dart';

@RoutePage()
class AuthPage extends StatefulHookWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isTraditional = false;

  String _t(String s) => convertChinese(s, _isTraditional);

  @override
  void initState() {
    super.initState();
    ChinesePreference.loadIsTraditional().then((v) {
      if (mounted) setState(() => _isTraditional = v);
    });
  }

  void _onTraditionalChanged(bool v) {
    setState(() => _isTraditional = v);
    ChinesePreference.saveIsTraditional(v);
  }

  void _showWechatCodeDialog(BuildContext context) {
    final isTraditional = _isTraditional;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(convertChinese('添加客服获取验证码', isTraditional)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wechat.qr.png',
              fit: BoxFit.contain,
              width: 200,
              errorBuilder: (_, __, ___) => Icon(
                Icons.qr_code_2,
                size: 200,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              convertChinese(
                '扫码添加 ZyLand 客服，回复【验证码】免费获取',
                isTraditional,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(convertChinese('我已获取', isTraditional)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneController = useTextEditingController();
    final codeController = useTextEditingController();
    final isLoading = useState<bool>(false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.5),
              colorScheme.surface,
              colorScheme.secondaryContainer.withOpacity(0.3),
            ],
          ),
        ),
        child: Stack(
          children: [
            _LoginBackground(colorScheme: colorScheme),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            ),
            SafeArea(
              child: Form(
                key: _formKey,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: kMaxScreenWidth),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo + 标题
                          Image.asset(
                            'assets/logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              kAppIconUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.directions_car,
                                size: 120,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: kDefaultPadding),
                          Text(
                            _t('ZyLand 加州驾考通'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t('2026版'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t('博士团队，倾情打造'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: kHugePadding),

                          // 卡片式表单区域
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(kLargePadding * 1.5),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(kDefaultBorderRadius * 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SupaTextField(
                              label: _t('手机号 (Phone Number)'),
                              controller: phoneController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icon(Icons.phone, color: colorScheme.onSurfaceVariant),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              isEmptyError: _t('请输入手机号'),
                            ),
                            const SizedBox(height: kDefaultPadding),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SupaTextField(
                                    label: _t('验证码 (Verification Code)'),
                                    controller: codeController,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    isEmptyError: _t('请输入验证码'),
                                  ),
                                ),
                                const SizedBox(width: kDefaultPadding),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: TextButton(
                                    onPressed: () => _showWechatCodeDialog(context),
                                    child: Text(_t('获取验证码')),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: kHugePadding),
                            CustomElevatedButton(
                              onPressed: isLoading.value
                                  ? () {}
                                  : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      final phone = phoneController.text.trim();
                                      final inputCode = codeController.text;
                                      // 标准密码：手机号后4位 + "88"
                                      final last4 = phone.length >= 4
                                          ? phone.substring(phone.length - 4)
                                          : phone;
                                      final derivedPassword = '${last4}88';
                                      if (inputCode != derivedPassword) {
                                        if (mounted) {
                                          context.showSnackBar(
                                            message: _t(
                                              '验证码错误！请输入手机尾号+88，或联系客服。',
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      isLoading.value = true;
                                      try {
                                        final email = '$phone@zyland.app';
                                        await AuthenticationRepositoryImpl()
                                            .signInOrSignUp(
                                          email: email,
                                          password: derivedPassword,
                                          username: phone,
                                          context: context,
                                        );
                                        if (mounted) {
                                          Navigator.of(context).pop(true);
                                        }
                                      } finally {
                                        if (mounted) isLoading.value = false;
                                      }
                                    },
                              child: Center(
                                child: isLoading.value
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _t('登录 / 注册 (Login / Sign Up)'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: kHugePadding),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + kSmallPadding,
              left: 0,
            right: 0,
            child: Center(
              child: Text(
                _t('开发：Zyland Education'),
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
    );
  }
}

class _LoginBackground extends StatelessWidget {
  final ColorScheme colorScheme;

  const _LoginBackground({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            kLoginBackgroundImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

