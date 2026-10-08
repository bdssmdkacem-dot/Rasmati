import 'package:flutter_test/flutter_test.dart';
import 'package:rasmati/main.dart';

void main() {
  testWidgets('home screen introduces Rasmati and drawing actions', (tester) async {
    await tester.pumpWidget(const RasmatiApp());
    expect(find.text('رسوماتي'), findsWidgets);
    expect(find.text('صوّر رسمة'), findsOneWidget);
    expect(find.text('اختر من المعرض'), findsOneWidget);
  });
}
