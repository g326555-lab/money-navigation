import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../features/scan/scan_screen.dart';
import 'theme.dart';

class MoneyNavigationApp extends StatelessWidget {
  const MoneyNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Part A is English. The demo switch (scene 4) will own the locale;
      // until then the device language must not turn the app Thai.
      locale: const Locale('en'),
      // Screens are added in demo order. Home (scene 3) will replace this.
      home: const ScanScreen(),
    );
  }
}
