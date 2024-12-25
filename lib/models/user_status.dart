class UserStatus {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;

  UserStatus({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      userId: json['user_id'],
      isOnline: json['is_online'],
      lastSeen: DateTime.parse(json['last_seen']),
    );
  }
}