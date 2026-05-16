import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../services/chat_repository.dart';
import '../../utils/app_palette.dart';
import 'message_bubble.dart';

class ChatMessages extends StatefulWidget {
  final String roomId;

  const ChatMessages({super.key, required this.roomId});

  @override
  State<ChatMessages> createState() => ChatMessagesState();
}

class ChatMessagesState extends State<ChatMessages> {
  final ScrollController scrollController = ScrollController();
  late final Stream<List<ChatMessage>> _messagesStream;

  int _lastMessageCount = 0;
  String? _lastTopMessageId;

  @override
  void initState() {
    super.initState();
    _messagesStream = ChatRepository.instance.watchMessages(widget.roomId);
    ChatRepository.instance.purgeOldMessagesIfNeeded(widget.roomId);
  }

  void scrollToLatest({bool animated = true}) {
    if (!scrollController.hasClients) return;
    final target = scrollController.position.minScrollExtent;
    if (animated) {
      scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      scrollController.jumpTo(target);
    }
  }

  bool _isNearLatest() {
    if (!scrollController.hasClients) return true;
    final distance = (scrollController.offset -
            scrollController.position.minScrollExtent)
        .abs();
    return distance < 72;
  }

  void _onMessagesUpdated(List<ChatMessage> messages) {
    if (messages.isEmpty) return;

    final newestId = messages.first.id;
    final countChanged = messages.length != _lastMessageCount;
    final newestChanged = newestId != _lastTopMessageId;

    _lastMessageCount = messages.length;
    _lastTopMessageId = newestId;

    if (!countChanged && !newestChanged) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isNearLatest() || newestChanged) {
        scrollToLatest(animated: countChanged);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<ChatMessage>>(
    stream: _messagesStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(p.gold),
          ),
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Could not load messages.',
            style: TextStyle(color: p.textSecondary),
          ),
        );
      }

      final messages = snapshot.data ?? const <ChatMessage>[];

      if (messages.isEmpty) {
        return _ChatEmptyState(palette: p);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onMessagesUpdated(messages);
      });

      return ListView.builder(
        controller: scrollController,
        reverse: true,
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        cacheExtent: 800,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isMe = message.isSentBy(currentUserId);

          final olderIndex = index + 1;
          final showSenderName = !isMe &&
              (olderIndex >= messages.length ||
                  messages[olderIndex].senderId != message.senderId);

          return MessageBubble(
            key: ValueKey(message.id),
            message: message,
            isMe: isMe,
            showSenderName: showSenderName,
          );
        },
      );
    },
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  final AppPalette palette;

  const _ChatEmptyState({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_rounded,
            size: 44,
            color: palette.gold.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send a message to start the conversation.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
