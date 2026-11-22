import 'package:http/http.dart' as http;

import '../../data/cache/local_snapshot_cache_store.dart';
import '../../data/cache/user_workspace_store.dart';
import '../../data/datasources/binance_market_provider.dart';
import '../../data/datasources/bnm_xml_provider.dart';
import '../../data/datasources/frankfurter_forex_provider.dart';
import '../../data/datasources/yahoo_stock_provider.dart';
import '../../data/repositories/market_repository_impl.dart';
import '../../domain/repositories/market_repository.dart';
import '../../domain/usecases/calculate_period_analytics.dart';
import '../../domain/usecases/convert_assets.dart';
import '../../domain/usecases/load_market_snapshot.dart';
import '../../presentation/controllers/converter_controller.dart';
import '../../presentation/controllers/market_terminal_controller.dart';

/// Composition root assembling dependencies via SOLID Dependency Inversion.
class ServiceLocator {
  ServiceLocator._({
    required this.httpClient,
    required this.marketRepository,
    required this.terminalController,
    required this.converterController,
  });

  factory ServiceLocator.createProduction() {
    final client = http.Client();
    final cacheStore = LocalSnapshotCacheStore();
    final workspaceStore = UserWorkspaceStore();

    final repository = MarketRepositoryImpl(
      providers: [
        BinanceMarketProvider(client: client),
        YahooStockProvider(client: client),
        FrankfurterForexProvider(client: client),
        BnmXmlProvider(client: client),
      ],
      cacheStore: cacheStore,
    );

    const analyticsUseCase = CalculatePeriodAnalytics();
    final loadSnapshotUseCase = LoadMarketSnapshot(repository);
    const convertUseCase = ConvertAssets();

    final terminal = MarketTerminalController(
      loadMarketSnapshot: loadSnapshotUseCase,
      calculatePeriodAnalytics: analyticsUseCase,
      repository: repository,
      workspaceStore: workspaceStore,
    );

    final converter = ConverterController(
      convertAssets: convertUseCase,
    );

    return ServiceLocator._(
      httpClient: client,
      marketRepository: repository,
      terminalController: terminal,
      converterController: converter,
    );
  }

  final http.Client httpClient;
  final MarketRepository marketRepository;
  final MarketTerminalController terminalController;
  final ConverterController converterController;

  void dispose() {
    terminalController.dispose();
    converterController.dispose();
    httpClient.close();
  }
}
