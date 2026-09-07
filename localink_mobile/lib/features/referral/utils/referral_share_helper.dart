import '../../../../core/config/app_config.dart';

/// Builds the WhatsApp / native share message for referrals.
class ReferralShareHelper {
  static String buildMessage({
    required String referralCode,
    String? referralLink,
  }) {
    final link = (referralLink == null || referralLink.isEmpty)
        ? AppConfig.referralLinkFor(referralCode)
        : referralLink;

    return '''
🙏 Support Sanatani Businesses!

I am using VocalForSanatan to support and discover Sanatan/Hindu-owned businesses around us.

Please join VocalForSanatan and help strengthen our community by supporting Sanatani businesses and business owners.

📲 Download / Join:
$link

🔗 My Referral Code: $referralCode

Let's strengthen our community by supporting our own businesses. 🇮🇳🚩
'''.trim();
  }

  static Uri whatsappShareUri(String message) {
    return Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
  }
}
