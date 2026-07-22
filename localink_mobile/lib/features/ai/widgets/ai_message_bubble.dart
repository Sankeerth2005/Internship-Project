import 'package:flutter/material.dart';

class AiMessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const AiMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6600).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFFF6600), size: 16),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFFFF6600) : const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                  ),
                  border: isUser 
                      ? null 
                      : Border.all(color: const Color(0xFFEAE8E3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF1A1918),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEAE8E3)),
                ),
                child: const Icon(Icons.person, color: Color(0xFF5F5C58), size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
