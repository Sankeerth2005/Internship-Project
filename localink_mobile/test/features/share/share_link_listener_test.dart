import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/core/storage/user_prefs_store.dart';
import 'package:localink_mobile/features/share/utils/share_link_listener.dart';

void main() {
  group('ShareLinkListener.extractPending', () {
    test('parses https collection link', () {
      final uri = Uri.parse(
        'https://vocalforsanatan.com/share/collection/ABCDEFGHJKLMNPQR',
      );
      final pending = ShareLinkListener.extractPending(uri);
      expect(pending, isNotNull);
      expect(pending!.kind, ShareLinkKind.collection);
      expect(pending.token, 'ABCDEFGHJKLMNPQR');
    });

    test('parses https business link', () {
      final uri = Uri.parse(
        'https://www.vocalforsanatan.com/share/business/ABCDEFGHJKLMNPQR',
      );
      final pending = ShareLinkListener.extractPending(uri);
      expect(pending?.kind, ShareLinkKind.business);
    });

    test('parses custom scheme', () {
      final uri = Uri.parse(
        'vocalforsanatan://share/business/ABCDEFGHJKLMNPQR',
      );
      final pending = ShareLinkListener.extractPending(uri);
      expect(pending?.kind, ShareLinkKind.business);
      expect(pending?.token, 'ABCDEFGHJKLMNPQR');
    });

    test('parses path-only share link from GoRouter', () {
      final uri = Uri.parse('/share/collection/ABCDEFGHJKLMNPQR');
      final pending = ShareLinkListener.extractPending(uri);
      expect(pending?.kind, ShareLinkKind.collection);
      expect(pending?.token, 'ABCDEFGHJKLMNPQR');
    });

    test('appRouteForUri maps collection path', () {
      final uri = Uri.parse(
        'https://vocalforsanatan.com/share/collection/ABCDEFGHJKLMNPQR',
      );
      expect(
        ShareLinkListener.appRouteForUri(uri),
        '/share/collection/ABCDEFGHJKLMNPQR',
      );
    });

    test('ignores invite links', () {
      final uri = Uri.parse('https://vocalforsanatan.com/invite?code=K7M2NP');
      expect(ShareLinkListener.extractPending(uri), isNull);
    });
  });
}
