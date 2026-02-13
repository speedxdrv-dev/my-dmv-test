/// 官方手册章节
class HandbookChapter {
  final String id;
  final String title;
  final String content;

  const HandbookChapter({
    required this.id,
    required this.title,
    required this.content,
  });

  factory HandbookChapter.fromMap(Map<String, dynamic> map) {
    return HandbookChapter(
      id: '${map['id'] ?? ''}',
      title: '${map['title'] ?? ''}',
      content: '${map['content'] ?? ''}',
    );
  }
}
