import 'package:flutter_test/flutter_test.dart';
import 'package:localhost_party_games/main.dart';

void main() {
  testWidgets('Home shows brand', (tester) async {
    await tester.pumpWidget(const LocalHostPartyApp());
    expect(find.text('1234'), findsOneWidget);
    expect(find.text('PARTY GAMES'), findsOneWidget);
    expect(find.text('PLAY ON THIS DEVICE'), findsOneWidget);
  });
}
