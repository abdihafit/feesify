// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:feesify/features/auth/pending_approval_screen.dart';
import 'package:feesify/main.dart';

void main() {
  testWidgets('renders school finance app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const SchoolFinanceApp(
        home: PendingApprovalScreen(
          title: 'School Finance System',
          message: 'Test',
        ),
      ),
    );

    expect(find.text('School Finance System'), findsOneWidget);
  });
}
