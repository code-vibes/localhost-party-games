import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'theme.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalHostPartyApp());
}

class LocalHostPartyApp extends StatelessWidget {
  const LocalHostPartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Local Host Party',
        debugShowCheckedModeBanner: false,
        theme: PartyTheme.light(),
        home: const HomePage(),
      ),
    );
  }
}
