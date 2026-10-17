enum ChatMessageType {
  text,
  photo,
  voice,
  surprise,
  thinkingOfYou,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final ChatMessageType type;
  final String? mediaUrl;
  final int? voiceDurationSeconds;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? scheduledUnlockDate;
  final bool isSurpriseUnlocked;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.type = ChatMessageType.text,
    this.mediaUrl,
    this.voiceDurationSeconds,
    required this.timestamp,
    this.isRead = true,
    this.scheduledUnlockDate,
    this.isSurpriseUnlocked = false,
  });

  bool get isLockedSurprise {
    if (type != ChatMessageType.surprise) return false;
    if (scheduledUnlockDate == null) return false;
    return DateTime.now().isBefore(scheduledUnlockDate!) && !isSurpriseUnlocked;
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    ChatMessageType? type,
    String? mediaUrl,
    int? voiceDurationSeconds,
    DateTime? timestamp,
    bool? isRead,
    DateTime? scheduledUnlockDate,
    bool? isSurpriseUnlocked,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      scheduledUnlockDate: scheduledUnlockDate ?? this.scheduledUnlockDate,
      isSurpriseUnlocked: isSurpriseUnlocked ?? this.isSurpriseUnlocked,
    );
  }
}
