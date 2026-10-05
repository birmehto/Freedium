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

class $CachedArticlesTable extends CachedArticles
    with TableInfo<$CachedArticlesTable, CachedArticle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 2048,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _htmlMeta = const VerificationMeta('html');
  @override
  late final GeneratedColumn<String> html = GeneratedColumn<String>(
    'html',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publicationMeta = const VerificationMeta(
    'publication',
  );
  @override
  late final GeneratedColumn<String> publication = GeneratedColumn<String>(
    'publication',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    url,
    html,
    title,
    author,
    publication,
    domain,
    wordCount,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedArticle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('html')) {
      context.handle(
        _htmlMeta,
        html.isAcceptableOrUnknown(data['html']!, _htmlMeta),
      );
    } else if (isInserting) {
      context.missing(_htmlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('publication')) {
      context.handle(
        _publicationMeta,
        publication.isAcceptableOrUnknown(
          data['publication']!,
          _publicationMeta,
        ),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  CachedArticle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedArticle(
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      html: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}html'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      publication: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication'],
      ),
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $CachedArticlesTable createAlias(String alias) {
    return $CachedArticlesTable(attachedDatabase, alias);
  }
}

class CachedArticle extends DataClass implements Insertable<CachedArticle> {
  /// Canonical URL of the article, from `ArticleUrl.canonicalize`.
  final String url;

  /// The article's own markup, cleaned of scripts and styles.
  final String html;

  /// Title, author and publication are denormalized onto the cache so a saved
  /// article can be listed without joining the metadata cache in memory.
  final String title;
  final String? author;
  final String? publication;
  final String? domain;
  final int wordCount;

  /// When this copy was written, which is also the eviction order.
  final DateTime savedAt;
  const CachedArticle({
    required this.url,
    required this.html,
    required this.title,
    this.author,
    this.publication,
    this.domain,
    required this.wordCount,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['html'] = Variable<String>(html);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || publication != null) {
      map['publication'] = Variable<String>(publication);
    }
    if (!nullToAbsent || domain != null) {
      map['domain'] = Variable<String>(domain);
    }
    map['word_count'] = Variable<int>(wordCount);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  CachedArticlesCompanion toCompanion(bool nullToAbsent) {
    return CachedArticlesCompanion(
      url: Value(url),
      html: Value(html),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      publication: publication == null && nullToAbsent
          ? const Value.absent()
          : Value(publication),
      domain: domain == null && nullToAbsent
          ? const Value.absent()
          : Value(domain),
      wordCount: Value(wordCount),
      savedAt: Value(savedAt),
    );
  }

  factory CachedArticle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedArticle(
      url: serializer.fromJson<String>(json['url']),
      html: serializer.fromJson<String>(json['html']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      publication: serializer.fromJson<String?>(json['publication']),
      domain: serializer.fromJson<String?>(json['domain']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'html': serializer.toJson<String>(html),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'publication': serializer.toJson<String?>(publication),
      'domain': serializer.toJson<String?>(domain),
      'wordCount': serializer.toJson<int>(wordCount),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  CachedArticle copyWith({
    String? url,
    String? html,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> publication = const Value.absent(),
    Value<String?> domain = const Value.absent(),
    int? wordCount,
    DateTime? savedAt,
  }) => CachedArticle(
    url: url ?? this.url,
    html: html ?? this.html,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    publication: publication.present ? publication.value : this.publication,
    domain: domain.present ? domain.value : this.domain,
    wordCount: wordCount ?? this.wordCount,
    savedAt: savedAt ?? this.savedAt,
  );
  CachedArticle copyWithCompanion(CachedArticlesCompanion data) {
    return CachedArticle(
      url: data.url.present ? data.url.value : this.url,
      html: data.html.present ? data.html.value : this.html,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      publication: data.publication.present
          ? data.publication.value
          : this.publication,
      domain: data.domain.present ? data.domain.value : this.domain,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedArticle(')
          ..write('url: $url, ')
          ..write('html: $html, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publication: $publication, ')
          ..write('domain: $domain, ')
          ..write('wordCount: $wordCount, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    url,
    html,
    title,
    author,
    publication,
    domain,
    wordCount,
    savedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedArticle &&
          other.url == this.url &&
          other.html == this.html &&
          other.title == this.title &&
          other.author == this.author &&
          other.publication == this.publication &&
          other.domain == this.domain &&
          other.wordCount == this.wordCount &&
          other.savedAt == this.savedAt);
}

class CachedArticlesCompanion extends UpdateCompanion<CachedArticle> {
  final Value<String> url;
  final Value<String> html;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> publication;
  final Value<String?> domain;
  final Value<int> wordCount;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const CachedArticlesCompanion({
    this.url = const Value.absent(),
    this.html = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.publication = const Value.absent(),
    this.domain = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedArticlesCompanion.insert({
    required String url,
    required String html,
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.publication = const Value.absent(),
    this.domain = const Value.absent(),
    this.wordCount = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       html = Value(html),
       savedAt = Value(savedAt);
  static Insertable<CachedArticle> custom({
    Expression<String>? url,
    Expression<String>? html,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? publication,
    Expression<String>? domain,
    Expression<int>? wordCount,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (html != null) 'html': html,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (publication != null) 'publication': publication,
      if (domain != null) 'domain': domain,
      if (wordCount != null) 'word_count': wordCount,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedArticlesCompanion copyWith({
    Value<String>? url,
    Value<String>? html,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? publication,
    Value<String?>? domain,
    Value<int>? wordCount,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return CachedArticlesCompanion(
      url: url ?? this.url,
      html: html ?? this.html,
      title: title ?? this.title,
      author: author ?? this.author,
      publication: publication ?? this.publication,
      domain: domain ?? this.domain,
      wordCount: wordCount ?? this.wordCount,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (html.present) {
      map['html'] = Variable<String>(html.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (publication.present) {
      map['publication'] = Variable<String>(publication.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedArticlesCompanion(')
          ..write('url: $url, ')
          ..write('html: $html, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publication: $publication, ')
          ..write('domain: $domain, ')
          ..write('wordCount: $wordCount, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KvRowsTable kvRows = $KvRowsTable(this);
  late final $CachedArticlesTable cachedArticles = $CachedArticlesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [kvRows, cachedArticles];
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
typedef $$CachedArticlesTableCreateCompanionBuilder =
    CachedArticlesCompanion Function({
      required String url,
      required String html,
      Value<String> title,
      Value<String?> author,
      Value<String?> publication,
      Value<String?> domain,
      Value<int> wordCount,
      required DateTime savedAt,
      Value<int> rowid,
    });
typedef $$CachedArticlesTableUpdateCompanionBuilder =
    CachedArticlesCompanion Function({
      Value<String> url,
      Value<String> html,
      Value<String> title,
      Value<String?> author,
      Value<String?> publication,
      Value<String?> domain,
      Value<int> wordCount,
      Value<DateTime> savedAt,
      Value<int> rowid,
    });

class $$CachedArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedArticlesTable> {
  $$CachedArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get html => $composableBuilder(
    column: $table.html,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publication => $composableBuilder(
    column: $table.publication,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedArticlesTable> {
  $$CachedArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get html => $composableBuilder(
    column: $table.html,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publication => $composableBuilder(
    column: $table.publication,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedArticlesTable> {
  $$CachedArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get html =>
      $composableBuilder(column: $table.html, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get publication => $composableBuilder(
    column: $table.publication,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$CachedArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedArticlesTable,
          CachedArticle,
          $$CachedArticlesTableFilterComposer,
          $$CachedArticlesTableOrderingComposer,
          $$CachedArticlesTableAnnotationComposer,
          $$CachedArticlesTableCreateCompanionBuilder,
          $$CachedArticlesTableUpdateCompanionBuilder,
          (
            CachedArticle,
            BaseReferences<_$AppDatabase, $CachedArticlesTable, CachedArticle>,
          ),
          CachedArticle,
          PrefetchHooks Function()
        > {
  $$CachedArticlesTableTableManager(
    _$AppDatabase db,
    $CachedArticlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<String> html = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> publication = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedArticlesCompanion(
                url: url,
                html: html,
                title: title,
                author: author,
                publication: publication,
                domain: domain,
                wordCount: wordCount,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String url,
                required String html,
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> publication = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedArticlesCompanion.insert(
                url: url,
                html: html,
                title: title,
                author: author,
                publication: publication,
                domain: domain,
                wordCount: wordCount,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedArticlesTable, CachedArticle>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedArticlesTable,
                    CachedArticle
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedArticlesTable,
      CachedArticle,
      $$CachedArticlesTableFilterComposer,
      $$CachedArticlesTableOrderingComposer,
      $$CachedArticlesTableAnnotationComposer,
      $$CachedArticlesTableCreateCompanionBuilder,
      $$CachedArticlesTableUpdateCompanionBuilder,
      (
        CachedArticle,
        BaseReferences<_$AppDatabase, $CachedArticlesTable, CachedArticle>,
      ),
      CachedArticle,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KvRowsTableTableManager get kvRows =>
      $$KvRowsTableTableManager(_db, _db.kvRows);
  $$CachedArticlesTableTableManager get cachedArticles =>
      $$CachedArticlesTableTableManager(_db, _db.cachedArticles);
}
