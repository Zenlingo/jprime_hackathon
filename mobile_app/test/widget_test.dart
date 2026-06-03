import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const JPrimeApp());
    expect(find.text('Welcome to jPrime.'), findsOneWidget);
  });
}
