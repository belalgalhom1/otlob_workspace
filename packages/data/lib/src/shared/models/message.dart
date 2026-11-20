enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  system,
  product,
}

class MessageReply {
  final String id;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final bool deleted;
  final String? senderName;
  final String? senderAvatar;
  final String? senderTitle;
  final String? senderTitleAr;

  const MessageReply({
    required this.id,
    required this.type,
    this.text,
    this.mediaUrl,
    this.deleted = false,
    this.senderName,
    this.senderAvatar,
    this.senderTitle,
    this.senderTitleAr,
  });

  static MessageType parseType(String? typeStr) {
    switch (typeStr?.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'AUDIO':
        return MessageType.audio;
      case 'VIDEO':
        return MessageType.video;
      case 'FILE':
        return MessageType.file;
      case 'LOCATION':
        return MessageType.location;
      case 'SYSTEM':
        return MessageType.system;
      case 'PRODUCT':
        return MessageType.product;
      default:
        return MessageType.text;
    }
  }

  factory MessageReply.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return MessageReply(
      id: json['id']?.toString() ?? '',
      type: parseType(json['type']?.toString()),
      text: json['text']?.toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      deleted: json['deleted'] == true,
      senderName: sender?['name']?.toString() ?? json['senderName']?.toString(),
      senderAvatar: sender?['avatar']?.toString() ?? json['senderAvatar']?.toString(),
      senderTitle: sender?['title']?.toString() ?? json['senderTitle']?.toString(),
      senderTitleAr: sender?['titleAr']?.toString() ?? json['senderTitleAr']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name.toUpperCase(),
      'text': text,
      'mediaUrl': mediaUrl,
      'deleted': deleted,
      'sender': {
        'name': senderName,
        'avatar': senderAvatar,
        'title': senderTitle,
        'titleAr': senderTitleAr,
      },
    };
  }
}

class Message {
  final String id;
  final String content;
  final MessageType type;
  final bool isMe;
  final DateTime timestamp;
  final String senderName;
  final String? senderRole;
  final String? senderTitle;
  final String? senderTitleAr;
  final String? senderAvatar;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final String? replyToId;
  final MessageReply? replyTo;
  final double? uploadProgress;
  final String? localFilePath;
  final bool isUploadFailed;

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    required this.timestamp,
    required this.senderName,
    this.senderRole,
    this.senderTitle,
    this.senderTitleAr,
    this.senderAvatar,
    this.mediaUrl,
    this.metadata,
    this.isRead = false,
    this.replyToId,
    this.replyTo,
    this.uploadProgress,
    this.localFilePath,
    this.isUploadFailed = false,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    bool? isMe,
    DateTime? timestamp,
    String? senderName,
    String? senderRole,
    String? senderTitle,
    String? senderTitleAr,
    String? senderAvatar,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
    bool? isRead,
    String? replyToId,
    MessageReply? replyTo,
    double? uploadProgress,
    String? localFilePath,
    bool? isUploadFailed,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderTitle: senderTitle ?? this.senderTitle,
      senderTitleAr: senderTitleAr ?? this.senderTitleAr,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      localFilePath: localFilePath ?? this.localFilePath,
      isUploadFailed: isUploadFailed ?? this.isUploadFailed,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json, [String? currentUserId]) {
    final sender = json['sender'] ?? {};
    final senderRole = sender['role']?.toString();
    final senderId = sender['id']?.toString();

    // isMe can be determined by matching currentUserId with senderId
    final isMe = currentUserId != null && senderId == currentUserId;

    final type = MessageReply.parseType(json['type']?.toString());

    MessageReply? replyTo;
    if (json['replyTo'] != null && json['replyTo'] is Map) {
      replyTo = MessageReply.fromJson(Map<String, dynamic>.from(json['replyTo'] as Map));
    }
    final replyToId = json['replyToId']?.toString() ?? replyTo?.id;

    return Message(
      id: json['id']?.toString() ?? '',
      content: json['text']?.toString() ?? '',
      type: type,
      isMe: isMe,
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      senderName: sender['name']?.toString() ?? json['senderName']?.toString() ?? 'Unknown',
      senderRole: senderRole,
      senderTitle: sender['title']?.toString() ?? json['senderTitle']?.toString(),
      senderTitleAr: sender['titleAr']?.toString() ?? json['senderTitleAr']?.toString(),
      senderAvatar: sender['avatar']?.toString() ?? json['senderAvatar']?.toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['isRead'] == true,
      replyToId: replyToId,
      replyTo: replyTo,
    );
  }

  String? getLocalizedTitle({required bool isArabic}) {
    if (isArabic) {
      return (senderTitleAr != null && senderTitleAr!.trim().isNotEmpty)
          ? senderTitleAr!.trim()
          : (senderTitle != null && senderTitle!.trim().isNotEmpty ? senderTitle!.trim() : null);
    } else {
      return (senderTitle != null && senderTitle!.trim().isNotEmpty)
          ? senderTitle!.trim()
          : (senderTitleAr != null && senderTitleAr!.trim().isNotEmpty ? senderTitleAr!.trim() : null);
    }
  }
}
