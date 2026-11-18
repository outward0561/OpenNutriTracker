import 'package:flutter/foundation.dart';

/// Keeps a diary transfer exclusive until all of its writes have completed.
class DiaryTransferGuard extends ChangeNotifier {
  bool _running = false;

  bool get isRunning => _running;

  /// Ignores an overlapping request. A failed or cancelled transfer releases
  /// the guard so the user can try again.
  Future<void> run(Future<void> Function() transfer) async {
    if (_running) return;
    _running = true;
    notifyListeners();
    try {
      await transfer();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
