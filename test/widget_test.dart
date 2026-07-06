import 'package:flutter_test/flutter_test.dart';

import 'package:procell_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProcellApp());
    await tester.pump();

    expect(find.text('ProCell Store'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
