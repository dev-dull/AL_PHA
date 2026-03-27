// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BoardsTable extends Boards with TableInfo<$BoardsTable, BoardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<DateTime> weekStart = GeneratedColumn<DateTime>(
    'week_start',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    createdAt,
    updatedAt,
    archived,
    weekStart,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boards';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}week_start'],
      ),
    );
  }

  @override
  $BoardsTable createAlias(String alias) {
    return $BoardsTable(attachedDatabase, alias);
  }
}

class BoardRow extends DataClass implements Insertable<BoardRow> {
  final String id;
  final String name;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final DateTime? weekStart;
  const BoardRow({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    this.weekStart,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || weekStart != null) {
      map['week_start'] = Variable<DateTime>(weekStart);
    }
    return map;
  }

  BoardsCompanion toCompanion(bool nullToAbsent) {
    return BoardsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archived: Value(archived),
      weekStart: weekStart == null && nullToAbsent
          ? const Value.absent()
          : Value(weekStart),
    );
  }

  factory BoardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archived: serializer.fromJson<bool>(json['archived']),
      weekStart: serializer.fromJson<DateTime?>(json['weekStart']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archived': serializer.toJson<bool>(archived),
      'weekStart': serializer.toJson<DateTime?>(weekStart),
    };
  }

  BoardRow copyWith({
    String? id,
    String? name,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    Value<DateTime?> weekStart = const Value.absent(),
  }) => BoardRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archived: archived ?? this.archived,
    weekStart: weekStart.present ? weekStart.value : this.weekStart,
  );
  BoardRow copyWithCompanion(BoardsCompanion data) {
    return BoardRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archived: data.archived.present ? data.archived.value : this.archived,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived, ')
          ..write('weekStart: $weekStart')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, createdAt, updatedAt, archived, weekStart);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archived == this.archived &&
          other.weekStart == this.weekStart);
}

