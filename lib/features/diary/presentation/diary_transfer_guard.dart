import 'package:flutter/foundation.dart';

/// Keeps a diary transfer exclusive until all of its writes have completed.
class DiaryTransferGuard extends ChangeNotifier {
  bool _running = false;
  bool _deleting = false;
  int _pendingDeletes = 0;

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

  /// Section deletion invokes one callback per item without awaiting it.
  /// Keep the guard held for the entire batch while allowing each deletion
  /// through; the tracked-day lock serializes their database writes.
  Future<void> runDelete(Future<void> Function() delete) async {
    if (_running && !_deleting) return;
    if (!_running) {
      _running = true;
      _deleting = true;
      notifyListeners();
    }
    _pendingDeletes++;
    try {
      await delete();
    } finally {
      _pendingDeletes--;
      if (_pendingDeletes == 0) {
        _deleting = false;
        _running = false;
        notifyListeners();
      }
    }
  }
}
