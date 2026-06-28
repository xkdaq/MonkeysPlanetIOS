import 'package:flutter_test/flutter_test.dart';
import 'package:monkeysplanetios/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MonkeysPlanetApp());
    expect(find.text('猴哥星球'), findsNothing); // 初始页面是 MainTabs
  });
}
