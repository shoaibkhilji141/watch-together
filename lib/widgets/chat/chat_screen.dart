import 'package:flutter/material.dart';

import '../../services/chat_repository.dart';
import '../../utils/app_palette.dart';
import 'chat_messages.dart';
import 'message_input.dart';

/// Chat panel for a watch room. Only [ChatMessages] subscribes to Firestore.
class ChatScreen extends StatefulWidget {
  final String roomId;

  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ChatMessagesState> _messagesKey =
      GlobalKey<ChatMessagesState>();

  @override
  void dispose() {
    ChatRepository.instance.disposeRoom(widget.roomId);
    super.dispose();
  }

  Future<void> _handleSend(String text) async {
    await ChatRepository.instance.sendMessage(
      roomId: widget.roomId,
      text: text,
    );
    _messagesKey.currentState?.scrollToLatest();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return ColoredBox(
      color: p.bg,
      child: Column(
        children: [
          Expanded(
            child: ChatMessages(
              key: _messagesKey,
              roomId: widget.roomId,
            ),
          ),
          MessageInput(onSend: _handleSend),
        ],
      ),
    );
  }
}
