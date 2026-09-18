import 'package:get_storage/get_storage.dart';

/// Minimal persistence contract shared by every store so the stores can run
/// against real disk storage in production and an in-memory map in tests.
abstract class KeyValueStore {
  dynamic read(String key);
  Future<void> write(String key, dynamic value);
  void remove(String key);
  Iterable<String> getKeys();
}

class GetStorageKeyValueStore implements KeyValueStore {
  GetStorageKeyValueStore(this._storage);

  final GetStorage _storage;

  @override
  dynamic read(String key) => _storage.read(key);

  @override
  Future<void> write(String key, dynamic value) => _storage.write(key, value);

  @override
  void remove(String key) => _storage.remove(key);

  @override
  Iterable<String> getKeys() => _storage.getKeys();
}

/// In-memory fallback used before GetStorage is initialized (and in tests).
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, dynamic> _data = {};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  void remove(String key) {
    _data.remove(key);
  }

  @override
  Iterable<String> getKeys() => _data.keys;
}
