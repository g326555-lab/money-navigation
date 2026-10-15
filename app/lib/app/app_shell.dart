import 'package:flutter/material.dart';

import '../features/assistant/assistant_screen.dart';
import '../features/home/home_screen.dart';
import '../features/records/records_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/speak/haggle_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/app_tab_bar.dart';
import '../shared/content_width.dart';

/// Home, Assistant and Records live under the floating tab bar. Scan and Speak are
/// full-screen flows, so their tabs open them on top instead of switching.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

enum _Tab { home, scan, speak, assistant, records }

class _AppShellState extends State<AppShell> {
  _Tab _page = _Tab.home;

  void _open(Widget screen) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => screen, fullscreenDialog: true),
  );

  void _select(int index) {
    switch (_Tab.values[index]) {
      case _Tab.scan:
        _open(const ScanScreen());
      case _Tab.speak:
        _open(const HaggleScreen());
      case final tab:
        setState(() => _page = tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: switch (_page) {
          _Tab.assistant => 1,
          _Tab.records => 2,
          _ => 0,
        },
        children: [
          ContentWidth(
            child: HomeScreen(
              onScan: () => _open(const ScanScreen()),
              onSeeAll: () => setState(() => _page = _Tab.records),
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              onOpenAssistant: () => setState(() => _page = _Tab.assistant),
            ),
          ),
          const ContentWidth(child: AssistantScreen()),
          const ContentWidth(child: RecordsScreen()),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        selected: _page.index,
        onSelected: _select,
        tabs: [
          AppTab(
            label: l10n.tabHome,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
          ),
          AppTab(
            label: l10n.tabScan,
            icon: Icons.document_scanner_outlined,
            activeIcon: Icons.document_scanner_rounded,
          ),
          AppTab(
            label: l10n.tabSpeak,
            icon: Icons.mic_none_rounded,
            activeIcon: Icons.mic_rounded,
          ),
          AppTab(
            label: l10n.tabAssistant,
            icon: Icons.navigation_outlined,
            activeIcon: Icons.navigation_rounded,
          ),
          AppTab(
            label: l10n.tabRecords,
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
          ),
        ],
      ),
    );
  }
}
