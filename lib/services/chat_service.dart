class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

class ChatService {
  const ChatService();

  // Placeholder API surface for future Firebase integration.
  Stream<List<ChatMessage>> subscribeToRoomMessages(String roomId) {
    throw UnimplementedError('Connect to your backend here.');
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    throw UnimplementedError('Send message via your backend here.');
  }
}

