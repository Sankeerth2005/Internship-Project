import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;
  final VoidCallback onAIFeedTap;
  final VoidCallback onLogoutTap;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.onProfileTap,
    required this.onAIFeedTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting & Profile Avatar Group
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onProfileTap();
                },
                child: Hero(
                  tag: 'user_profile_avatar',
                  child: Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9E4F), Color(0xFFFF6600)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6600).withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: Color(0xFFFF6600),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello 👋',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF5F5C58),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF1A1918),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions Group (AI Feed + Logout)
          Row(
            children: [
              // Premium AI Feed Button
              _TactileFeedback(
                onTap: onAIFeedTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6600).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF6600).withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFF6600),
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'AI Feed',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFFF6600),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Signout Button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE1251B).withValues(alpha: 0.08),
                    border: Border.all(
                      color: const Color(0xFFE1251B).withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE1251B),
                    size: 16,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onLogoutTap();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Private widget to handle elastic press micro-interaction
class _TactileFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileFeedback({required this.child, required this.onTap});

  @override
  State<_TactileFeedback> createState() => _TactileFeedbackState();
}

class _TactileFeedbackState extends State<_TactileFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
