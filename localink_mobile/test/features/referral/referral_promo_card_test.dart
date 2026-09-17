import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:localink_mobile/features/referral/presentation/widgets/referral_promo_card.dart';

void main() {
  testWidgets('ReferralPromoCard opens /refer-support', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: ReferralPromoCard(subtitle: 'Test subtitle'),
          ),
        ),
        GoRoute(
          path: '/refer-support',
          builder: (_, __) => const Scaffold(
            body: Text('referral-dashboard'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Refer & Support'), findsOneWidget);
    expect(find.text('Test subtitle'), findsOneWidget);

    await tester.tap(find.text('Refer & Support'));
    await tester.pumpAndSettle();

    expect(find.text('referral-dashboard'), findsOneWidget);
    expect(router.state.uri.path, '/refer-support');
  });
}
