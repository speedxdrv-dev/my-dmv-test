import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/config/supabase/supabase_config.dart';
import '../../../../core/widgets/custom_elevated_button.dart';

@RoutePage()
class SupabaseUnavailablePage extends StatelessWidget {
  const SupabaseUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                '无法连接 Supabase',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '网络无法访问 Supabase 服务（ERR_NAME_NOT_RESOLVED）。\n\n'
                '可能原因：\n'
                '• 网络限制（建议使用 VPN）\n'
                '• 原作者的 Supabase 项目已删除\n\n'
                '您可以使用演示模式，但测验功能需要连接 Supabase。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomElevatedButton(
                onPressed: () {
                  SupabaseConfig.isReachable = true;
                  appRouter.replaceAll([const HomeRoute(), const AuthRoute()]);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_queue),
                    SizedBox(width: 8),
                    Text('仍尝试连接 Supabase'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  appRouter.replaceAll([const HomeRoute(), const DemoHomeRoute()]);
                },
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: const Text('进入演示模式'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
