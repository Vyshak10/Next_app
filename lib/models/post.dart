class Post {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final List<String> tags;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.tags,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'image_urls': imageUrls,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_liked': isLiked,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? imageUrls,
    List<String>? tags,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
} 