import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/features/referral/utils/referral_link_listener.dart';
import 'package:localink_mobile/features/referral/utils/referral_share_helper.dart';

void main() {
  group('ReferralLinkListener.extractCode', () {
    test('parses https invite query', () {
      final uri = Uri.parse(
        'https://vocalforsanatan.com/invite?code=VFS-AB12CD',
      );
      expect(ReferralLinkListener.extractCode(uri), 'VFS-AB12CD');
    });

    test('parses custom scheme', () {
      final uri = Uri.parse('vocalforsanatan://invite?code=vfs-x7k29p');
      expect(ReferralLinkListener.extractCode(uri), 'VFS-X7K29P');
    });

    test('ignores unrelated links', () {
      final uri = Uri.parse('https://vocalforsanatan.com/download');
      expect(ReferralLinkListener.extractCode(uri), isNull);
    });
  });

  group('ReferralShareHelper', () {
    test('includes code and link in message', () {
      final msg = ReferralShareHelper.buildMessage(
        referralCode: 'VFS-TEST01',
        referralLink: 'https://vocalforsanatan.com/invite?code=VFS-TEST01',
      );
      expect(msg, contains('VFS-TEST01'));
      expect(msg, contains('vocalforsanatan.com/invite'));
      expect(msg, contains('VocalForSanatan'));
    });
  });
}
