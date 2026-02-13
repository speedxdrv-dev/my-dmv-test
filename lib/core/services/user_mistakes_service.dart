import '../utils/resources/supabase.dart';

/// 个人错题本 - 与 Supabase user_mistakes 表交互
///
/// 表结构建议：
/// - user_id (uuid, FK to auth.users)
/// - question_id (uuid, FK to questions.id)
/// - 唯一约束: (user_id, question_id)
class UserMistakesService {
  UserMistakesService._();

  static const String _table = 'user_mistakes';

  /// 添加错题到 user_mistakes 表
  static Future<void> addMistake(String userId, String questionId) async {
    try {
      await supabase.from(_table).insert({
        'user_id': userId,
        'question_id': questionId,
      });
    } catch (_) {
      // 重复插入时忽略
    }
  }

  /// 从 user_mistakes 表移除错题
  static Future<void> removeMistake(String userId, String questionId) async {
    try {
      await supabase
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('question_id', questionId);
    } catch (_) {}
  }

  /// 获取用户所有错题 question_id 列表
  static Future<List<String>> getMistakeIds(String userId) async {
    try {
      final response = await supabase
          .from(_table)
          .select('question_id')
          .eq('user_id', userId);
      if (response.isEmpty) return [];
      final list = response;
      return list
          .map((e) => (e)['question_id']?.toString())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取用户错题数量
  static Future<int> getMistakeCount(String userId) async {
    final ids = await getMistakeIds(userId);
    return ids.length;
  }
}
