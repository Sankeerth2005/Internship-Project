import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/core/storage/user_prefs_store.dart';
import 'package:localink_mobile/features/share/utils/pending_share_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('pending share consume lifecycle', () {
    const pending = PendingShareRoute(
      kind: ShareLinkKind.collection,
      token: 'ABCDEFGHJKLMNPQR',
    );

    test('setPendingShare without force does not resurrect consumed token',
        () async {
      await UserPrefsStore.setPendingShare(pending, force: true);
      await UserPrefsStore.markShareConsumed(pending);

      await UserPrefsStore.setPendingShare(pending); // no force
      expect(await UserPrefsStore.getPendingShare(), isNull);
    });

    test('force setPendingShare allows reopening same token', () async {
      await UserPrefsStore.markShareConsumed(pending);
      await UserPrefsStore.setPendingShare(pending, force: true);

      final stored = await UserPrefsStore.getPendingShare();
      expect(stored?.kind, ShareLinkKind.collection);
      expect(stored?.token, 'ABCDEFGHJKLMNPQR');
    });

    test('pendingShareGoRoute peeks without consuming', () async {
      await UserPrefsStore.setPendingShare(pending, force: true);

      final route = await pendingShareGoRoute();
      expect(route, '/share/collection/ABCDEFGHJKLMNPQR');
      expect(await UserPrefsStore.getPendingShare(), isNotNull);

      await UserPrefsStore.markShareConsumed(pending);
      expect(await pendingShareGoRoute(), isNull);
    });

    test('pendingShareFromLocation parses collection and legacy paths', () {
      expect(
        pendingShareFromLocation('/share/collection/ABCDEFGHJKLMNPQR')?.kind,
        ShareLinkKind.collection,
      );
      expect(
        pendingShareFromLocation('/shared-collection/ABCDEFGHJKLMNPQR')?.token,
        'ABCDEFGHJKLMNPQR',
      );
      expect(pendingShareFromLocation('/home'), isNull);
    });
  });
}
