import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/chat_provider.dart';
import '../../../shared/presentation/widgets/app_state_widget.dart';
import '../../../../core/theme/app_theme.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  final bool isOwner;

  const ConversationsScreen({super.key, required this.isOwner});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isOwner) {
        ref.read(chatProvider.notifier).loadOwnerConversations();
      } else {
        ref.read(chatProvider.notifier).loadUserConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
      ),
      body: chatState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor),
            )
          : chatState.error != null
              ? AppStateWidget.error(
                  message: 'Could not load conversations.',
                  onRetry: () {
                    if (widget.isOwner) {
                      ref.read(chatProvider.notifier).loadOwnerConversations();
                    } else {
                      ref.read(chatProvider.notifier).loadUserConversations();
                    }
                  },
                )
              : chatState.conversations.isEmpty
                  ? _buildEmptyState()
                  : _buildList(chatState.conversations),
    );
  }

  Widget _buildEmptyState() {
    return AppStateWidget.empty(
      title: 'No messages yet',
      description: widget.isOwner
          ? 'When users message your business, they will appear here.'
          : 'Start a conversation with a business from their profile.',
      icon: Icons.chat_bubble_outline_rounded,
    );
  }

  Widget _buildList(List<Conversation> conversations) {
    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderColor),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final title =
            widget.isOwner ? (conv.userName ?? 'User') : (conv.businessName ?? 'Business');
        final image = widget.isOwner ? null : conv.businessImage;
        final time = DateFormat('MMM d, h:mm a').format(conv.lastMessageAt.toLocal());

        return Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push(
                '/chat/${conv.id}?role=${widget.isOwner ? "Owner" : "User"}&title=$title',
              );
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.surfaceColor,
                backgroundImage: image != null && image.isNotEmpty
                    ? NetworkImage(image)
                    : null,
                child: image == null || image.isEmpty
                    ? Icon(
                        widget.isOwner
                            ? Icons.person_rounded
                            : Icons.storefront_rounded,
                        color: AppTheme.accentColor,
                      )
                    : null,
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              subtitle: Text(
                time,
                style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedTextColor),
            ),
          ),
        );
      },
    );
  }
}
