import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatWidget extends StatefulWidget {
  final String roomId;

  const ChatWidget({
    super.key,
    required this.roomId,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _hasText = false;

  // ── Brand Palette ──────────────────────────────────────────────
  static const Color _bg = Color(0xFF0D0F14);
  static const Color _surface = Color(0xFF161A23);
  static const Color _surfaceAlt = Color(0xFF1C2130);
  static const Color _gold = Color(0xFFCBA869);
  static const Color _goldLight = Color(0xFFE8C98A);
  static const Color _textPrimary = Color(0xFFF0EDE6);
  static const Color _textSecondary = Color(0xFF8A8FA0);
  static const Color _border = Color(0xFF2A2F3E);
  static const Color _myBubble = Color(0xFF1E2535);
  static const Color _myBubbleBorder = Color(0xFF2E3A50);

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('You must be logged in to send messages.');
      return;
    }

    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      final messagesRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages');

      await messagesRef.add({
        'senderId': user.uid,
        'senderName': user.displayName ?? user.email ?? 'Unknown',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _scrollToBottom();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showSnack(e.message ?? 'Failed to send message. Please try again.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
        content: Text(
          message,
          style: const TextStyle(color: _textPrimary, fontSize: 13.5),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // Returns initials from a display name or email
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s._@]+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Messages list ────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomId)
                .collection('messages')
                .orderBy('timestamp')
                .snapshots(),
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_gold),
                  ),
                );
              }

              // Empty state
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: _textSecondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "No messages yet.",
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Start the conversation!",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              final currentUser = FirebaseAuth.instance.currentUser;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              return ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final senderName =
                      (data['senderName'] as String?) ?? 'Unknown';
                  final senderId = data['senderId'] as String?;
                  final text = (data['text'] as String?) ?? '';
                  final isMe = currentUser != null &&
                      senderId != null &&
                      senderId == currentUser.uid;

                  // Show avatar only when sender changes
                  final prevSenderId = index > 0
                      ? (docs[index - 1].data()['senderId'] as String?)
                      : null;
                  final isFirstInGroup = prevSenderId != senderId;

                  return _ChatBubble(
                    text: text,
                    senderName: senderName,
                    isMe: isMe,
                    isFirstInGroup: isFirstInGroup,
                    initials: _initials(senderName),
                  );
                },
              );
            },
          ),
        ),

        // ── Input bar ────────────────────────────────────────────
        Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Row(
            children: [
              // Text field
              Expanded(
                child: _ChatInputField(
                  controller: _messageController,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              // Send button
              _SendButton(
                isSending: _isSending,
                hasText: _hasText,
                onTap: _isSending ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Chat Bubble ────────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isMe;
  final bool isFirstInGroup;
  final String initials;

  const _ChatBubble({
    required this.text,
    required this.senderName,
    required this.isMe,
    required this.isFirstInGroup,
    required this.initials,
  });

  static const Color _surface = Color(0xFF161A23);
  static const Color _surfaceAlt = Color(0xFF1C2130);
  static const Color _gold = Color(0xFFCBA869);
  static const Color _textPrimary = Color(0xFFF0EDE6);
  static const Color _textSecondary = Color(0xFF8A8FA0);
  static const Color _border = Color(0xFF2A2F3E);
  static const Color _myBubble = Color(0xFF1A2235);
  static const Color _myBubbleBorder = Color(0xFF263045);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 10 : 3,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other person's avatar
          if (!isMe) ...[
            if (isFirstInGroup)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _surfaceAlt,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _border),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 30),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name (first in group only)
                if (isFirstInGroup && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe ? _myBubble : _surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 14),
                    ),
                    border: Border.all(
                      color: isMe ? _myBubbleBorder : _border,
                    ),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: _textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // My avatar
          if (isMe) ...[
            const SizedBox(width: 8),
            if (isFirstInGroup)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _gold.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text(
                    "You",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCBA869),
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 30),
          ],
        ],
      ),
    );
  }
}

// ── Chat Input Field ───────────────────────────────────────────────────────────
class _ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  const _ChatInputField({
    required this.controller,
    this.onSubmitted,
  });

  @override
  State<_ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<_ChatInputField> {
  bool _focused = false;

  static const Color _bg = Color(0xFF0D0F14);
  static const Color _gold = Color(0xFFCBA869);
  static const Color _textPrimary = Color(0xFFF0EDE6);
  static const Color _textHint = Color(0xFF3E4455);
  static const Color _border = Color(0xFF2A2F3E);

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? _gold : _border,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: _gold.withOpacity(0.10),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          onSubmitted: widget.onSubmitted,
          textInputAction: TextInputAction.send,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 13.5,
          ),
          decoration: const InputDecoration(
            hintText: 'Say something…',
            hintStyle: TextStyle(color: _textHint, fontSize: 13.5),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

// ── Send Button ────────────────────────────────────────────────────────────────
class _SendButton extends StatefulWidget {
  final bool isSending;
  final bool hasText;
  final VoidCallback? onTap;

  const _SendButton({
    required this.isSending,
    required this.hasText,
    required this.onTap,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  static const Color _bg = Color(0xFF0D0F14);
  static const Color _gold = Color(0xFFCBA869);
  static const Color _goldLight = Color(0xFFE8C98A);
  static const Color _surface = Color(0xFF161A23);
  static const Color _border = Color(0xFF2A2F3E);
  static const Color _textSecondary = Color(0xFF8A8FA0);

  @override
  Widget build(BuildContext context) {
    final active = widget.hasText && !widget.isSending;

    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [_gold, _goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? Colors.transparent : _border,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _gold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: widget.isSending
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_bg),
                  ),
                )
              : Icon(
                  Icons.send_rounded,
                  size: 17,
                  color: active ? _bg : _textSecondary,
                ),
        ),
      ),
    );
  }
}
