import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/repositories/sync_repository.dart';

/// Emits [ConnectivityStatus] changes using the `connectivity_plus` package.
///
/// Debounced by 500ms to avoid rapid flapping on unstable networks.
@singleton
final class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  late final Stream<ConnectivityStatus> statusStream = _connectivity
      .onConnectivityChanged
      .debounceTime(const Duration(milliseconds: 500))
      .map(_mapResults)
      .distinct()
      .asBroadcastStream();

  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
    return hasConnection
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }

  /// Checks current connectivity status once (non-streaming).
  Future<ConnectivityStatus> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }
}
