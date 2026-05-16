import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../utils/app_palette.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSenderName;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showSenderName,
    this.showTimestamp = true,
  });

  String get _initials {
    final parts = message.senderName.trim().split(RegExp(r'[\s._@]+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return message.senderName.isNotEmpty
        ? message.senderName[0].toUpperCase()
        : '?';
  }

  String? get _timeLabel {
    final ts = message.timestamp;
    if (ts == null) return null;
    final hour = ts.hour % 12 == 0 ? 12 : ts.hour % 12;
    final minute = ts.minute.toString().padLeft(2, '0');
    final period = ts.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final bubbleColor = isMe
        ? const Color(0xFF005C4B)
        : (Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF1F2C34));

    return Padding(
      padding: EdgeInsets.only(
        top: showSenderName ? 10 : 2,
        bottom: 2,
        left: isMe ? 48 : 8,
        right: isMe ? 8 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showSenderName) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: p.surfaceAlt,
              child: Text(
                _initials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: p.gold,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ] else if (!isMe) ...[
            const SizedBox(width: 34),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderName && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: isMe ? Colors.white : p.textPrimary,
                        ),
                      ),
                      if (showTimestamp && _timeLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _timeLabel!,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.65)
                                : p.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
