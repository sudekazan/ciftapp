import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  ChatProvider() {
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    final now = DateTime.now();

    _messages.addAll([
      ChatMessage(
        id: const Uuid().v4(),
        senderId: 'partner',
        senderName: 'Can',
        text: 'Günaydın sevgilim! Bugün Londra çok güneşli, aklımdasın ❤️',
        type: ChatMessageType.text,
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      ChatMessage(
        id: const Uuid().v4(),
        senderId: 'me',
        senderName: 'Sude',
        text: 'Günaydın aşkım! İstanbul da harika bugün. Kahvemi içerken seni düşündüm ☕️',
        type: ChatMessageType.text,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 45)),
      ),
      ChatMessage(
        id: const Uuid().v4(),
        senderId: 'partner',
        senderName: 'Can',
        text: 'Sana sesimi bırakıyorum, özledim sesini duymayı.',
        type: ChatMessageType.voice,
        voiceDurationSeconds: 14,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
      ),
      ChatMessage(
        id: const Uuid().v4(),
        senderId: 'partner',
        senderName: 'Can',
        text: 'Sana küçük bir sürprizim var! 🎁',
        type: ChatMessageType.surprise,
        scheduledUnlockDate: now.add(const Duration(hours: 5)),
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  void sendTextMessage({required String senderId, required String senderName, required String text}) {
    final msg = ChatMessage(
      id: const Uuid().v4(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      type: ChatMessageType.text,
      timestamp: DateTime.now(),
    );
    _messages.add(msg);
    notifyListeners();

    // Friendly auto-reply simulation for testing
    _simulatePartnerResponse(text);
  }

  void sendVoiceNote({required String senderId, required String senderName, int durationSeconds = 12}) {
    final msg = ChatMessage(
      id: const Uuid().v4(),
      senderId: senderId,
      senderName: senderName,
      text: 'Sesli Mesaj ($durationSeconds sn)',
      type: ChatMessageType.voice,
      voiceDurationSeconds: durationSeconds,
      timestamp: DateTime.now(),
    );
    _messages.add(msg);
    notifyListeners();
  }

  void sendSurpriseMessage({
    required String senderId,
    required String senderName,
    required String text,
    required DateTime scheduledDate,
  }) {
    final msg = ChatMessage(
      id: const Uuid().v4(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      type: ChatMessageType.surprise,
      scheduledUnlockDate: scheduledDate,
      timestamp: DateTime.now(),
      isSurpriseUnlocked: false,
    );
    _messages.add(msg);
    notifyListeners();
  }

  void unlockSurprise(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(isSurpriseUnlocked: true);
      notifyListeners();
    }
  }

  void sendThinkingOfYouMessage({required String senderId, required String senderName}) {
    final msg = ChatMessage(
      id: const Uuid().v4(),
      senderId: senderId,
      senderName: senderName,
      text: '❤️ Seni düşündüm!',
      type: ChatMessageType.thinkingOfYou,
      timestamp: DateTime.now(),
    );
    _messages.add(msg);
    notifyListeners();
  }

  void _simulatePartnerResponse(String incoming) {
    Timer(const Duration(milliseconds: 1500), () {
      final replies = [
        'Canım benim, ben de tam bunu düşünüyordum! 🥰',
        'Buluşmamıza çok az kaldı, sabırsızlanıyorum! ❤️',
        'Günün sorusunu yanıtladın mı? Ben yazdım bile! ✨',
        'Seni çok seviyorum, iyi ki varsın ❤️',
      ];
      final randomReply = (replies..shuffle()).first;

      _messages.add(ChatMessage(
        id: const Uuid().v4(),
        senderId: 'partner',
        senderName: 'Can',
        text: randomReply,
        type: ChatMessageType.text,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    });
  }
}
