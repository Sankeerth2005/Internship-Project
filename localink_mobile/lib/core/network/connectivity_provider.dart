import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline, unknown }

class ConnectivityNotifier extends Notifier<NetworkStatus> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  NetworkStatus build() {
    _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen(_onChange);
    ref.onDispose(() => _sub?.cancel());

    Future.microtask(_prime);
    return NetworkStatus.unknown;
  }

  Future<void> _prime() async {
    try {
      final results = await Connectivity().checkConnectivity();
      state = _map(results);
    } catch (_) {
      state = NetworkStatus.unknown;
    }
  }

  void _onChange(List<ConnectivityResult> results) {
    state = _map(results);
  }

  NetworkStatus _map(List<ConnectivityResult> results) {
    if (results.isEmpty) return NetworkStatus.offline;
    if (results.every((r) => r == ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, NetworkStatus>(ConnectivityNotifier.new);

final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider) == NetworkStatus.offline;
});
