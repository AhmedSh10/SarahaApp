class Message {
  final String id;
  final String recipientId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.recipientId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      recipientId: json['recipient_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}