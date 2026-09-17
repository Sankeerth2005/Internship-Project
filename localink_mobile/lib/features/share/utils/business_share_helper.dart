import '../../../core/config/app_config.dart';
import '../data/models/share_models.dart';
import '../../business/data/models/business_models.dart';

class BusinessShareHelper {
  static String businessLinkFor(String publicToken) {
    final base = AppConfig.shareBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/business/$publicToken';
  }

  static String collectionLinkFor(String publicToken) {
    final base = AppConfig.shareBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/collection/$publicToken';
  }

  static String buildSingleBusinessMessage({
    required BusinessDto business,
    required String shareUrl,
  }) {
    final category = (business.categoryName ?? '').trim();
    final locationParts = [
      if (business.city.trim().isNotEmpty) business.city.trim(),
      if (business.state.trim().isNotEmpty) business.state.trim(),
    ];
    final location = locationParts.join(', ');

    final buffer = StringBuffer()
      ..writeln('🙏 I thought you might find this business useful!')
      ..writeln()
      ..writeln('🏪 ${business.businessName}');

    if (category.isNotEmpty) {
      buffer.writeln('📂 $category');
    }
    if (location.isNotEmpty) {
      buffer.writeln('📍 $location');
    }

    buffer
      ..writeln()
      ..writeln('🔗 View it on VocalForSanatan:')
      ..writeln(shareUrl)
      ..writeln()
      ..writeln('🚩 Discover and support Sanatan businesses.');

    return buffer.toString().trim();
  }

  static String buildCollectionMessage({
    required String shareUrl,
    String? title,
    String? note,
  }) {
    final displayTitle =
        (title != null && title.trim().isNotEmpty)
            ? title.trim()
            : 'Businesses shared with you';

    final buffer = StringBuffer()
      ..writeln(
        '🙏 I found some businesses on VocalForSanatan that you may find useful.',
      )
      ..writeln()
      ..writeln('📋 $displayTitle');

    if (note != null && note.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(note.trim());
    }

    buffer
      ..writeln()
      ..writeln('🔗 View the businesses:')
      ..writeln(shareUrl)
      ..writeln()
      ..writeln(
        '🚩 Discover and support Sanatan businesses with VocalForSanatan.',
      );

    return buffer.toString().trim();
  }

  static Uri whatsappShareUri(String message) {
    return Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
  }

  static String linkForCreated(ShareCreatedResult result) {
    if (result.shareUrl.isNotEmpty) return result.shareUrl;
    return result.shareKind == 'business'
        ? businessLinkFor(result.publicToken)
        : collectionLinkFor(result.publicToken);
  }
}
