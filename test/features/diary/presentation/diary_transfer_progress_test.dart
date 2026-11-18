import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/features/diary/presentation/diary_transfer_progress.dart';

void main() {
  test('retry after a partial batch copy skips its committed destination',
      () async {
    final progress = DiaryTransferProgress();
    final destinations = <String>[];
    var failSecond = true;

    Future<void> transfer() async {
      await progress.copyOnce('day', 'food:one', 'one', () async {
        destinations.add('one');
      });
      await progress.copyOnce('day', 'food:two', 'two', () async {
        if (failSecond) throw StateError('storage failed');
        destinations.add('two');
      });
      await progress.finish('day', () async {});
    }

    await expectLater(transfer(), throwsStateError);
    failSecond = false;
    await transfer();
    expect(destinations, ['one', 'two']);
  });

  test('retry after deletion fails does not repeat the destination copy',
      () async {
    final progress = DiaryTransferProgress();
    var copies = 0;
    var deletes = 0;
    var failDelete = true;

    Future<void> move() async {
      await progress.copyOnce('move', 'food:one', 'one', () async {
        copies++;
      });
      await progress.finish('move', () async {
        if (failDelete) throw StateError('delete failed');
        deletes++;
      });
    }

    await expectLater(move(), throwsStateError);
    failDelete = false;
    await move();
    expect(copies, 1);
    expect(deletes, 1);
  });

  test('a changed source is not silently moved using the earlier copy',
      () async {
    final progress = DiaryTransferProgress();
    await progress.copyOnce('day', 'food:one', 'old', () async {});
    await expectLater(
      progress.copyOnce('day', 'food:one', 'edited', () async {}),
      throwsA(isA<DiaryTransferSourceChanged>()),
    );
  });

  test('source snapshots include sugar and sodium beyond entity equality', () {
    MealNutrimentsDBO nutrition(double sugar, double sodium) => MealNutrimentsDBO(
      energyKcal100: 100,
      carbohydrates100: 10,
      fat100: 2,
      proteins100: 3,
      sugars100: sugar,
      saturatedFat100: 1,
      fiber100: 1,
      sodium100: sodium,
    );
    final original = DiaryTransferProgress.snapshot(nutrition(2, 100));
    expect(DiaryTransferProgress.snapshot(nutrition(3, 100)), isNot(original));
    expect(DiaryTransferProgress.snapshot(nutrition(2, 200)), isNot(original));
  });

  test('a successful copy may be intentionally repeated', () async {
    final progress = DiaryTransferProgress();
    var copies = 0;
    for (var i = 0; i < 2; i++) {
      await progress.copyOnce('day', 'food:one', 'one', () async {
        copies++;
      });
      await progress.finish('day', () async {});
    }
    expect(copies, 2);
  });
}
