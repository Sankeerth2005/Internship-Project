class Conversation {
  final int id;
  final int? businessId;
  final String? businessName;
  final String? businessImage;
  final int? userId;
  final String? userName;
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    this.businessId,
    this.businessName,
    this.businessImage,
    this.userId,
    this.userName,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      businessId: json['businessId'],
      businessName: json['businessName'],
      businessImage: json['businessImage'],
      userId: json['userId'],
      userName: json['userName'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
    );
  }
}

class ChatMessage {
  final int id;
  final String senderRole;
  final String? text;
  final String? audioUrl;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderRole,
    this.text,
    this.audioUrl,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderRole: json['senderRole'],
      text: json['text'],
      audioUrl: json['audioUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
    );
  }
}
