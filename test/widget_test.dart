import 'package:flutter_test/flutter_test.dart';
import 'package:app_movil_wati/app.dart';

void main() {
  testWidgets('App renders WATI text', (WidgetTester tester) async {
    await tester.pumpWidget(const WatiApp());
    expect(find.text('WATI'), findsOneWidget);
  });
}