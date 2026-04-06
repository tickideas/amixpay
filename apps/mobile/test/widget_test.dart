import 'package:flutter_test/flutter_test.dart';
import 'package:amixpay_app/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AmixPayApp());
    await tester.pump();
  });
}
