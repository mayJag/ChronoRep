import 'package:flutter_test/flutter_test.dart';

import 'package:chronorep/main.dart';

void main() {
  testWidgets('App boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ChronoRepApp());
    // The wordmark on the splash screen should be present after first frame.
    expect(find.text('ChronoRep'), findsOneWidget);
  });
}
