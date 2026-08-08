import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/brand_icons.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String? profilePicture;
  final VoidCallback onProfileTap;
  final VoidCallback onAIFeedTap;
  final VoidCallback onLogoutTap;

  const HomeHeader({
    super.key,
    required this.userName,
    this.profilePicture,
    required this.onProfileTap,
    required this.onAIFeedTap,
    required this.onLogoutTap,
  });

  ImageProvider? _resolveImage(String? picture) {
    if (picture == null || picture.isEmpty) return null;

    if (picture.startsWith('data:image')) {
      final base64Data = picture.split(',').last;
      try {
        return MemoryImage(base64Decode(base64Data));
      } catch (_) {
        return null;
      }
    }

    final resolved = DioClient.resolveUrl(picture);
    if (resolved != null) {
      return NetworkImage(resolved);
    }

    return NetworkImage(picture);
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolveImage(profilePicture);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onProfileTap();
                  },
                  child: Hero(
                    tag: 'user_profile_avatar',
                    child: Container(
                      width: 48,
                      height: 48,
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
                            color: const Color(0xFFFF6600).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: imageProvider != null
                              ? Image(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Color(0xFFFF6600),
                                        size: 26,
                                      ),
                                    );
                                  },
                                )
                              : const Center(
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BrandIcons.om(size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            'Vocal for Sanatan',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFFFF6600),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userName.isEmpty ? 'Hello' : 'Hello, $userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                ),
              ],
            ),
          ),
          Row(
            children: [
              _TactileFeedback(
                onTap: onAIFeedTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6600).withValues(alpha: 0.12),
                        const Color(0xFFFF9E4F).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF6600).withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFF6600),
                        size: 15,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'AI',
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
                    size: 18,
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

class _TactileFeedback extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileFeedback({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: child,
    );
  }
}
