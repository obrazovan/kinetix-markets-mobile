import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/di/service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final locator = ServiceLocator.createProduction();
  unawaited(locator.terminalController.initialize());

  runApp(
    KinetixMarketsApp(
      terminalController: locator.terminalController,
      converterController: locator.converterController,
    ),
  );
}
