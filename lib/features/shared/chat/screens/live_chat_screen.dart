import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Full-featured live chat screen between driver and passenger
class LiveChatScreen extends ConsumerStatefulWidget {
  const LiveChatScreen({
    super.key,
    this.rideId,
    this.driverName,
    this.driverId,
  });

  final String? rideId;
  final String? driverName;
  final String? driverId;

  @override
  ConsumerState<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends ConsumerState<LiveChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  static const _quickReplies = [
    'I am here',
    'Coming in 2 min',
    'Please wait',
    'Where are you?',
    'At the gate',
    'On my way',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize chat room if not already open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = ref.read(chatControllerProvider);
      if (chat.activeRoom == null) {
        ref.read(chatControllerProvider.notifier).openChatRoom(
              rideId: widget.rideId ?? 'ride_001',
              passengerId: 'passenger_001',
              driverId: widget.driverId ?? 'driver_001',
              passengerName: 'You',
              driverName: widget.driverName ?? 'Driver',
            );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatControllerProvider.notifier).sendMessage(
          text,
          isFromPassenger: true,
        );
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = chatState.messages;
    final driverName = chatState.activeRoom?.driverName ?? 'Driver';

    // Auto-scroll when new messages arrive
    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                driverName[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (chatState.isDriverTyping)
                  const Text(
                    'typing...',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Initiating voice call...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Privacy notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.info.withOpacity(0.08),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.info.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Messages are auto-deleted after ride ends for your privacy',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: messages.isEmpty
                ? _EmptyChatState(driverName: driverName)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: messages.length + (chatState.isDriverTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && chatState.isDriverTyping) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 4,
                              bottom: 8,
                            ),
                            child: TypingIndicator(name: driverName),
                          ),
                        );
                      }
                      final message = messages[index];
                      final showTimestamp = index == 0 ||
                          messages[index].timestamp
                                  .difference(messages[index - 1].timestamp)
                                  .inMinutes >
                              5;
                      return ChatBubble(
                        message: message,
                        showTimestamp: showTimestamp,
                      );
                    },
                  ),
          ),

          // Quick reply chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                return ActionChip(
                  label: Text(
                    _quickReplies[index],
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _sendMessage(_quickReplies[index]),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      isDark ? AppColors.darkCard : AppColors.lightCard,
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              MediaQuery.of(context).padding.bottom + AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_messageController.text),
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

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.driverName});
  final String driverName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chat with $driverName',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Send a quick message or use quick replies',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
