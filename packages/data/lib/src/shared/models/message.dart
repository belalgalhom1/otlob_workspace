enum MessageType {
  text,
  image,
  video,
  audio,
  file,
}

class Message {
  final String id;
  final String content;
  final MessageType type;
  final bool isMe;
  final DateTime timestamp;
  final String senderName;
  final String? senderRole;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    required this.timestamp,
    required this.senderName,
    this.senderRole,
    this.mediaUrl,
    this.metadata,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    bool? isMe,
    DateTime? timestamp,
    String? senderName,
    String? senderRole,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json, [String? currentUserId]) {
    final sender = json['sender'] ?? {};
    final senderRole = sender['role']?.toString();
    final senderId = sender['id']?.toString();

    // isMe can be determined by matching currentUserId with senderId
    final isMe = currentUserId != null && senderId == currentUserId;

    MessageType type;
    final typeStr = json['type']?.toString().toUpperCase() ?? 'TEXT';
    switch (typeStr) {
      case 'IMAGE':
        type = MessageType.image;
        break;
      case 'AUDIO':
        type = MessageType.audio;
        break;
      case 'VIDEO':
        type = MessageType.video;
        break;
      case 'FILE':
        type = MessageType.file;
        break;
      default:
        type = MessageType.text;
    }

    return Message(
      id: json['id']?.toString() ?? '',
      content: json['text']?.toString() ?? '',
      type: type,
      isMe: isMe,
      timestamp: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      senderName: sender['name']?.toString() ?? 'Unknown',
      senderRole: senderRole,
      mediaUrl: json['mediaUrl']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