class BoardsCompanion extends UpdateCompanion<BoardRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> archived;
  final Value<DateTime?> weekStart;
  final Value<int> rowid;
  const BoardsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardsCompanion.insert({
    required String id,
    required String name,
    required String type,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archived = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BoardRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? archived,
    Expression<DateTime>? weekStart,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archived != null) 'archived': archived,
      if (weekStart != null) 'week_start': weekStart,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? archived,
    Value<DateTime?>? weekStart,
    Value<int>? rowid,
  }) {
    return BoardsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      weekStart: weekStart ?? this.weekStart,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<DateTime>(weekStart.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived, ')
          ..write('weekStart: $weekStart, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardColumnsTable extends BoardColumns
    with TableInfo<$BoardColumnsTable, BoardColumnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardColumnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('custom'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, boardId, label, position, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_columns';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardColumnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardColumnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardColumnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $BoardColumnsTable createAlias(String alias) {
    return $BoardColumnsTable(attachedDatabase, alias);
  }
}

class BoardColumnRow extends DataClass implements Insertable<BoardColumnRow> {
  final String id;
  final String boardId;
  final String label;
  final int position;
  final String type;
  const BoardColumnRow({
    required this.id,
    required this.boardId,
    required this.label,
    required this.position,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['board_id'] = Variable<String>(boardId);
    map['label'] = Variable<String>(label);
    map['position'] = Variable<int>(position);
    map['type'] = Variable<String>(type);
    return map;
  }

  BoardColumnsCompanion toCompanion(bool nullToAbsent) {
    return BoardColumnsCompanion(
      id: Value(id),
      boardId: Value(boardId),
      label: Value(label),
      position: Value(position),
      type: Value(type),
    );
  }

  factory BoardColumnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardColumnRow(
      id: serializer.fromJson<String>(json['id']),
      boardId: serializer.fromJson<String>(json['boardId']),
      label: serializer.fromJson<String>(json['label']),
      position: serializer.fromJson<int>(json['position']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boardId': serializer.toJson<String>(boardId),
      'label': serializer.toJson<String>(label),
      'position': serializer.toJson<int>(position),
      'type': serializer.toJson<String>(type),
    };
  }

  BoardColumnRow copyWith({
    String? id,
    String? boardId,
    String? label,
    int? position,
    String? type,
  }) => BoardColumnRow(
    id: id ?? this.id,
    boardId: boardId ?? this.boardId,
    label: label ?? this.label,
    position: position ?? this.position,
    type: type ?? this.type,
  );
  BoardColumnRow copyWithCompanion(BoardColumnsCompanion data) {
    return BoardColumnRow(
      id: data.id.present ? data.id.value : this.id,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      label: data.label.present ? data.label.value : this.label,
      position: data.position.present ? data.position.value : this.position,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardColumnRow(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('label: $label, ')
          ..write('position: $position, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, boardId, label, position, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardColumnRow &&
          other.id == this.id &&
          other.boardId == this.boardId &&
          other.label == this.label &&
          other.position == this.position &&
          other.type == this.type);
}

class BoardColumnsCompanion extends UpdateCompanion<BoardColumnRow> {
  final Value<String> id;
  final Value<String> boardId;
  final Value<String> label;
  final Value<int> position;
  final Value<String> type;
  final Value<int> rowid;
  const BoardColumnsCompanion({
    this.id = const Value.absent(),
    this.boardId = const Value.absent(),
    this.label = const Value.absent(),
    this.position = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardColumnsCompanion.insert({
    required String id,
    required String boardId,
    required String label,
    required int position,
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boardId = Value(boardId),
       label = Value(label),
       position = Value(position);
  static Insertable<BoardColumnRow> custom({
    Expression<String>? id,
    Expression<String>? boardId,
    Expression<String>? label,
    Expression<int>? position,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boardId != null) 'board_id': boardId,
      if (label != null) 'label': label,
      if (position != null) 'position': position,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardColumnsCompanion copyWith({
    Value<String>? id,
    Value<String>? boardId,
    Value<String>? label,
    Value<int>? position,
    Value<String>? type,
    Value<int>? rowid,
  }) {
    return BoardColumnsCompanion(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      label: label ?? this.label,
      position: position ?? this.position,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardColumnsCompanion(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('label: $label, ')
          ..write('position: $position, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _migratedFromBoardIdMeta =
      const VerificationMeta('migratedFromBoardId');
  @override
  late final GeneratedColumn<String> migratedFromBoardId =
      GeneratedColumn<String>(
        'migrated_from_board_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _migratedFromTaskIdMeta =
      const VerificationMeta('migratedFromTaskId');
  @override
  late final GeneratedColumn<String> migratedFromTaskId =
      GeneratedColumn<String>(
        'migrated_from_task_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isEventMeta = const VerificationMeta(
    'isEvent',
  );
  @override
  late final GeneratedColumn<bool> isEvent = GeneratedColumn<bool>(
    'is_event',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_event" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _scheduledTimeMeta = const VerificationMeta(
    'scheduledTime',
  );
  @override
  late final GeneratedColumn<String> scheduledTime = GeneratedColumn<String>(
    'scheduled_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boardId,
    title,
    description,
    state,
    priority,
    position,
    createdAt,
    completedAt,
    deadline,
    migratedFromBoardId,
    migratedFromTaskId,
    isEvent,
    scheduledTime,
    recurrenceRule,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('migrated_from_board_id')) {
      context.handle(
        _migratedFromBoardIdMeta,
        migratedFromBoardId.isAcceptableOrUnknown(
          data['migrated_from_board_id']!,
          _migratedFromBoardIdMeta,
        ),
      );
    }
    if (data.containsKey('migrated_from_task_id')) {
      context.handle(
        _migratedFromTaskIdMeta,
        migratedFromTaskId.isAcceptableOrUnknown(
          data['migrated_from_task_id']!,
          _migratedFromTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('is_event')) {
      context.handle(
        _isEventMeta,
        isEvent.isAcceptableOrUnknown(data['is_event']!, _isEventMeta),
      );
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
        _scheduledTimeMeta,
        scheduledTime.isAcceptableOrUnknown(
          data['scheduled_time']!,
          _scheduledTimeMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      migratedFromBoardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migrated_from_board_id'],
      ),
      migratedFromTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migrated_from_task_id'],
      ),
      isEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_event'],
      )!,
      scheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_time'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final String boardId;
  final String title;
  final String description;
  final String state;
  final int priority;
  final int position;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deadline;
  final String? migratedFromBoardId;
  final String? migratedFromTaskId;
  final bool isEvent;
  final String? scheduledTime;
  final String? recurrenceRule;
  const TaskRow({
    required this.id,
    required this.boardId,
    required this.title,
    required this.description,
    required this.state,
    required this.priority,
    required this.position,
    required this.createdAt,
    this.completedAt,
    this.deadline,
    this.migratedFromBoardId,
    this.migratedFromTaskId,
    required this.isEvent,
    this.scheduledTime,
    this.recurrenceRule,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['board_id'] = Variable<String>(boardId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['state'] = Variable<String>(state);
    map['priority'] = Variable<int>(priority);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    if (!nullToAbsent || migratedFromBoardId != null) {
      map['migrated_from_board_id'] = Variable<String>(migratedFromBoardId);
    }
    if (!nullToAbsent || migratedFromTaskId != null) {
      map['migrated_from_task_id'] = Variable<String>(migratedFromTaskId);
    }
    map['is_event'] = Variable<bool>(isEvent);
    if (!nullToAbsent || scheduledTime != null) {
      map['scheduled_time'] = Variable<String>(scheduledTime);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      boardId: Value(boardId),
      title: Value(title),
      description: Value(description),
      state: Value(state),
      priority: Value(priority),
      position: Value(position),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      migratedFromBoardId: migratedFromBoardId == null && nullToAbsent
          ? const Value.absent()
          : Value(migratedFromBoardId),
      migratedFromTaskId: migratedFromTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(migratedFromTaskId),
      isEvent: Value(isEvent),
      scheduledTime: scheduledTime == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledTime),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      boardId: serializer.fromJson<String>(json['boardId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      state: serializer.fromJson<String>(json['state']),
      priority: serializer.fromJson<int>(json['priority']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      migratedFromBoardId: serializer.fromJson<String?>(
        json['migratedFromBoardId'],
      ),
      migratedFromTaskId: serializer.fromJson<String?>(
        json['migratedFromTaskId'],
      ),
      isEvent: serializer.fromJson<bool>(json['isEvent']),
      scheduledTime: serializer.fromJson<String?>(json['scheduledTime']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boardId': serializer.toJson<String>(boardId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'state': serializer.toJson<String>(state),
      'priority': serializer.toJson<int>(priority),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'migratedFromBoardId': serializer.toJson<String?>(migratedFromBoardId),
      'migratedFromTaskId': serializer.toJson<String?>(migratedFromTaskId),
      'isEvent': serializer.toJson<bool>(isEvent),
      'scheduledTime': serializer.toJson<String?>(scheduledTime),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
    };
  }

  TaskRow copyWith({
    String? id,
    String? boardId,
    String? title,
    String? description,
    String? state,
    int? priority,
    int? position,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> deadline = const Value.absent(),
    Value<String?> migratedFromBoardId = const Value.absent(),
    Value<String?> migratedFromTaskId = const Value.absent(),
    bool? isEvent,
    Value<String?> scheduledTime = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    boardId: boardId ?? this.boardId,
    title: title ?? this.title,
    description: description ?? this.description,
    state: state ?? this.state,
    priority: priority ?? this.priority,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    deadline: deadline.present ? deadline.value : this.deadline,
    migratedFromBoardId: migratedFromBoardId.present
        ? migratedFromBoardId.value
        : this.migratedFromBoardId,
    migratedFromTaskId: migratedFromTaskId.present
        ? migratedFromTaskId.value
        : this.migratedFromTaskId,
    isEvent: isEvent ?? this.isEvent,
    scheduledTime: scheduledTime.present
        ? scheduledTime.value
        : this.scheduledTime,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      state: data.state.present ? data.state.value : this.state,
      priority: data.priority.present ? data.priority.value : this.priority,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      migratedFromBoardId: data.migratedFromBoardId.present
          ? data.migratedFromBoardId.value
          : this.migratedFromBoardId,
      migratedFromTaskId: data.migratedFromTaskId.present
          ? data.migratedFromTaskId.value
          : this.migratedFromTaskId,
      isEvent: data.isEvent.present ? data.isEvent.value : this.isEvent,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('state: $state, ')
          ..write('priority: $priority, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deadline: $deadline, ')
          ..write('migratedFromBoardId: $migratedFromBoardId, ')
          ..write('migratedFromTaskId: $migratedFromTaskId, ')
          ..write('isEvent: $isEvent, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('recurrenceRule: $recurrenceRule')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    boardId,
    title,
    description,
    state,
    priority,
    position,
    createdAt,
    completedAt,
    deadline,
    migratedFromBoardId,
    migratedFromTaskId,
    isEvent,
    scheduledTime,
    recurrenceRule,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.boardId == this.boardId &&
          other.title == this.title &&
          other.description == this.description &&
          other.state == this.state &&
          other.priority == this.priority &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.deadline == this.deadline &&
          other.migratedFromBoardId == this.migratedFromBoardId &&
          other.migratedFromTaskId == this.migratedFromTaskId &&
          other.isEvent == this.isEvent &&
          other.scheduledTime == this.scheduledTime &&
          other.recurrenceRule == this.recurrenceRule);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<String> boardId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> state;
  final Value<int> priority;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> deadline;
  final Value<String?> migratedFromBoardId;
  final Value<String?> migratedFromTaskId;
  final Value<bool> isEvent;
  final Value<String?> scheduledTime;
  final Value<String?> recurrenceRule;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.boardId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.state = const Value.absent(),
    this.priority = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deadline = const Value.absent(),
    this.migratedFromBoardId = const Value.absent(),
    this.migratedFromTaskId = const Value.absent(),
    this.isEvent = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String boardId,
    required String title,
    this.description = const Value.absent(),
    this.state = const Value.absent(),
    this.priority = const Value.absent(),
    required int position,
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.deadline = const Value.absent(),
    this.migratedFromBoardId = const Value.absent(),
    this.migratedFromTaskId = const Value.absent(),
    this.isEvent = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boardId = Value(boardId),
       title = Value(title),
       position = Value(position),
       createdAt = Value(createdAt);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<String>? boardId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? state,
    Expression<int>? priority,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? deadline,
    Expression<String>? migratedFromBoardId,
    Expression<String>? migratedFromTaskId,
    Expression<bool>? isEvent,
    Expression<String>? scheduledTime,
    Expression<String>? recurrenceRule,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boardId != null) 'board_id': boardId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (state != null) 'state': state,
      if (priority != null) 'priority': priority,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (deadline != null) 'deadline': deadline,
      if (migratedFromBoardId != null)
        'migrated_from_board_id': migratedFromBoardId,
      if (migratedFromTaskId != null)
        'migrated_from_task_id': migratedFromTaskId,
      if (isEvent != null) 'is_event': isEvent,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? boardId,
    Value<String>? title,
    Value<String>? description,
    Value<String>? state,
    Value<int>? priority,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? deadline,
    Value<String?>? migratedFromBoardId,
    Value<String?>? migratedFromTaskId,
    Value<bool>? isEvent,
    Value<String?>? scheduledTime,
    Value<String?>? recurrenceRule,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      description: description ?? this.description,
      state: state ?? this.state,
      priority: priority ?? this.priority,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
      migratedFromBoardId: migratedFromBoardId ?? this.migratedFromBoardId,
      migratedFromTaskId: migratedFromTaskId ?? this.migratedFromTaskId,
      isEvent: isEvent ?? this.isEvent,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (migratedFromBoardId.present) {
      map['migrated_from_board_id'] = Variable<String>(
        migratedFromBoardId.value,
      );
    }
    if (migratedFromTaskId.present) {
      map['migrated_from_task_id'] = Variable<String>(migratedFromTaskId.value);
    }
    if (isEvent.present) {
      map['is_event'] = Variable<bool>(isEvent.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<String>(scheduledTime.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('state: $state, ')
          ..write('priority: $priority, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deadline: $deadline, ')
          ..write('migratedFromBoardId: $migratedFromBoardId, ')
          ..write('migratedFromTaskId: $migratedFromTaskId, ')
          ..write('isEvent: $isEvent, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MarkersTable extends Markers with TableInfo<$MarkersTable, MarkerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _columnIdMeta = const VerificationMeta(
    'columnId',
  );
  @override
  late final GeneratedColumn<String> columnId = GeneratedColumn<String>(
    'column_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES board_columns (id)',
    ),
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id)',
    ),
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    columnId,
    boardId,
    symbol,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'markers';
  @override
  VerificationContext validateIntegrity(
    Insertable<MarkerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('column_id')) {
      context.handle(
        _columnIdMeta,
        columnId.isAcceptableOrUnknown(data['column_id']!, _columnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_columnIdMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {taskId, columnId},
  ];
  @override
  MarkerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MarkerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      columnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}column_id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MarkersTable createAlias(String alias) {
    return $MarkersTable(attachedDatabase, alias);
  }
}

class MarkerRow extends DataClass implements Insertable<MarkerRow> {
  final String id;
  final String taskId;
  final String columnId;
  final String boardId;
  final String symbol;
  final DateTime updatedAt;
  const MarkerRow({
    required this.id,
    required this.taskId,
    required this.columnId,
    required this.boardId,
    required this.symbol,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['column_id'] = Variable<String>(columnId);
    map['board_id'] = Variable<String>(boardId);
    map['symbol'] = Variable<String>(symbol);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MarkersCompanion toCompanion(bool nullToAbsent) {
    return MarkersCompanion(
      id: Value(id),
      taskId: Value(taskId),
      columnId: Value(columnId),
      boardId: Value(boardId),
      symbol: Value(symbol),
      updatedAt: Value(updatedAt),
    );
  }

  factory MarkerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MarkerRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      columnId: serializer.fromJson<String>(json['columnId']),
      boardId: serializer.fromJson<String>(json['boardId']),
      symbol: serializer.fromJson<String>(json['symbol']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'columnId': serializer.toJson<String>(columnId),
      'boardId': serializer.toJson<String>(boardId),
      'symbol': serializer.toJson<String>(symbol),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MarkerRow copyWith({
    String? id,
    String? taskId,
    String? columnId,
    String? boardId,
    String? symbol,
    DateTime? updatedAt,
  }) => MarkerRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    columnId: columnId ?? this.columnId,
    boardId: boardId ?? this.boardId,
    symbol: symbol ?? this.symbol,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MarkerRow copyWithCompanion(MarkersCompanion data) {
    return MarkerRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      columnId: data.columnId.present ? data.columnId.value : this.columnId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MarkerRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('columnId: $columnId, ')
          ..write('boardId: $boardId, ')
          ..write('symbol: $symbol, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, columnId, boardId, symbol, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MarkerRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.columnId == this.columnId &&
          other.boardId == this.boardId &&
          other.symbol == this.symbol &&
          other.updatedAt == this.updatedAt);
}

class MarkersCompanion extends UpdateCompanion<MarkerRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> columnId;
  final Value<String> boardId;
  final Value<String> symbol;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MarkersCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.columnId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.symbol = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MarkersCompanion.insert({
    required String id,
    required String taskId,
    required String columnId,
    required String boardId,
    required String symbol,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       columnId = Value(columnId),
       boardId = Value(boardId),
       symbol = Value(symbol),
       updatedAt = Value(updatedAt);
  static Insertable<MarkerRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? columnId,
    Expression<String>? boardId,
    Expression<String>? symbol,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (columnId != null) 'column_id': columnId,
      if (boardId != null) 'board_id': boardId,
      if (symbol != null) 'symbol': symbol,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MarkersCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? columnId,
    Value<String>? boardId,
    Value<String>? symbol,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MarkersCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      columnId: columnId ?? this.columnId,
      boardId: boardId ?? this.boardId,
      symbol: symbol ?? this.symbol,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (columnId.present) {
      map['column_id'] = Variable<String>(columnId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarkersCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('columnId: $columnId, ')
          ..write('boardId: $boardId, ')
          ..write('symbol: $symbol, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskNotesTable extends TaskNotes
    with TableInfo<$TaskNotesTable, TaskNoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    content,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskNoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskNoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskNoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TaskNotesTable createAlias(String alias) {
    return $TaskNotesTable(attachedDatabase, alias);
  }
}

class TaskNoteRow extends DataClass implements Insertable<TaskNoteRow> {
  final String id;
  final String taskId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TaskNoteRow({
    required this.id,
    required this.taskId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TaskNotesCompanion toCompanion(bool nullToAbsent) {
    return TaskNotesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaskNoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskNoteRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TaskNoteRow copyWith({
    String? id,
    String? taskId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TaskNoteRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaskNoteRow copyWithCompanion(TaskNotesCompanion data) {
    return TaskNoteRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskNoteRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskNoteRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TaskNotesCompanion extends UpdateCompanion<TaskNoteRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TaskNotesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskNotesCompanion.insert({
    required String id,
    required String taskId,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskNoteRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TaskNotesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskNotesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, position, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final String id;
  final String name;
  final int color;
  final int position;
  final DateTime createdAt;
  const TagRow({
    required this.id,
    required this.name,
    required this.color,
    required this.position,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      position: Value(position),
      createdAt: Value(createdAt),
    );
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TagRow copyWith({
    String? id,
    String? name,
    int? color,
    int? position,
    DateTime? createdAt,
  }) => TagRow(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, position, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.position == this.position &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required int color,
    required int position,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color),
       position = Value(position),
       createdAt = Value(createdAt);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? color,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTagsTable extends TaskTags
    with TableInfo<$TaskTagsTable, TaskTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, tagId, slot];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, tagId};
  @override
  TaskTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTagRow(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
    );
  }

  @override
  $TaskTagsTable createAlias(String alias) {
    return $TaskTagsTable(attachedDatabase, alias);
  }
}

class TaskTagRow extends DataClass implements Insertable<TaskTagRow> {
  final String taskId;
  final String tagId;
  final int slot;
  const TaskTagRow({
    required this.taskId,
    required this.tagId,
    required this.slot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['tag_id'] = Variable<String>(tagId);
    map['slot'] = Variable<int>(slot);
    return map;
  }

  TaskTagsCompanion toCompanion(bool nullToAbsent) {
    return TaskTagsCompanion(
      taskId: Value(taskId),
      tagId: Value(tagId),
      slot: Value(slot),
    );
  }

  factory TaskTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTagRow(
      taskId: serializer.fromJson<String>(json['taskId']),
      tagId: serializer.fromJson<String>(json['tagId']),
      slot: serializer.fromJson<int>(json['slot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'tagId': serializer.toJson<String>(tagId),
      'slot': serializer.toJson<int>(slot),
    };
  }

  TaskTagRow copyWith({String? taskId, String? tagId, int? slot}) => TaskTagRow(
    taskId: taskId ?? this.taskId,
    tagId: tagId ?? this.tagId,
    slot: slot ?? this.slot,
  );
  TaskTagRow copyWithCompanion(TaskTagsCompanion data) {
    return TaskTagRow(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      slot: data.slot.present ? data.slot.value : this.slot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTagRow(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('slot: $slot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, tagId, slot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTagRow &&
          other.taskId == this.taskId &&
          other.tagId == this.tagId &&
          other.slot == this.slot);
}

class TaskTagsCompanion extends UpdateCompanion<TaskTagRow> {
  final Value<String> taskId;
  final Value<String> tagId;
  final Value<int> slot;
  final Value<int> rowid;
  const TaskTagsCompanion({
    this.taskId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.slot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTagsCompanion.insert({
    required String taskId,
    required String tagId,
    required int slot,
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       tagId = Value(tagId),
       slot = Value(slot);
  static Insertable<TaskTagRow> custom({
    Expression<String>? taskId,
    Expression<String>? tagId,
    Expression<int>? slot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (tagId != null) 'tag_id': tagId,
      if (slot != null) 'slot': slot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTagsCompanion copyWith({
    Value<String>? taskId,
    Value<String>? tagId,
    Value<int>? slot,
    Value<int>? rowid,
  }) {
    return TaskTagsCompanion(
      taskId: taskId ?? this.taskId,
      tagId: tagId ?? this.tagId,
      slot: slot ?? this.slot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTagsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('slot: $slot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AlphaDatabase extends GeneratedDatabase {
  _$AlphaDatabase(QueryExecutor e) : super(e);
  $AlphaDatabaseManager get managers => $AlphaDatabaseManager(this);
  late final $BoardsTable boards = $BoardsTable(this);
  late final $BoardColumnsTable boardColumns = $BoardColumnsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $MarkersTable markers = $MarkersTable(this);
  late final $TaskNotesTable taskNotes = $TaskNotesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TaskTagsTable taskTags = $TaskTagsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    boards,
    boardColumns,
    tasks,
    markers,
    taskNotes,
    tags,
    taskTags,
  ];
}

typedef $$BoardsTableCreateCompanionBuilder =
    BoardsCompanion Function({
      required String id,
      required String name,
      required String type,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> archived,
      Value<DateTime?> weekStart,
      Value<int> rowid,
    });
typedef $$BoardsTableUpdateCompanionBuilder =
    BoardsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> archived,
      Value<DateTime?> weekStart,
      Value<int> rowid,
    });

final class $$BoardsTableReferences
    extends BaseReferences<_$AlphaDatabase, $BoardsTable, BoardRow> {
  $$BoardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BoardColumnsTable, List<BoardColumnRow>>
  _boardColumnsRefsTable(_$AlphaDatabase db) => MultiTypedResultKey.fromTable(
    db.boardColumns,
    aliasName: $_aliasNameGenerator(db.boards.id, db.boardColumns.boardId),
  );

  $$BoardColumnsTableProcessedTableManager get boardColumnsRefs {
    final manager = $$BoardColumnsTableTableManager(
      $_db,
      $_db.boardColumns,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_boardColumnsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<TaskRow>> _tasksRefsTable(
    _$AlphaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: $_aliasNameGenerator(db.boards.id, db.tasks.boardId),
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MarkersTable, List<MarkerRow>> _markersRefsTable(
    _$AlphaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.markers,
    aliasName: $_aliasNameGenerator(db.boards.id, db.markers.boardId),
  );

  $$MarkersTableProcessedTableManager get markersRefs {
    final manager = $$MarkersTableTableManager(
      $_db,
      $_db.markers,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_markersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoardsTableFilterComposer
    extends Composer<_$AlphaDatabase, $BoardsTable> {
  $$BoardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> boardColumnsRefs(
    Expression<bool> Function($$BoardColumnsTableFilterComposer f) f,
  ) {
    final $$BoardColumnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableFilterComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> markersRefs(
    Expression<bool> Function($$MarkersTableFilterComposer f) f,
  ) {
    final $$MarkersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.markers,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarkersTableFilterComposer(
            $db: $db,
            $table: $db.markers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardsTableOrderingComposer
    extends Composer<_$AlphaDatabase, $BoardsTable> {
  $$BoardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardsTableAnnotationComposer
    extends Composer<_$AlphaDatabase, $BoardsTable> {
  $$BoardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  Expression<T> boardColumnsRefs<T extends Object>(
    Expression<T> Function($$BoardColumnsTableAnnotationComposer a) f,
  ) {
    final $$BoardColumnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> markersRefs<T extends Object>(
    Expression<T> Function($$MarkersTableAnnotationComposer a) f,
  ) {
    final $$MarkersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.markers,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarkersTableAnnotationComposer(
            $db: $db,
            $table: $db.markers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardsTableTableManager
    extends
        RootTableManager<
          _$AlphaDatabase,
          $BoardsTable,
          BoardRow,
          $$BoardsTableFilterComposer,
          $$BoardsTableOrderingComposer,
          $$BoardsTableAnnotationComposer,
          $$BoardsTableCreateCompanionBuilder,
          $$BoardsTableUpdateCompanionBuilder,
          (BoardRow, $$BoardsTableReferences),
          BoardRow,
          PrefetchHooks Function({
            bool boardColumnsRefs,
            bool tasksRefs,
            bool markersRefs,
          })
        > {
  $$BoardsTableTableManager(_$AlphaDatabase db, $BoardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime?> weekStart = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardsCompanion(
                id: id,
                name: name,
                type: type,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archived: archived,
                weekStart: weekStart,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> archived = const Value.absent(),
                Value<DateTime?> weekStart = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardsCompanion.insert(
                id: id,
                name: name,
                type: type,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archived: archived,
                weekStart: weekStart,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BoardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                boardColumnsRefs = false,
                tasksRefs = false,
                markersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (boardColumnsRefs) db.boardColumns,
                    if (tasksRefs) db.tasks,
                    if (markersRefs) db.markers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (boardColumnsRefs)
                        await $_getPrefetchedData<
                          BoardRow,
                          $BoardsTable,
                          BoardColumnRow
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._boardColumnsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(
                                db,
                                table,
                                p0,
                              ).boardColumnsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tasksRefs)
                        await $_getPrefetchedData<
                          BoardRow,
                          $BoardsTable,
                          TaskRow
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(db, table, p0).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (markersRefs)
                        await $_getPrefetchedData<
                          BoardRow,
                          $BoardsTable,
                          MarkerRow
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._markersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(
                                db,
                                table,
                                p0,
                              ).markersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BoardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AlphaDatabase,
      $BoardsTable,
      BoardRow,
      $$BoardsTableFilterComposer,
      $$BoardsTableOrderingComposer,
      $$BoardsTableAnnotationComposer,
      $$BoardsTableCreateCompanionBuilder,
      $$BoardsTableUpdateCompanionBuilder,
      (BoardRow, $$BoardsTableReferences),
      BoardRow,
      PrefetchHooks Function({
        bool boardColumnsRefs,
        bool tasksRefs,
        bool markersRefs,
      })
    >;
typedef $$BoardColumnsTableCreateCompanionBuilder =
    BoardColumnsCompanion Function({
      required String id,
      required String boardId,
      required String label,
      required int position,
      Value<String> type,
      Value<int> rowid,
    });
typedef $$BoardColumnsTableUpdateCompanionBuilder =
    BoardColumnsCompanion Function({
      Value<String> id,
      Value<String> boardId,
      Value<String> label,
      Value<int> position,
      Value<String> type,
      Value<int> rowid,
    });

final class $$BoardColumnsTableReferences
    extends
        BaseReferences<_$AlphaDatabase, $BoardColumnsTable, BoardColumnRow> {
  $$BoardColumnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$AlphaDatabase db) => db.boards
      .createAlias($_aliasNameGenerator(db.boardColumns.boardId, db.boards.id));

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MarkersTable, List<MarkerRow>> _markersRefsTable(
    _$AlphaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.markers,
    aliasName: $_aliasNameGenerator(db.boardColumns.id, db.markers.columnId),
  );

  $$MarkersTableProcessedTableManager get markersRefs {
    final manager = $$MarkersTableTableManager(
      $_db,
      $_db.markers,
    ).filter((f) => f.columnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_markersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoardColumnsTableFilterComposer
    extends Composer<_$AlphaDatabase, $BoardColumnsTable> {
  $$BoardColumnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> markersRefs(
    Expression<bool> Function($$MarkersTableFilterComposer f) f,
  ) {
    final $$MarkersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.markers,
      getReferencedColumn: (t) => t.columnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarkersTableFilterComposer(
            $db: $db,
            $table: $db.markers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardColumnsTableOrderingComposer
    extends Composer<_$AlphaDatabase, $BoardColumnsTable> {
  $$BoardColumnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BoardColumnsTableAnnotationComposer
    extends Composer<_$AlphaDatabase, $BoardColumnsTable> {
  $$BoardColumnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> markersRefs<T extends Object>(
    Expression<T> Function($$MarkersTableAnnotationComposer a) f,
  ) {
    final $$MarkersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.markers,
      getReferencedColumn: (t) => t.columnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarkersTableAnnotationComposer(
            $db: $db,
            $table: $db.markers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardColumnsTableTableManager
    extends
        RootTableManager<
          _$AlphaDatabase,
          $BoardColumnsTable,
          BoardColumnRow,
          $$BoardColumnsTableFilterComposer,
          $$BoardColumnsTableOrderingComposer,
          $$BoardColumnsTableAnnotationComposer,
          $$BoardColumnsTableCreateCompanionBuilder,
          $$BoardColumnsTableUpdateCompanionBuilder,
          (BoardColumnRow, $$BoardColumnsTableReferences),
          BoardColumnRow,
          PrefetchHooks Function({bool boardId, bool markersRefs})
        > {
  $$BoardColumnsTableTableManager(_$AlphaDatabase db, $BoardColumnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardColumnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardColumnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardColumnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardColumnsCompanion(
                id: id,
                boardId: boardId,
                label: label,
                position: position,
                type: type,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boardId,
                required String label,
                required int position,
                Value<String> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardColumnsCompanion.insert(
                id: id,
                boardId: boardId,
                label: label,
                position: position,
                type: type,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BoardColumnsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boardId = false, markersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (markersRefs) db.markers],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boardId,
                                referencedTable: $$BoardColumnsTableReferences
                                    ._boardIdTable(db),
                                referencedColumn: $$BoardColumnsTableReferences
                                    ._boardIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (markersRefs)
                    await $_getPrefetchedData<
                      BoardColumnRow,
                      $BoardColumnsTable,
                      MarkerRow
                    >(
                      currentTable: table,
                      referencedTable: $$BoardColumnsTableReferences
                          ._markersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BoardColumnsTableReferences(
                            db,
                            table,
                            p0,
                          ).markersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.columnId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BoardColumnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AlphaDatabase,
      $BoardColumnsTable,
      BoardColumnRow,
      $$BoardColumnsTableFilterComposer,
      $$BoardColumnsTableOrderingComposer,
      $$BoardColumnsTableAnnotationComposer,
      $$BoardColumnsTableCreateCompanionBuilder,
      $$BoardColumnsTableUpdateCompanionBuilder,
      (BoardColumnRow, $$BoardColumnsTableReferences),
      BoardColumnRow,
      PrefetchHooks Function({bool boardId, bool markersRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String boardId,
      required String title,
      Value<String> description,
      Value<String> state,
      Value<int> priority,
      required int position,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> deadline,
      Value<String?> migratedFromBoardId,
      Value<String?> migratedFromTaskId,
      Value<bool> isEvent,
      Value<String?> scheduledTime,
      Value<String?> recurrenceRule,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> boardId,
      Value<String> title,
      Value<String> description,
      Value<String> state,
      Value<int> priority,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> deadline,
      Value<String?> migratedFromBoardId,
      Value<String?> migratedFromTaskId,
      Value<bool> isEvent,
      Value<String?> scheduledTime,
      Value<String?> recurrenceRule,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AlphaDatabase, $TasksTable, TaskRow> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$AlphaDatabase db) => db.boards
      .createAlias($_aliasNameGenerator(db.tasks.boardId, db.boards.id));

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MarkersTable, List<MarkerRow>> _markersRefsTable(
    _$AlphaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.markers,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.markers.taskId),
  );

  $$MarkersTableProcessedTableManager get markersRefs {
    final manager = $$MarkersTableTableManager(
      $_db,
      $_db.markers,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_markersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskNotesTable, List<TaskNoteRow>>
  _taskNotesRefsTable(_$AlphaDatabase db) => MultiTypedResultKey.fromTable(
    db.taskNotes,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskNotes.taskId),
  );

  $$TaskNotesTableProcessedTableManager get taskNotesRefs {
    final manager = $$TaskNotesTableTableManager(
      $_db,
      $_db.taskNotes,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskTagsTable, List<TaskTagRow>>
  _taskTagsRefsTable(_$AlphaDatabase db) => MultiTypedResultKey.fromTable(
    db.taskTags,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskTags.taskId),
  );

  $$TaskTagsTableProcessedTableManager get taskTagsRefs {
    final manager = $$TaskTagsTableTableManager(
      $_db,
      $_db.taskTags,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer
    extends Composer<_$AlphaDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get migratedFromBoardId => $composableBuilder(
    column: $table.migratedFromBoardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get migratedFromTaskId => $composableBuilder(
    column: $table.migratedFromTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEvent => $composableBuilder(
    column: $table.isEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> markersRefs(
    Expression<bool> Function($$MarkersTableFilterComposer f) f,
  ) {
    final $$MarkersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.markers,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarkersTableFilterComposer(
            $db: $db,
            $table: $db.markers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskNotesRefs(
    Expression<bool> Function($$TaskNotesTableFilterComposer f) f,
  ) {
    final $$TaskNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskNotes,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskNotesTableFilterComposer(
            $db: $db,
            $table: $db.taskNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskTagsRefs(
    Expression<bool> Function($$TaskTagsTableFilterComposer f) f,
  ) {
    final $$TaskTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableFilterComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AlphaDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get migratedFromBoardId => $composableBuilder(
    column: $table.migratedFromBoardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get migratedFromTaskId => $composableBuilder(
    column: $table.migratedFromTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEvent => $composableBuilder(
    column: $table.isEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AlphaDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get migratedFromBoardId => $composableBuilder(
    column: $table.migratedFromBoardId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get migratedFromTaskId => $composableBuilder(
    column: $table.migratedFromTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEvent =>
      $composableBuilder(column: $table.isEvent, builder: (column) => column);

  GeneratedColumn<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> markersRefs<T extends Object>(
    Expression<T> Function($$MarkersTableAnnotationComposer a) f,
  ) {
    final $$MarkersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.markers,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarkersTableAnnotationComposer(
            $db: $db,
            $table: $db.markers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskNotesRefs<T extends Object>(
    Expression<T> Function($$TaskNotesTableAnnotationComposer a) f,
  ) {
    final $$TaskNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskNotes,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskTagsRefs<T extends Object>(
    Expression<T> Function($$TaskTagsTableAnnotationComposer a) f,
  ) {
    final $$TaskTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AlphaDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, $$TasksTableReferences),
          TaskRow,
          PrefetchHooks Function({
            bool boardId,
            bool markersRefs,
            bool taskNotesRefs,
            bool taskTagsRefs,
          })
        > {
  $$TasksTableTableManager(_$AlphaDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<String?> migratedFromBoardId = const Value.absent(),
                Value<String?> migratedFromTaskId = const Value.absent(),
                Value<bool> isEvent = const Value.absent(),
                Value<String?> scheduledTime = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                boardId: boardId,
                title: title,
                description: description,
                state: state,
                priority: priority,
                position: position,
                createdAt: createdAt,
                completedAt: completedAt,
                deadline: deadline,
                migratedFromBoardId: migratedFromBoardId,
                migratedFromTaskId: migratedFromTaskId,
                isEvent: isEvent,
                scheduledTime: scheduledTime,
                recurrenceRule: recurrenceRule,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boardId,
                required String title,
                Value<String> description = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> priority = const Value.absent(),
                required int position,
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<String?> migratedFromBoardId = const Value.absent(),
                Value<String?> migratedFromTaskId = const Value.absent(),
                Value<bool> isEvent = const Value.absent(),
                Value<String?> scheduledTime = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                boardId: boardId,
                title: title,
                description: description,
                state: state,
                priority: priority,
                position: position,
                createdAt: createdAt,
                completedAt: completedAt,
                deadline: deadline,
                migratedFromBoardId: migratedFromBoardId,
                migratedFromTaskId: migratedFromTaskId,
                isEvent: isEvent,
                scheduledTime: scheduledTime,
                recurrenceRule: recurrenceRule,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                boardId = false,
                markersRefs = false,
                taskNotesRefs = false,
                taskTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (markersRefs) db.markers,
                    if (taskNotesRefs) db.taskNotes,
                    if (taskTagsRefs) db.taskTags,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (boardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.boardId,
                                    referencedTable: $$TasksTableReferences
                                        ._boardIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._boardIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (markersRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          MarkerRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._markersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(db, table, p0).markersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskNotesRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          TaskNoteRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskTagsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          TaskTagRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AlphaDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, $$TasksTableReferences),
      TaskRow,
      PrefetchHooks Function({
        bool boardId,
        bool markersRefs,
        bool taskNotesRefs,
        bool taskTagsRefs,
      })
    >;
typedef $$MarkersTableCreateCompanionBuilder =
    MarkersCompanion Function({
      required String id,
      required String taskId,
      required String columnId,
      required String boardId,
      required String symbol,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MarkersTableUpdateCompanionBuilder =
    MarkersCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> columnId,
      Value<String> boardId,
      Value<String> symbol,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MarkersTableReferences
    extends BaseReferences<_$AlphaDatabase, $MarkersTable, MarkerRow> {
  $$MarkersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AlphaDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.markers.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BoardColumnsTable _columnIdTable(_$AlphaDatabase db) =>
      db.boardColumns.createAlias(
        $_aliasNameGenerator(db.markers.columnId, db.boardColumns.id),
      );

  $$BoardColumnsTableProcessedTableManager get columnId {
    final $_column = $_itemColumn<String>('column_id')!;

    final manager = $$BoardColumnsTableTableManager(
      $_db,
      $_db.boardColumns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_columnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BoardsTable _boardIdTable(_$AlphaDatabase db) => db.boards
      .createAlias($_aliasNameGenerator(db.markers.boardId, db.boards.id));

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MarkersTableFilterComposer
    extends Composer<_$AlphaDatabase, $MarkersTable> {
  $$MarkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardColumnsTableFilterComposer get columnId {
    final $$BoardColumnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableFilterComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarkersTableOrderingComposer
    extends Composer<_$AlphaDatabase, $MarkersTable> {
  $$MarkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardColumnsTableOrderingComposer get columnId {
    final $$BoardColumnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableOrderingComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarkersTableAnnotationComposer
    extends Composer<_$AlphaDatabase, $MarkersTable> {
  $$MarkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardColumnsTableAnnotationComposer get columnId {
    final $$BoardColumnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarkersTableTableManager
    extends
        RootTableManager<
          _$AlphaDatabase,
          $MarkersTable,
          MarkerRow,
          $$MarkersTableFilterComposer,
          $$MarkersTableOrderingComposer,
          $$MarkersTableAnnotationComposer,
          $$MarkersTableCreateCompanionBuilder,
          $$MarkersTableUpdateCompanionBuilder,
          (MarkerRow, $$MarkersTableReferences),
          MarkerRow,
          PrefetchHooks Function({bool taskId, bool columnId, bool boardId})
        > {
  $$MarkersTableTableManager(_$AlphaDatabase db, $MarkersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MarkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MarkersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MarkersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> columnId = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MarkersCompanion(
                id: id,
                taskId: taskId,
                columnId: columnId,
                boardId: boardId,
                symbol: symbol,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String columnId,
                required String boardId,
                required String symbol,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MarkersCompanion.insert(
                id: id,
                taskId: taskId,
                columnId: columnId,
                boardId: boardId,
                symbol: symbol,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MarkersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({taskId = false, columnId = false, boardId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (taskId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.taskId,
                                    referencedTable: $$MarkersTableReferences
                                        ._taskIdTable(db),
                                    referencedColumn: $$MarkersTableReferences
                                        ._taskIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (columnId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.columnId,
                                    referencedTable: $$MarkersTableReferences
                                        ._columnIdTable(db),
                                    referencedColumn: $$MarkersTableReferences
                                        ._columnIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (boardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.boardId,
                                    referencedTable: $$MarkersTableReferences
                                        ._boardIdTable(db),
                                    referencedColumn: $$MarkersTableReferences
                                        ._boardIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$MarkersTableProcessedTableManager =
    ProcessedTableManager<
      _$AlphaDatabase,
      $MarkersTable,
      MarkerRow,
      $$MarkersTableFilterComposer,
      $$MarkersTableOrderingComposer,
      $$MarkersTableAnnotationComposer,
      $$MarkersTableCreateCompanionBuilder,
      $$MarkersTableUpdateCompanionBuilder,
      (MarkerRow, $$MarkersTableReferences),
      MarkerRow,
      PrefetchHooks Function({bool taskId, bool columnId, bool boardId})
    >;
typedef $$TaskNotesTableCreateCompanionBuilder =
    TaskNotesCompanion Function({
      required String id,
      required String taskId,
      required String content,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TaskNotesTableUpdateCompanionBuilder =
    TaskNotesCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TaskNotesTableReferences
    extends BaseReferences<_$AlphaDatabase, $TaskNotesTable, TaskNoteRow> {
  $$TaskNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AlphaDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskNotes.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskNotesTableFilterComposer
    extends Composer<_$AlphaDatabase, $TaskNotesTable> {
  $$TaskNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskNotesTableOrderingComposer
    extends Composer<_$AlphaDatabase, $TaskNotesTable> {
  $$TaskNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskNotesTableAnnotationComposer
    extends Composer<_$AlphaDatabase, $TaskNotesTable> {
  $$TaskNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskNotesTableTableManager
    extends
        RootTableManager<
          _$AlphaDatabase,
          $TaskNotesTable,
          TaskNoteRow,
          $$TaskNotesTableFilterComposer,
          $$TaskNotesTableOrderingComposer,
          $$TaskNotesTableAnnotationComposer,
          $$TaskNotesTableCreateCompanionBuilder,
          $$TaskNotesTableUpdateCompanionBuilder,
          (TaskNoteRow, $$TaskNotesTableReferences),
          TaskNoteRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskNotesTableTableManager(_$AlphaDatabase db, $TaskNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskNotesCompanion(
                id: id,
                taskId: taskId,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String content,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TaskNotesCompanion.insert(
                id: id,
                taskId: taskId,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$TaskNotesTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$TaskNotesTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AlphaDatabase,
      $TaskNotesTable,
      TaskNoteRow,
      $$TaskNotesTableFilterComposer,
      $$TaskNotesTableOrderingComposer,
      $$TaskNotesTableAnnotationComposer,
      $$TaskNotesTableCreateCompanionBuilder,
      $$TaskNotesTableUpdateCompanionBuilder,
      (TaskNoteRow, $$TaskNotesTableReferences),
      TaskNoteRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      required int color,
      required int position,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> color,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AlphaDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskTagsTable, List<TaskTagRow>>
  _taskTagsRefsTable(_$AlphaDatabase db) => MultiTypedResultKey.fromTable(
    db.taskTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.taskTags.tagId),
  );

  $$TaskTagsTableProcessedTableManager get taskTagsRefs {
    final manager = $$TaskTagsTableTableManager(
      $_db,
      $_db.taskTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AlphaDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskTagsRefs(
    Expression<bool> Function($$TaskTagsTableFilterComposer f) f,
  ) {
    final $$TaskTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableFilterComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer
    extends Composer<_$AlphaDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AlphaDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> taskTagsRefs<T extends Object>(
    Expression<T> Function($$TaskTagsTableAnnotationComposer a) f,
  ) {
    final $$TaskTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AlphaDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, $$TagsTableReferences),
          TagRow,
          PrefetchHooks Function({bool taskTagsRefs})
        > {
  $$TagsTableTableManager(_$AlphaDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int color,
                required int position,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({taskTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (taskTagsRefs) db.taskTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskTagsRefs)
                    await $_getPrefetchedData<TagRow, $TagsTable, TaskTagRow>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._taskTagsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).taskTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AlphaDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, $$TagsTableReferences),
      TagRow,
      PrefetchHooks Function({bool taskTagsRefs})
    >;
typedef $$TaskTagsTableCreateCompanionBuilder =
    TaskTagsCompanion Function({
      required String taskId,
      required String tagId,
      required int slot,
      Value<int> rowid,
    });
typedef $$TaskTagsTableUpdateCompanionBuilder =
    TaskTagsCompanion Function({
      Value<String> taskId,
      Value<String> tagId,
      Value<int> slot,
      Value<int> rowid,
    });

final class $$TaskTagsTableReferences
    extends BaseReferences<_$AlphaDatabase, $TaskTagsTable, TaskTagRow> {
  $$TaskTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AlphaDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskTags.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AlphaDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.taskTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskTagsTableFilterComposer
    extends Composer<_$AlphaDatabase, $TaskTagsTable> {
  $$TaskTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableOrderingComposer
    extends Composer<_$AlphaDatabase, $TaskTagsTable> {
  $$TaskTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableAnnotationComposer
    extends Composer<_$AlphaDatabase, $TaskTagsTable> {
  $$TaskTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableTableManager
    extends
        RootTableManager<
          _$AlphaDatabase,
          $TaskTagsTable,
          TaskTagRow,
          $$TaskTagsTableFilterComposer,
          $$TaskTagsTableOrderingComposer,
          $$TaskTagsTableAnnotationComposer,
          $$TaskTagsTableCreateCompanionBuilder,
          $$TaskTagsTableUpdateCompanionBuilder,
          (TaskTagRow, $$TaskTagsTableReferences),
          TaskTagRow,
          PrefetchHooks Function({bool taskId, bool tagId})
        > {
  $$TaskTagsTableTableManager(_$AlphaDatabase db, $TaskTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> slot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTagsCompanion(
                taskId: taskId,
                tagId: tagId,
                slot: slot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String tagId,
                required int slot,
                Value<int> rowid = const Value.absent(),
              }) => TaskTagsCompanion.insert(
                taskId: taskId,
                tagId: tagId,
                slot: slot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$TaskTagsTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$TaskTagsTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$TaskTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$TaskTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AlphaDatabase,
      $TaskTagsTable,
      TaskTagRow,
      $$TaskTagsTableFilterComposer,
      $$TaskTagsTableOrderingComposer,
      $$TaskTagsTableAnnotationComposer,
      $$TaskTagsTableCreateCompanionBuilder,
      $$TaskTagsTableUpdateCompanionBuilder,
      (TaskTagRow, $$TaskTagsTableReferences),
      TaskTagRow,
      PrefetchHooks Function({bool taskId, bool tagId})
    >;

class $AlphaDatabaseManager {
  final _$AlphaDatabase _db;
  $AlphaDatabaseManager(this._db);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db, _db.boards);
  $$BoardColumnsTableTableManager get boardColumns =>
      $$BoardColumnsTableTableManager(_db, _db.boardColumns);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$MarkersTableTableManager get markers =>
      $$MarkersTableTableManager(_db, _db.markers);
  $$TaskNotesTableTableManager get taskNotes =>
      $$TaskNotesTableTableManager(_db, _db.taskNotes);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TaskTagsTableTableManager get taskTags =>
      $$TaskTagsTableTableManager(_db, _db.taskTags);
}
