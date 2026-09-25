import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/storage/app_database.dart';
import 'package:freedium/core/storage/key_value_store.dart';

void main() {
  late AppDatabase database;
  late DriftKeyValueStore store;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = DriftKeyValueStore(database);
    await store.init();
  });

  tearDown(() async {
    await store.close();
  });

  test('starts empty', () {
    expect(store.read('missing'), isNull);
    expect(store.getKeys(), isEmpty);
  });

  test('writes and reads primitive and structured values', () async {
    await store.write('n', 42);
    await store.write('s', 'hello');
    await store.write('b', true);
    await store.write('map', {
      'a': 1,
      'list': [true, 'x', null],
    });
    expect(store.read('n'), 42);
    expect(store.read('s'), 'hello');
    expect(store.read('b'), isTrue);
    expect(store.read('map'), {
      'a': 1,
      'list': [true, 'x', null],
    });
    expect(store.getKeys().toSet(), {'n', 's', 'b', 'map'});
  });

  test('write overwrites the previous value in place', () async {
    await store.write('k', 'v1');
    await store.write('k', {'nested': true});
    expect(store.read('k'), {'nested': true});
    expect(store.getKeys(), ['k']);
  });

  test('a fresh store reloads persisted values from disk', () async {
    await store.write('prefs', {'theme': 'dark', 'font': 21});
    final reloaded = DriftKeyValueStore(database);
    await reloaded.init();
    expect(reloaded.read('prefs'), {'theme': 'dark', 'font': 21});
    await reloaded.close();
  });
}
