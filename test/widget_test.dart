import 'package:flutter_test/flutter_test.dart';
import 'package:child_connect/main.dart';

void main() {
  testWidgets('Child Connect app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChildConnectApp());
    expect(find.byType(ChildConnectApp), findsOneWidget);
  });
}
