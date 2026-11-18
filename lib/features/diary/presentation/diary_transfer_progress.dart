import 'dart:convert';

/// Records completed destination writes after a transfer fails. The journal
/// lives for the current app session; it is not a durable transaction log.
class DiaryTransferProgress {
  final _copied = <String, Map<String, Object>>{};

  /// Use every persisted field, including nutrients excluded from entity
  /// equality. Non-finite legacy values are represented as strings.
  static String snapshot(Object? value) => jsonEncode(_jsonSafe(value));

  static Object? _jsonSafe(Object? value) {
    if (value is double && !value.isFinite) return value.toString();
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key, _jsonSafe(entry)));
    }
    if (value is Iterable) return value.map(_jsonSafe).toList();
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    return _jsonSafe((value as dynamic).toJson());
  }

  /// Avoids repeating an already completed copy when the same transfer is
  /// retried. Refuse a changed source so a move cannot delete a newer edit
  /// after copying an older version.
  Future<void> copyOnce(
    String transferKey,
    String entryKey,
    Object snapshot,
    Future<void> Function() copy,
  ) async {
    final entries = _copied[transferKey];
    final previous = entries?[entryKey];
    if (previous != null) {
      if (previous != snapshot) {
        throw const DiaryTransferSourceChanged();
      }
      return;
    }
    await copy();
    (_copied[transferKey] ??= {})[entryKey] = snapshot;
  }

  /// Keep completed copies on failure, including a source deletion failure.
  /// A completely successful transfer may be deliberately repeated later.
  Future<void> finish(
    String transferKey,
    Future<void> Function() deleteSources,
  ) async {
    await deleteSources();
    _copied.remove(transferKey);
  }
}

class DiaryTransferSourceChanged implements Exception {
  const DiaryTransferSourceChanged();
}

