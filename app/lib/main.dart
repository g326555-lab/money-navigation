import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'services/auth/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Accounts are optional: without env/supabase.json this does nothing and
  // the app keeps everything on the phone.
  await initSupabase();
  runApp(const MoneyNavigationApp());
}
