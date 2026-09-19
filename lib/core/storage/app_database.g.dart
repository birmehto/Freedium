// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KvRowsTable extends KvRows with TableInfo<$KvRowsTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonValueMeta = const VerificationMeta(
    'jsonValue',
  );
  @override
  late final GeneratedColumn<String> jsonValue = GeneratedColumn<String>(
    'json_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, jsonValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('json_value')) {
      context.handle(
        _jsonValueMeta,
        jsonValue.isAcceptableOrUnknown(data['json_value']!, _jsonValueMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      jsonValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_value'],
      )!,
    );
  }

  @override
  $KvRowsTable createAlias(String alias) {
    return $KvRowsTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String jsonValue;
  const KvRow({required this.key, required this.jsonValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['json_value'] = Variable<String>(jsonValue);
    return map;
  }

  KvRowsCompanion toCompanion(bool nullToAbsent) {
    return KvRowsCompanion(key: Value(key), jsonValue: Value(jsonValue));
  }

  factory KvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      jsonValue: serializer.fromJson<String>(json['jsonValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'jsonValue': serializer.toJson<String>(jsonValue),
    };
  }

  KvRow copyWith({String? key, String? jsonValue}) =>
      KvRow(key: key ?? this.key, jsonValue: jsonValue ?? this.jsonValue);
  KvRow copyWithCompanion(KvRowsCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      jsonValue: data.jsonValue.present ? data.jsonValue.value : this.jsonValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('jsonValue: $jsonValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, jsonValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow &&
          other.key == this.key &&
          other.jsonValue == this.jsonValue);
}

class KvRowsCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> jsonValue;
  final Value<int> rowid;
  const KvRowsCompanion({
    this.key = const Value.absent(),
    this.jsonValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvRowsCompanion.insert({
    required String key,
    required String jsonValue,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       jsonValue = Value(jsonValue);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? jsonValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (jsonValue != null) 'json_value': jsonValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? jsonValue,
    Value<int>? rowid,
  }) {
    return KvRowsCompanion(
      key: key ?? this.key,
      jsonValue: jsonValue ?? this.jsonValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (jsonValue.present) {
      map['json_value'] = Variable<String>(jsonValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvRowsCompanion(')
          ..write('key: $key, ')
          ..write('jsonValue: $jsonValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KvRowsTable kvRows = $KvRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [kvRows];
}

typedef $$KvRowsTableCreateCompanionBuilder = KvRowsCompanion Function({
  required String key,
  required String jsonValue,
  Value<int> rowid,
});
typedef $$KvRowsTableUpdateCompanionBuilder = KvRowsCompanion Function({
  Value<String> key,
  Value<String> jsonValue,
  Value<int> rowid,
});

class $$KvRowsTableFilterComposer
    extends Composer<_$AppDatabase, $KvRowsTable> {
  $$KvRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonValue => $composableBuilder(
    column: $table.jsonValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $KvRowsTable> {
  $$KvRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonValue => $composableBuilder(
    column: $table.jsonValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KvRowsTable> {
  $$KvRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get jsonValue =>
      $composableBuilder(column: $table.jsonValue, builder: (column) => column);
}

class $$KvRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KvRowsTable,
          KvRow,
          $$KvRowsTableFilterComposer,
          $$KvRowsTableOrderingComposer,
          $$KvRowsTableAnnotationComposer,
          $$KvRowsTableCreateCompanionBuilder,
          $$KvRowsTableUpdateCompanionBuilder,
          (KvRow, BaseReferences<_$AppDatabase, $KvRowsTable, KvRow>),
          KvRow,
          PrefetchHooks Function()
        > {
  $$KvRowsTableTableManager(_$AppDatabase db, $KvRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> jsonValue = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KvRowsCompanion(key: key, jsonValue: jsonValue, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String jsonValue,
                Value<int> rowid = const Value.absent(),
              }) => KvRowsCompanion.insert(
                key: key,
                jsonValue: jsonValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KvRowsTable, KvRow>(table),
                  BaseReferences<_$AppDatabase, $KvRowsTable, KvRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KvRowsTable,
      KvRow,
      $$KvRowsTableFilterComposer,
      $$KvRowsTableOrderingComposer,
      $$KvRowsTableAnnotationComposer,
      $$KvRowsTableCreateCompanionBuilder,
      $$KvRowsTableUpdateCompanionBuilder,
      (KvRow, BaseReferences<_$AppDatabase, $KvRowsTable, KvRow>),
      KvRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KvRowsTableTableManager get kvRows =>
      $$KvRowsTableTableManager(_db, _db.kvRows);
}
