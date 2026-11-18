import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fertilizer_app/main.dart';

void main() {
  testWidgets('Krushi Mitra app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(KrushiMitraApp), findsOneWidget);
  });
}
