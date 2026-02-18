import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/extensions/snack_bar_extension.dart';
import '../core/user/user_manager.dart';

class ManualSmsVerificationWidget extends StatefulWidget {
  final VoidCallback onVerified;

  const ManualSmsVerificationWidget({
    super.key,
    required this.onVerified,
  });

  @override
  State<ManualSmsVerificationWidget> createState() =>
      _ManualSmsVerificationWidgetState();
}

// ... (imports)

class _ManualSmsVerificationWidgetState
    extends State<ManualSmsVerificationWidget> {
// ...
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isCodeSent = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  Future<void> _getVerificationCode() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''); // Ensure only digits
    if (phone.isEmpty || phone.length < 10) {
      if (mounted) {
        context.showSnackBar(message: '请输入有效的手机号', background: Colors.red);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call Supabase Edge Function to send code
      await Supabase.instance.client.functions.invoke(
        'manual-sms-verification',
        body: {'action': 'send', 'phone': phone},
      );

      if (mounted) {
        context.showSnackBar(message: '验证码请求已发送，请留意管理员短信', background: Colors.green);
        setState(() {
          _isCodeSent = true;
        });
        _startCountdown();
      }
    } on FunctionException catch (e) {
      if (mounted) {
        // Handle specific error messages from backend if needed
        context.showSnackBar(message: e.details?['message'] ?? '发送失败，请稍后重试', background: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(message: '发送失败: $e', background: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''); // Ensure only digits
    final code = _codeController.text.trim().replaceAll(RegExp(r'\D'), ''); // Ensure only digits

    if (code.length != 6) {
      if (mounted) {
        context.showSnackBar(message: '请输入6位验证码', background: Colors.red);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;

      // Call Supabase Edge Function to verify code
      final response = await Supabase.instance.client.functions.invoke(
        'manual-sms-verification',
        body: {
          'action': 'verify', 
          'phone': phone, 
          'code': code,
          'userId': userId, // 👈 告诉后端当前是谁在操作
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      
      if (data['valid'] == true) {
        if (mounted) {
          // If session data is returned, sign in the user
          if (data['session'] != null) {
            try {
              final session = Session.fromJson(data['session']);
              if (session != null) {
                await Supabase.instance.client.auth.recoverSession(session.accessToken);
                await Supabase.instance.client.auth.refreshSession();
              }
            } catch (e) {
              debugPrint('Auto-login failed: $e');
              if (mounted) context.showSnackBar(message: '自动登录失败: $e', background: Colors.red);
            }
          }
          
          // 3. 关键修复：强制刷新 VIP 状态到全局管理器
          if (mounted) {
             final uid = Supabase.instance.client.auth.currentUser?.id;
             if (uid != null) {
               await context.read<UserManager>().loadVipStatus(uid);
             } else {
               context.showSnackBar(message: '自动登录异常：未获取到用户ID', background: Colors.red);
             }
          }
          
          if (mounted) context.showSnackBar(message: '验证成功！', background: Colors.green);
          widget.onVerified();
        }
      } else {
        if (mounted) {
          context.showSnackBar(message: '验证码错误或已过期', background: Colors.red);
        }
      }
    } on FunctionException catch (e) {
      if (mounted) {
        context.showSnackBar(message: e.details?['message'] ?? '验证失败', background: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(message: '验证出错: $e', background: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          Text(
            '人工短信验证',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          // Phone Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    hintText: '接收验证码',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  enabled: !_isCodeSent, // Lock phone after sending
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: (_isLoading || _countdown > 0 || _isCodeSent)
                      ? null
                      : _getVerificationCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A017),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading && !_isCodeSent
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_countdown > 0 ? '${_countdown}s' : '获取验证码'),
                ),
              ),
            ],
          ),
          if (_isCodeSent) ...[
            const SizedBox(height: 16),
            // Code Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      hintText: '6位数字',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A017),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('验证并支付'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '注：验证码将由管理员人工发送，请耐心等待',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
