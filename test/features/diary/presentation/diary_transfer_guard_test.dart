import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/diary/presentation/diary_transfer_guard.dart';

void main() {
  test('a second move cannot copy or debit the same day during a slow move',
      () async {
    final guard = DiaryTransferGuard();
    final allowWrite = Completer<void>();
    var sourceCalories = 250;
    var destinationCalories = 0;
    var copiedEntries = 0;

    Future<void> moveDay() async {
      await allowWrite.future;
      copiedEntries++;
      destinationCalories += 250;
      sourceCalories -= 250;
    }

    final first = guard.run(moveDay);
    expect(guard.isRunning, isTrue);
    await guard.run(moveDay);
    allowWrite.complete();
    await first;

    expect(copiedEntries, 1);
    expect(destinationCalories, 250);
    expect(sourceCalories, 0);
    expect(guard.isRunning, isFalse);
    guard.dispose();
  });

  test('a failed move releases the guard for a retry', () async {
    final guard = DiaryTransferGuard();
    await expectLater(
      guard.run(() async => throw StateError('write failed')),
      throwsStateError,
    );
    var retried = false;
    await guard.run(() async {
      retried = true;
    });
    expect(retried, isTrue);
    expect(guard.isRunning, isFalse);
    guard.dispose();
  });
}
