import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/features/shared/presentation/widgets/app_safe_bottom_bar.dart';

void main() {
  testWidgets('scaffold mode uses viewPadding when the keyboard is closed', (tester) async {
    late double inset;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: 48),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        child: Builder(
          builder: (context) {
            inset = AppSafeBottomBar.insetOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(inset, 48);
  });

  testWidgets('scaffold mode does not add inset while the keyboard is open', (tester) async {
    late double inset;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: 48),
          viewPadding: EdgeInsets.only(bottom: 48),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: Builder(
          builder: (context) {
            inset = AppSafeBottomBar.insetOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(inset, 0);
  });

  testWidgets('overlay mode keeps the larger of keyboard and system inset', (tester) async {
    late double closed;
    late double open;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        child: Builder(
          builder: (context) {
            closed = AppSafeBottomBar.insetOf(
              context,
              mode: AppSafeBottomMode.overlay,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          viewPadding: EdgeInsets.only(bottom: 48),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: Builder(
          builder: (context) {
            open = AppSafeBottomBar.insetOf(
              context,
              mode: AppSafeBottomMode.overlay,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(closed, 48);
    expect(open, 300);
  });
}
