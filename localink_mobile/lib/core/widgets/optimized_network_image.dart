import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../network/dio_client.dart';

/// Enterprise-style network image:
/// - Resolves relative `/uploads/...` paths
/// - Disk + memory cache (CachedNetworkImage)
/// - Placeholder + fade-in
/// - Automatic retry with backoff on failure
/// - Memory-aware decode via [memCacheWidth]/[memCacheHeight]
class OptimizedNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? placeholderColor;
  final IconData errorIcon;
  final Color? errorIconColor;
  final double errorIconSize;
  final Duration fadeInDuration;
  final int maxRetries;
  final int? memCacheWidth;
  final int? memCacheHeight;
  /// Optional cache key / version. When set, used as [CachedNetworkImage.cacheKey]
  /// and appended as `?v=` / `&v=` so updated photos bust disk/memory cache.
  final String? cacheKey;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderColor,
    this.errorIcon = Icons.broken_image_outlined,
    this.errorIconColor,
    this.errorIconSize = 32,
    this.fadeInDuration = const Duration(milliseconds: 280),
    this.maxRetries = 2,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
  });

  /// Convenience for business cover / list thumbnails.
  factory OptimizedNetworkImage.business({
    Key? key,
    required String? imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color placeholderColor = const Color(0xFFF0EFEA),
    Color iconColor = const Color(0xFFFF6600),
    double iconSize = 36,
    String? cacheKey,
  }) {
    return OptimizedNetworkImage(
      key: key,
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      borderRadius: borderRadius,
      placeholderColor: placeholderColor,
      errorIcon: Icons.storefront_rounded,
      errorIconColor: iconColor,
      errorIconSize: iconSize,
      cacheKey: cacheKey,
      // Decode near display size to cut RAM on list scrolls
      memCacheWidth: width != null && width.isFinite ? (width * 2).round() : 800,
      memCacheHeight: height != null && height.isFinite ? (height * 2).round() : 600,
    );
  }

  /// Evict a resolved image URL from the disk/memory cache (e.g. after photo replace).
  static Future<void> evict(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final resolved = DioClient.resolveUrl(imageUrl);
    if (resolved == null || resolved.isEmpty) return;
    try {
      await CachedNetworkImage.evictFromCache(resolved);
    } catch (_) {}
  }

  @override
  State<OptimizedNetworkImage> createState() => _OptimizedNetworkImageState();
}

class _OptimizedNetworkImageState extends State<OptimizedNetworkImage> {
  int _retryCount = 0;
  int _cacheBust = 0;

  String? get _resolved {
    final raw = widget.imageUrl;
    if (raw == null || raw.isEmpty) return null;
    return DioClient.resolveUrl(raw);
  }

  void _retry() {
    if (_retryCount >= widget.maxRetries) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 350 * (_retryCount + 1)), () {
        if (!mounted) return;
        setState(() {
          _retryCount++;
          _cacheBust++;
        });
      });
    });
  }

  Widget _placeholder() {
    if (widget.placeholder != null) return widget.placeholder!;
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.placeholderColor ?? const Color(0xFFF0EFEA),
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: (widget.errorIconColor ?? const Color(0xFFFF6600)).withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _error() {
    if (widget.errorWidget != null) return widget.errorWidget!;
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.placeholderColor ?? const Color(0xFFF0EFEA),
      alignment: Alignment.center,
      child: Icon(
        widget.errorIcon,
        color: widget.errorIconColor ?? const Color(0xFFFF6600),
        size: widget.errorIconSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolved;
    Widget child;

    if (url == null) {
      child = _error();
    } else {
      var requestUrl = url;
      final version = widget.cacheKey;
      if (version != null && version.isNotEmpty) {
        requestUrl = '$requestUrl${requestUrl.contains('?') ? '&' : '?'}v=${Uri.encodeQueryComponent(version)}';
      }
      if (_cacheBust > 0) {
        requestUrl = '$requestUrl${requestUrl.contains('?') ? '&' : '?'}_r=$_cacheBust';
      }
      child = CachedNetworkImage(
        imageUrl: requestUrl,
        cacheKey: version?.isNotEmpty == true ? version : null,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: widget.fadeInDuration,
        fadeOutDuration: const Duration(milliseconds: 120),
        memCacheWidth: widget.memCacheWidth,
        memCacheHeight: widget.memCacheHeight,
        placeholder: (context, url) => _placeholder(),
        errorWidget: (context, url, error) {
          if (_retryCount < widget.maxRetries) {
            _retry();
            return _placeholder();
          }
          return _error();
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }
}
