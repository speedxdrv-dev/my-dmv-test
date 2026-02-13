import '../../../../core/config/supabase/setup.dart';

/// Supabase questions 表的数据模型
///
/// 对应数据库列名：
/// - question_text: 题目文本
/// - option_a, option_b, option_c: 三个选项
/// - correct_answer: 正确答案 ('A'/'B'/'C' 或 1/2/3)
/// - explanation: 解析
/// - image_url: 图片 URL 或文件名
class QuestionModel {
  final String id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String correctOption; // 'A', 'B', 'C'
  final String explanation;
  final String? imageUrl;

  QuestionModel({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.correctOption,
    required this.explanation,
    this.imageUrl,
  });

  /// 获取完整图片 URL：若 imageUrl 为空返回 null；
  /// 若已包含 http 则原样返回；否则拼接到 Storage 基础 URL 后
  String? get fullImageUrl {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.toLowerCase().contains('http')) return url;
    return '$kSupabaseStorageBaseUrl$url';
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    // 对应数据库列名: question_text, option_a, option_b, option_c, correct_answer, explanation, image_url
    final q = map['question_text'] ?? map['question'] ?? '';
    final a = map['option_a'] ?? '';
    final b = map['option_b'] ?? '';
    final c = map['option_c'] ?? '';
    var correct = '${map['correct_answer'] ?? map['correct_option'] ?? 'A'}';
    final exp = map['explanation'] ?? '';

    // 统一为 A/B/C
    if (correct == '1' || correct == 'option_a') correct = 'A';
    if (correct == '2' || correct == 'option_b') correct = 'B';
    if (correct == '3' || correct == 'option_c') correct = 'C';

    final img = map['image_url'];
    final imageUrlStr = img == null ? null : (img is String ? img : '$img').trim();
    return QuestionModel(
      id: '${map['id'] ?? ''}',
      question: q is String ? q : '$q',
      optionA: a is String ? a : '$a',
      optionB: b is String ? b : '$b',
      optionC: c is String ? c : '$c',
      correctOption: correct.toUpperCase().substring(0, 1),
      explanation: exp is String ? exp : '$exp',
      imageUrl: imageUrlStr?.isEmpty == true ? null : imageUrlStr,
    );
  }

  bool isCorrect(String selected) => selected.toUpperCase() == correctOption;
}
