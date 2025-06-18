class UserProfile {
  final String id;
  final String userId;
  final String userType;
  final String name;
  final List<String> skills;
  final String? avatarUrl;
  final String? description;
  final bool notifyEnabled;

  UserProfile({
    required this.id,
    required this.userId,
    required this.userType,
    required this.name,
    required this.skills,
    this.avatarUrl,
    this.description,
    required this.notifyEnabled,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      userType: json['user_type'],
      name: json['name'],
      skills: List<String>.from(json['skills'] ?? []),
      avatarUrl: json['avatar_url'],
      description: json['description'],
      notifyEnabled: json['notify_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_type': userType,
      'name': name,
      'skills': skills,
      'avatar_url': avatarUrl,
      'description': description,
      'notify_enabled': notifyEnabled,
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? userType,
    String? name,
    List<String>? skills,
    String? avatarUrl,
    String? description,
    bool? notifyEnabled,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      skills: skills ?? this.skills,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      description: description ?? this.description,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
    );
  }
} 