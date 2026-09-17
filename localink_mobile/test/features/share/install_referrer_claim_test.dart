import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/core/storage/user_prefs_store.dart';
import 'package:localink_mobile/features/share/utils/install_referrer_claim.dart';

void main() {
  group('InstallReferrerClaim.parseShareContent', () {
    test('parses collection content', () {
      final pending = InstallReferrerClaim.parseShareContent(
        'collection_ABCDEFGHJKLMNPQR',
      );
      expect(pending?.kind, ShareLinkKind.collection);
      expect(pending?.token, 'ABCDEFGHJKLMNPQR');
    });

    test('parses business content', () {
      final pending = InstallReferrerClaim.parseShareContent(
        'business_ABCDEFGHJKLMNPQR',
      );
      expect(pending?.kind, ShareLinkKind.business);
    });

    test('rejects short tokens', () {
      expect(InstallReferrerClaim.parseShareContent('collection_ABC'), isNull);
    });

    test('rejects unknown kind', () {
      expect(
        InstallReferrerClaim.parseShareContent('invite_ABCDEFGHJKLMNPQR'),
        isNull,
      );
    });
  });
}
