import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
      // Screens are added in demo order; the scan screen is the first one.
      home: const Scaffold(),
    );
  }
}
