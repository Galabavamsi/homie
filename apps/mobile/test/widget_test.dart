import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_mobile/presentation/app.dart';

void main() {
  testWidgets('Homie app renders splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomieApp()));

    expect(find.text('Homie'), findsOneWidget);
    expect(find.text('Group ordering, powered by Swiggy MCP'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Enter Homie locally'), findsOneWidget);
  });
}
