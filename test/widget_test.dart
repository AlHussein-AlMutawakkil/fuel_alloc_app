import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_alloc_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FuelAllocApp());
    expect(find.byType(FuelAllocApp), findsOneWidget);
  });
}
