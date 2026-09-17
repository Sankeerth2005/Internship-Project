import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/features/referral/utils/referral_link_listener.dart';
import 'package:localink_mobile/features/referral/utils/referral_share_helper.dart';

void main() {
  group('ReferralLinkListener.extractCode', () {
    test('parses https invite query', () {
      final uri = Uri.parse(
        'https://vocalforsanatan.com/invite?code=K7M2NP',
      );
      expect(ReferralLinkListener.extractCode(uri), 'K7M2NP');
    });

    test('strips legacy VFS- prefix', () {
      final uri = Uri.parse(
        'https://vocalforsanatan.com/invite?code=VFS-AB12CD',
      );
      expect(ReferralLinkListener.extractCode(uri), 'AB12CD');
    });

    test('parses custom scheme', () {
      final uri = Uri.parse('vocalforsanatan://invite?code=vfs-x7k29p');
      expect(ReferralLinkListener.extractCode(uri), 'X7K29P');
    });

    test('ignores unrelated links', () {
      final uri = Uri.parse('https://vocalforsanatan.com/download');
      expect(ReferralLinkListener.extractCode(uri), isNull);
    });
  });

  group('ReferralShareHelper', () {
    test('includes code and link in message', () {
      final msg = ReferralShareHelper.buildMessage(
        referralCode: 'K7M2NP',
        referralLink: 'https://vocalforsanatan.com/invite?code=K7M2NP',
      );
      expect(msg, contains('K7M2NP'));
      expect(msg, contains('vocalforsanatan.com/invite'));
      expect(msg, contains('VocalForSanatan'));
    });
  });
}
