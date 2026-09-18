import 'package:flutter_test/flutter_test.dart';

import 'package:safewalk/main.dart';

void main() {
  testWidgets('Launch screen shows the SafeWalk brand', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeWalkApp());

    expect(find.text('SafeWalk'), findsOneWidget);
    expect(find.text('walk together, arrive safe'), findsOneWidget);

    // Let the launch screen's auto-navigate timer resolve before the test ends.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
