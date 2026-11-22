/// Base hierarchy for domain and infrastructure failures.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, [this.details]);

  final String message;
  final String? details;

  @override
  String toString() => details == null ? message : '$message ($details)';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, [super.details]);
}

final class ParseFailure extends AppFailure {
  const ParseFailure(super.message, [super.details]);
}

final class CacheFailure extends AppFailure {
  const CacheFailure(super.message, [super.details]);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, [super.details]);
}
