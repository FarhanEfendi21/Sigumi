import 'package:flutter_test/flutter_test.dart';
import 'package:sigumi/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SigumiApp());
    await tester.pump();
    expect(find.text('SIGUMI'), findsWidgets);
  });
}
