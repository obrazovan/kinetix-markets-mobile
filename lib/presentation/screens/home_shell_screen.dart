import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';
import '../controllers/converter_controller.dart';
import '../controllers/market_terminal_controller.dart';
import 'converter_screen.dart';
import 'markets_terminal_screen.dart';
import 'period_comparison_screen.dart';
import 'portfolio_screen.dart';

/// Root navigation shell connecting Markets, Unified Analytics, Portfolio, and Converter.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({
    super.key,
    required this.terminalController,
    required this.converterController,
  });

  final MarketTerminalController terminalController;
  final ConverterController converterController;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.terminalController.addListener(_onTerminalChanged);
    widget.converterController.syncSnapshot(widget.terminalController.snapshot);
  }

  @override
  void dispose() {
    widget.terminalController.removeListener(_onTerminalChanged);
    super.dispose();
  }

  void _onTerminalChanged() {
    widget.converterController.syncSnapshot(widget.terminalController.snapshot);
  }

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.terminalController,
        widget.converterController,
      ]),
      builder: (context, _) {
        final isOffline = widget.terminalController.isOffline;
        final statusColor = isOffline ? palette.warning : palette.bull;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'KINETIX',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isOffline ? 'ОФЛАЙН' : 'LIVE',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: widget.terminalController.isDarkMode
                    ? 'Светлая тема'
                    : 'Тёмная тема',
                onPressed: widget.terminalController.toggleTheme,
                icon: Icon(
                  widget.terminalController.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Обновить котировки',
                onPressed: widget.terminalController.isLoading
                    ? null
                    : widget.terminalController.refresh,
                icon: widget.terminalController.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.accent,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: IndexedStack(
            index: _tabIndex,
            children: [
              MarketsTerminalScreen(
                controller: widget.terminalController,
                onOpenAnalytics: (symbol, timeframe) {
                  widget.terminalController.selectAnalyticsAsset(symbol);
                  widget.terminalController.selectTimeframe(timeframe);
                  setState(() => _tabIndex = 1);
                },
              ),
              PeriodComparisonScreen(
                controller: widget.terminalController,
              ),
              PortfolioScreen(
                controller: widget.terminalController,
              ),
              ConverterScreen(
                terminalController: widget.terminalController,
                converterController: widget.converterController,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.candlestick_chart_outlined),
                selectedIcon: Icon(Icons.candlestick_chart_rounded),
                label: 'Рынок',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: 'Аналитика',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded),
                label: 'Портфель',
              ),
              NavigationDestination(
                icon: Icon(Icons.currency_exchange_outlined),
                selectedIcon: Icon(Icons.currency_exchange_rounded),
                label: 'Конвертер',
              ),
            ],
          ),
        );
      },
    );
  }
}
