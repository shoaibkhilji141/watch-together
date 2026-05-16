import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Stream<List<ChatMessage>>> _messageStreams = {};
  final Set<String> _cleanupStartedForRoom = {};

  static const int defaultMessageLimit = 100;
  static const Duration messageRetention = Duration(days: 30);

  CollectionReference<Map<String, dynamic>> _messagesRef(String roomId) =>
      _firestore.collection('rooms').doc(roomId).collection('messages');

  /// One shared stream per room — avoids re-subscribing on widget rebuilds.
  Stream<List<ChatMessage>> watchMessages(
    String roomId, {
    int limit = defaultMessageLimit,
  }) {
    final cacheKey = '$roomId:$limit';
    return _messageStreams.putIfAbsent(cacheKey, () {
      return _messagesRef(roomId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(ChatMessage.fromFirestore)
                .toList(),
          );
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _messagesRef(roomId).add({
      'senderId': user.uid,
      'senderName': user.displayName ?? user.email ?? 'Guest',
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes messages older than [messageRetention]. Runs once per room session.
  Future<void> purgeOldMessagesIfNeeded(String roomId) async {
    if (_cleanupStartedForRoom.contains(roomId)) return;
    _cleanupStartedForRoom.add(roomId);

    try {
      final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(messageRetention),
      );

      while (true) {
        final snapshot = await _messagesRef(roomId)
            .where('timestamp', isLessThan: cutoff)
            .limit(200)
            .get();

        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (snapshot.docs.length < 200) break;
      }
    } catch (_) {
      // Cleanup is best-effort; chat must keep working if rules block deletes.
    }
  }

  void disposeRoom(String roomId) {
    _cleanupStartedForRoom.remove(roomId);
    _messageStreams.removeWhere((key, _) => key.startsWith('$roomId:'));
  }
}
