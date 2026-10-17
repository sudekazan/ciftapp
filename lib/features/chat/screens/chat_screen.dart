import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/chat_provider.dart';
import 'surprise_message_dialog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecordingVoice = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    chatProvider.sendTextMessage(
      senderId: 'me',
      senderName: appState.currentUser.name,
      text: text,
    );

    _textController.clear();
    _scrollToBottom();
  }

  void _sendVoiceNote() {
    setState(() => _isRecordingVoice = true);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    chatProvider.sendVoiceNote(
      senderId: 'me',
      senderName: appState.currentUser.name,
      durationSeconds: 16,
    );

    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isRecordingVoice = false);
    });
  }

  void _openSurpriseDialog() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => SurpriseMessageDialog(
        onSchedule: (text, date) {
          chatProvider.sendSurpriseMessage(
            senderId: 'me',
            senderName: appState.currentUser.name,
            text: text,
            scheduledDate: date,
          );
          _scrollToBottom();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final partnerName = appState.currentUser.partnerName ?? 'Can';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: AppColors.heartGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Çevrim içi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: AppColors.accentTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.primary),
            tooltip: 'Hızlı Kalp Gönder',
            onPressed: () {
              appState.triggerThinkingOfYou();
              chatProvider.sendThinkingOfYouMessage(
                senderId: 'me',
                senderName: appState.currentUser.name,
              );
              _scrollToBottom();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[index];
                final isMe = message.senderId == 'me';
                return _buildMessageBubble(message, isMe, theme, isDark);
              },
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Surprise button
                  IconButton(
                    icon: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
                    tooltip: 'Sürpriz Mesaj Zamanla',
                    onPressed: _openSurpriseDialog,
                  ),

                  // Voice note button
                  IconButton(
                    icon: Icon(
                      _isRecordingVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isRecordingVoice ? Colors.red : AppColors.secondary,
                    ),
                    tooltip: 'Sesli Not Gönder',
                    onPressed: () {
                      _sendVoiceNote();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sesli mesaj gönderildi! 🎙️'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: l10n.text('type_message'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        fillColor: isDark ? AppColors.darkSurface : AppColors.background,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, ThemeData theme, bool isDark) {
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    if (message.type == ChatMessageType.thinkingOfYou) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                '${message.senderName} sana sevgi dokunuşu gönderdi! ❤️',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }

    if (message.type == ChatMessageType.surprise) {
      final isLocked = message.isLockedSurprise;

      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isLocked ? AppColors.purpleGradient : AppColors.heartGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLocked ? Icons.lock_clock_rounded : Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLocked ? 'Zaman Ayarlı Sürpriz' : 'Sürpriz Açıldı! 🎉',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isLocked
                  ? 'Bu mesaj partnerin için bir sır! Belirlenen saatte açılacak. 🎁'
                  : message.text,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (message.scheduledUnlockDate != null)
                    Text(
                      'Tarih: ${DateFormat('d MMM, HH:mm').format(message.scheduledUnlockDate!)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                    ),
                  if (isLocked)
                    InkWell(
                      onTap: () {
                        Provider.of<ChatProvider>(context, listen: false).unlockSurprise(message.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Şimdi Aç (Test)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (message.type == ChatMessageType.voice) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primary
                : (isDark ? AppColors.darkCardBg : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMe ? Colors.transparent : (isDark ? AppColors.darkDivider : AppColors.divider),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withOpacity(0.25) : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isMe ? Colors.white : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Simulated Audio Waveform
              Row(
                children: List.generate(
                  15,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 3,
                    height: ((i % 4) + 1) * 6.0 + 4,
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withOpacity(0.8) : AppColors.primary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '0:${message.voiceDurationSeconds?.toString().padLeft(2, '0') ?? "14"}',
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Standard Text Message Bubble
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onDoubleTap: () {
          Provider.of<ChatProvider>(context, listen: false).toggleReaction(message.id);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCardBg : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isMe ? Colors.transparent : (isDark ? AppColors.darkDivider : AppColors.divider),
                ),
                boxShadow: [
                  if (!isMe && !isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (message.reaction != null)
              Positioned(
                bottom: -2,
                right: isMe ? null : 8,
                left: isMe ? 8 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.reaction!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
