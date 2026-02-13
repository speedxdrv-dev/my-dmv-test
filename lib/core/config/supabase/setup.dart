import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// 当前连接的 Supabase 项目 URL（用于调试确认）
const String kSupabaseUrl = 'https://rjxjofocedvazhcmkrgj.supabase.co';

/// Storage 图片基础 URL，从 kSupabaseUrl 自动提取 Project ID
/// 格式: https://[ProjectID].supabase.co/storage/v1/object/public/quiz_images/
String get kSupabaseStorageBaseUrl {
  final projectRef = Uri.parse(kSupabaseUrl).host.split('.').first;
  return 'https://$projectRef.supabase.co/storage/v1/object/public/quiz_images/';
}

Future<void> setupSupabase() async {
  // Supabase Flutter 默认使用 SharedPreferences（移动端）或 localStorage（Web）持久化会话
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqeGpvZm9jZWR2YXpoY21rcmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1MTE5OTUsImV4cCI6MjA4NjA4Nzk5NX0.Fl5PXHKs-j5139cvpkSg0YstBGg_HlHsqZSa7FoybEA',
  );

  // 不再在启动时检测可达性，避免部署环境 404 阻塞应用
  // 各功能模块在使用时会自行处理网络异常
  SupabaseConfig.isReachable = true;
}