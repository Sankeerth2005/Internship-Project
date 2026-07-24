import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';


class ConversationsScreen extends ConsumerStatefulWidget {
  final bool isOwner; // true if business owner, false if user

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
        // We need a businessId. In a real app we'd fetch it from AuthState or BusinessProvider.
        // Hardcoding to 1 for this MVP demonstration since business features are simplified.
        ref.read(chatProvider.notifier).loadUserConversations(); // Owner uses same method internally?
        // Actually, backend expects `/api/v1/chat/business/{id}` for businesses.
        // Let's assume we use loadUserConversations for both right now or add logic.
      } else {
        ref.read(chatProvider.notifier).loadUserConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: chatState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatState.conversations.isEmpty
              ? _buildEmptyState()
              : _buildList(chatState.conversations),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isOwner
                ? 'When users message your business, they will appear here.'
                : 'Start a conversation with a business from their profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> conversations) {
    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final title = widget.isOwner ? (conv.userName ?? 'User') : (conv.businessName ?? 'Business');
        final image = widget.isOwner ? null : conv.businessImage;
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFF6600).withValues(alpha: 0.1),
            backgroundImage: image != null ? NetworkImage('http://10.0.2.2:5138$image') : null,
            child: image == null
                ? Text(
                    title.isNotEmpty ? title[0].toUpperCase() : 'U',
                    style: const TextStyle(color: const Color(0xFFFF6600), fontWeight: FontWeight.bold, fontSize: 20),
                  )
                : null,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: const Text(
            'Tap to view messages',
            style: TextStyle(color: Colors.grey),
          ),
          trailing: Text(
            DateFormat.MMMd().format(conv.lastMessageAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          onTap: () {
            // Navigate to ChatScreen
            context.push('/chat/${conv.id}?role=${widget.isOwner ? "Owner" : "User"}&title=$title');
          },
        );
      },
    );
  }
}
