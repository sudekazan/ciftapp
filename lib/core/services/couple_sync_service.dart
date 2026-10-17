import 'dart:async';
import '../models/chat_message.dart';
import '../models/plan_item.dart';

abstract class ICoupleSyncService {
  Stream<List<ChatMessage>> messageStream(String coupleId);
  Future<void> sendMessage(String coupleId, ChatMessage message);
  Future<void> sendThinkingOfYouPulse(String coupleId, String senderName);
  Future<void> syncTask(String coupleId, TaskItem task);
  Future<void> syncDailyQuestionAnswer(String coupleId, String questionId, String answer, String userId);
}

/// Simulated real-time sync service for seamless preview and offline development
class MockCoupleSyncService implements ICoupleSyncService {
  final _messageStreamController = StreamController<List<ChatMessage>>.broadcast();

  @override
  Stream<List<ChatMessage>> messageStream(String coupleId) => _messageStreamController.stream;

  @override
  Future<void> sendMessage(String coupleId, ChatMessage message) async {
    // In production with Firebase: FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('messages').add(...)
  }

  @override
  Future<void> sendThinkingOfYouPulse(String coupleId, String senderName) async {
    // In production with Firebase: FirebaseFirestore.instance.collection('couples').doc(coupleId).update({'lastThinkingOfYou': FieldValue.serverTimestamp()})
  }

  @override
  Future<void> syncTask(String coupleId, TaskItem task) async {
    // In production with Firebase: sync tasks collection
  }

  @override
  Future<void> syncDailyQuestionAnswer(String coupleId, String questionId, String answer, String userId) async {
    // In production with Firebase: sync question answer
  }

  void dispose() {
    _messageStreamController.close();
  }
}
