import 'package:injectable/injectable.dart';

import '../../domain/repositories/sync_repository.dart';
import 'connectivity_service.dart';

/// Simple interface for checking network availability.
/// Inject this (instead of ConnectivityService directly) for easier mocking.
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

@Injectable(as: NetworkInfo)
final class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectivity);

  final ConnectivityService _connectivity;

  @override
  Future<bool> get isConnected async {
    final status = await _connectivity.checkNow();
    return status == ConnectivityStatus.online;
  }
}
