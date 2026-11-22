import 'package:material_ui/material_ui.dart';

import '../presentation/controllers/converter_controller.dart';
import '../presentation/controllers/market_terminal_controller.dart';
import '../presentation/screens/home_shell_screen.dart';
import 'theme/terminal_theme.dart';

/// Top-level application widget binding theme and injected controllers.
class KinetixMarketsApp extends StatelessWidget {
  const KinetixMarketsApp({
    super.key,
    required this.terminalController,
    required this.converterController,
  });

  final MarketTerminalController terminalController;
  final ConverterController converterController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: terminalController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Kinetix Markets',
          debugShowCheckedModeBanner: false,
          theme: TerminalTheme.build(isDark: false),
          darkTheme: TerminalTheme.build(isDark: true),
          themeMode: terminalController.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: HomeShellScreen(
            terminalController: terminalController,
            converterController: converterController,
          ),
        );
      },
    );
  }
}
