class NewsModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String authorId;
  final String authorName;
  final DateTime publishedAt;
  final int views;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.publishedAt,
    this.views = 0,
  });

  // Convert NewsModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'publishedAt': publishedAt.toIso8601String(),
      'views': views,
    };
  }

  // Create NewsModel from Firestore JSON
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Anonymous',
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : DateTime.now(),
      views: json['views'] ?? 0,
    );
  }

  // Copy with method for updates
  NewsModel copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? authorId,
    String? authorName,
    DateTime? publishedAt,
    int? views,
  }) {
    return NewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      publishedAt: publishedAt ?? this.publishedAt,
      views: views ?? this.views,
    );
  }
}
