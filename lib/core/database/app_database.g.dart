// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
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
  List<GeneratedColumn> get $columns => [id, title, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
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
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
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
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Conversation copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Conversation(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConversationsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConversationsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MessageRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MessageRole>($MessagesTable.$converterrole);
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
  @override
  late final GeneratedColumnWithTypeConverter<MessageStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MessageStatus>($MessagesTable.$converterstatus);
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
  static const VerificationMeta _citationsMeta = const VerificationMeta(
    'citations',
  );
  @override
  late final GeneratedColumn<String> citations = GeneratedColumn<String>(
    'citations',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    role,
    content,
    status,
    createdAt,
    citations,
    imagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
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
    if (data.containsKey('citations')) {
      context.handle(
        _citationsMeta,
        citations.isAcceptableOrUnknown(data['citations']!, _citationsMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conversation_id'],
      )!,
      role: $MessagesTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      status: $MessagesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      citations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}citations'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MessageRole, String, String> $converterrole =
      const EnumNameConverter<MessageRole>(MessageRole.values);
  static JsonTypeConverter2<MessageStatus, String, String> $converterstatus =
      const EnumNameConverter<MessageStatus>(MessageStatus.values);
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final int conversationId;
  final MessageRole role;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;

  /// Assistant replies only: JSON list of passage ids given to the model,
  /// where index 0 is citation [1]. `[]` means the library was searched and
  /// nothing matched; null means no search ran (e.g. older messages).
  final String? citations;

  /// User messages only: a photo attached to the message, as a file name
  /// inside the app's photos directory (not an absolute path, so the app
  /// container can move between OS updates/restores).
  final String? imagePath;
  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.status,
    required this.createdAt,
    this.citations,
    this.imagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['conversation_id'] = Variable<int>(conversationId);
    {
      map['role'] = Variable<String>($MessagesTable.$converterrole.toSql(role));
    }
    map['content'] = Variable<String>(content);
    {
      map['status'] = Variable<String>(
        $MessagesTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || citations != null) {
      map['citations'] = Variable<String>(citations);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      status: Value(status),
      createdAt: Value(createdAt),
      citations: citations == null && nullToAbsent
          ? const Value.absent()
          : Value(citations),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      conversationId: serializer.fromJson<int>(json['conversationId']),
      role: $MessagesTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      content: serializer.fromJson<String>(json['content']),
      status: $MessagesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      citations: serializer.fromJson<String?>(json['citations']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conversationId': serializer.toJson<int>(conversationId),
      'role': serializer.toJson<String>(
        $MessagesTable.$converterrole.toJson(role),
      ),
      'content': serializer.toJson<String>(content),
      'status': serializer.toJson<String>(
        $MessagesTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'citations': serializer.toJson<String?>(citations),
      'imagePath': serializer.toJson<String?>(imagePath),
    };
  }

  Message copyWith({
    int? id,
    int? conversationId,
    MessageRole? role,
    String? content,
    MessageStatus? status,
    DateTime? createdAt,
    Value<String?> citations = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
  }) => Message(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    citations: citations.present ? citations.value : this.citations,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      citations: data.citations.present ? data.citations.value : this.citations,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('citations: $citations, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    role,
    content,
    status,
    createdAt,
    citations,
    imagePath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.citations == this.citations &&
          other.imagePath == this.imagePath);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<int> conversationId;
  final Value<MessageRole> role;
  final Value<String> content;
  final Value<MessageStatus> status;
  final Value<DateTime> createdAt;
  final Value<String?> citations;
  final Value<String?> imagePath;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.citations = const Value.absent(),
    this.imagePath = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required int conversationId,
    required MessageRole role,
    required String content,
    required MessageStatus status,
    required DateTime createdAt,
    this.citations = const Value.absent(),
    this.imagePath = const Value.absent(),
  }) : conversationId = Value(conversationId),
       role = Value(role),
       content = Value(content),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<int>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? citations,
    Expression<String>? imagePath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (citations != null) 'citations': citations,
      if (imagePath != null) 'image_path': imagePath,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<int>? conversationId,
    Value<MessageRole>? role,
    Value<String>? content,
    Value<MessageStatus>? status,
    Value<DateTime>? createdAt,
    Value<String?>? citations,
    Value<String?>? imagePath,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      citations: citations ?? this.citations,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $MessagesTable.$converterrole.toSql(role.value),
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $MessagesTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (citations.present) {
      map['citations'] = Variable<String>(citations.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('citations: $citations, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }
}

class $KnowledgePacksTable extends KnowledgePacks
    with TableInfo<$KnowledgePacksTable, KnowledgePack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgePacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  @override
  late final GeneratedColumnWithTypeConverter<PackCategory, String> category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PackCategory>($KnowledgePacksTable.$convertercategory);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _licenseMeta = const VerificationMeta(
    'license',
  );
  @override
  late final GeneratedColumn<String> license = GeneratedColumn<String>(
    'license',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attributionMeta = const VerificationMeta(
    'attribution',
  );
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReviewStatus, String>
  reviewStatus = GeneratedColumn<String>(
    'review_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(ReviewStatus.needsReview.name),
  ).withConverter<ReviewStatus>($KnowledgePacksTable.$converterreviewStatus);
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    category,
    version,
    publisher,
    license,
    attribution,
    reviewStatus,
    sizeBytes,
    source,
    installedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnowledgePack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    } else if (isInserting) {
      context.missing(_publisherMeta);
    }
    if (data.containsKey('license')) {
      context.handle(
        _licenseMeta,
        license.isAcceptableOrUnknown(data['license']!, _licenseMeta),
      );
    } else if (isInserting) {
      context.missing(_licenseMeta);
    }
    if (data.containsKey('attribution')) {
      context.handle(
        _attributionMeta,
        attribution.isAcceptableOrUnknown(
          data['attribution']!,
          _attributionMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KnowledgePack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgePack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: $KnowledgePacksTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      )!,
      license: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license'],
      )!,
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      )!,
      reviewStatus: $KnowledgePacksTable.$converterreviewStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}review_status'],
        )!,
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
    );
  }

  @override
  $KnowledgePacksTable createAlias(String alias) {
    return $KnowledgePacksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PackCategory, String, String> $convertercategory =
      const EnumNameConverter<PackCategory>(PackCategory.values);
  static JsonTypeConverter2<ReviewStatus, String, String>
  $converterreviewStatus = const EnumNameConverter<ReviewStatus>(
    ReviewStatus.values,
  );
}

class KnowledgePack extends DataClass implements Insertable<KnowledgePack> {
  final String id;
  final String title;
  final String description;
  final PackCategory category;
  final String version;
  final String publisher;
  final String license;
  final String attribution;
  final ReviewStatus reviewStatus;
  final int sizeBytes;

  /// Where it was installed from, e.g. `asset:assets/packs/water.json`.
  final String source;
  final DateTime installedAt;
  const KnowledgePack({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.version,
    required this.publisher,
    required this.license,
    required this.attribution,
    required this.reviewStatus,
    required this.sizeBytes,
    required this.source,
    required this.installedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    {
      map['category'] = Variable<String>(
        $KnowledgePacksTable.$convertercategory.toSql(category),
      );
    }
    map['version'] = Variable<String>(version);
    map['publisher'] = Variable<String>(publisher);
    map['license'] = Variable<String>(license);
    map['attribution'] = Variable<String>(attribution);
    {
      map['review_status'] = Variable<String>(
        $KnowledgePacksTable.$converterreviewStatus.toSql(reviewStatus),
      );
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['source'] = Variable<String>(source);
    map['installed_at'] = Variable<DateTime>(installedAt);
    return map;
  }

  KnowledgePacksCompanion toCompanion(bool nullToAbsent) {
    return KnowledgePacksCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      version: Value(version),
      publisher: Value(publisher),
      license: Value(license),
      attribution: Value(attribution),
      reviewStatus: Value(reviewStatus),
      sizeBytes: Value(sizeBytes),
      source: Value(source),
      installedAt: Value(installedAt),
    );
  }

  factory KnowledgePack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgePack(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      category: $KnowledgePacksTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      version: serializer.fromJson<String>(json['version']),
      publisher: serializer.fromJson<String>(json['publisher']),
      license: serializer.fromJson<String>(json['license']),
      attribution: serializer.fromJson<String>(json['attribution']),
      reviewStatus: $KnowledgePacksTable.$converterreviewStatus.fromJson(
        serializer.fromJson<String>(json['reviewStatus']),
      ),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      source: serializer.fromJson<String>(json['source']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(
        $KnowledgePacksTable.$convertercategory.toJson(category),
      ),
      'version': serializer.toJson<String>(version),
      'publisher': serializer.toJson<String>(publisher),
      'license': serializer.toJson<String>(license),
      'attribution': serializer.toJson<String>(attribution),
      'reviewStatus': serializer.toJson<String>(
        $KnowledgePacksTable.$converterreviewStatus.toJson(reviewStatus),
      ),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'source': serializer.toJson<String>(source),
      'installedAt': serializer.toJson<DateTime>(installedAt),
    };
  }

  KnowledgePack copyWith({
    String? id,
    String? title,
    String? description,
    PackCategory? category,
    String? version,
    String? publisher,
    String? license,
    String? attribution,
    ReviewStatus? reviewStatus,
    int? sizeBytes,
    String? source,
    DateTime? installedAt,
  }) => KnowledgePack(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    version: version ?? this.version,
    publisher: publisher ?? this.publisher,
    license: license ?? this.license,
    attribution: attribution ?? this.attribution,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    source: source ?? this.source,
    installedAt: installedAt ?? this.installedAt,
  );
  KnowledgePack copyWithCompanion(KnowledgePacksCompanion data) {
    return KnowledgePack(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      version: data.version.present ? data.version.value : this.version,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      license: data.license.present ? data.license.value : this.license,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      reviewStatus: data.reviewStatus.present
          ? data.reviewStatus.value
          : this.reviewStatus,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      source: data.source.present ? data.source.value : this.source,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgePack(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('version: $version, ')
          ..write('publisher: $publisher, ')
          ..write('license: $license, ')
          ..write('attribution: $attribution, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('source: $source, ')
          ..write('installedAt: $installedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    version,
    publisher,
    license,
    attribution,
    reviewStatus,
    sizeBytes,
    source,
    installedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgePack &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.version == this.version &&
          other.publisher == this.publisher &&
          other.license == this.license &&
          other.attribution == this.attribution &&
          other.reviewStatus == this.reviewStatus &&
          other.sizeBytes == this.sizeBytes &&
          other.source == this.source &&
          other.installedAt == this.installedAt);
}

class KnowledgePacksCompanion extends UpdateCompanion<KnowledgePack> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<PackCategory> category;
  final Value<String> version;
  final Value<String> publisher;
  final Value<String> license;
  final Value<String> attribution;
  final Value<ReviewStatus> reviewStatus;
  final Value<int> sizeBytes;
  final Value<String> source;
  final Value<DateTime> installedAt;
  final Value<int> rowid;
  const KnowledgePacksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.version = const Value.absent(),
    this.publisher = const Value.absent(),
    this.license = const Value.absent(),
    this.attribution = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.source = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnowledgePacksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required PackCategory category,
    required String version,
    required String publisher,
    required String license,
    this.attribution = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    required int sizeBytes,
    required String source,
    required DateTime installedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       category = Value(category),
       version = Value(version),
       publisher = Value(publisher),
       license = Value(license),
       sizeBytes = Value(sizeBytes),
       source = Value(source),
       installedAt = Value(installedAt);
  static Insertable<KnowledgePack> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? version,
    Expression<String>? publisher,
    Expression<String>? license,
    Expression<String>? attribution,
    Expression<String>? reviewStatus,
    Expression<int>? sizeBytes,
    Expression<String>? source,
    Expression<DateTime>? installedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (version != null) 'version': version,
      if (publisher != null) 'publisher': publisher,
      if (license != null) 'license': license,
      if (attribution != null) 'attribution': attribution,
      if (reviewStatus != null) 'review_status': reviewStatus,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (source != null) 'source': source,
      if (installedAt != null) 'installed_at': installedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnowledgePacksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<PackCategory>? category,
    Value<String>? version,
    Value<String>? publisher,
    Value<String>? license,
    Value<String>? attribution,
    Value<ReviewStatus>? reviewStatus,
    Value<int>? sizeBytes,
    Value<String>? source,
    Value<DateTime>? installedAt,
    Value<int>? rowid,
  }) {
    return KnowledgePacksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      version: version ?? this.version,
      publisher: publisher ?? this.publisher,
      license: license ?? this.license,
      attribution: attribution ?? this.attribution,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      source: source ?? this.source,
      installedAt: installedAt ?? this.installedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $KnowledgePacksTable.$convertercategory.toSql(category.value),
      );
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (reviewStatus.present) {
      map['review_status'] = Variable<String>(
        $KnowledgePacksTable.$converterreviewStatus.toSql(reviewStatus.value),
      );
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgePacksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('version: $version, ')
          ..write('publisher: $publisher, ')
          ..write('license: $license, ')
          ..write('attribution: $attribution, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('source: $source, ')
          ..write('installedAt: $installedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PackDocumentsTable extends PackDocuments
    with TableInfo<$PackDocumentsTable, PackDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<String> packId = GeneratedColumn<String>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES knowledge_packs (id) ON DELETE CASCADE',
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
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _aliasesMeta = const VerificationMeta(
    'aliases',
  );
  @override
  late final GeneratedColumn<String> aliases = GeneratedColumn<String>(
    'aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _libraryOnlyMeta = const VerificationMeta(
    'libraryOnly',
  );
  @override
  late final GeneratedColumn<bool> libraryOnly = GeneratedColumn<bool>(
    'library_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("library_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packId,
    title,
    sourceUrl,
    position,
    aliases,
    libraryOnly,
    embedding,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pack_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pack_id')) {
      context.handle(
        _packIdMeta,
        packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
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
    if (data.containsKey('aliases')) {
      context.handle(
        _aliasesMeta,
        aliases.isAcceptableOrUnknown(data['aliases']!, _aliasesMeta),
      );
    }
    if (data.containsKey('library_only')) {
      context.handle(
        _libraryOnlyMeta,
        libraryOnly.isAcceptableOrUnknown(
          data['library_only']!,
          _libraryOnlyMeta,
        ),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PackDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      packId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      aliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases'],
      )!,
      libraryOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}library_only'],
      )!,
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding'],
      ),
    );
  }

  @override
  $PackDocumentsTable createAlias(String alias) {
    return $PackDocumentsTable(attachedDatabase, alias);
  }
}

class PackDocument extends DataClass implements Insertable<PackDocument> {
  final int id;
  final String packId;
  final String title;
  final String? sourceUrl;
  final int position;

  /// Retrieval-only plain-language phrasings (see `DocumentData.aliases`);
  /// indexed with the title in `passages_fts`.
  final String aliases;

  /// Excluded from AI answers (regulation text, reference tables); still
  /// readable and searchable in the Library.
  final bool libraryOnly;

  /// Meaning vector of the title and aliases (int8, see `PassageVectors`),
  /// so a question can match a document as a whole.
  final Uint8List? embedding;
  const PackDocument({
    required this.id,
    required this.packId,
    required this.title,
    this.sourceUrl,
    required this.position,
    required this.aliases,
    required this.libraryOnly,
    this.embedding,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pack_id'] = Variable<String>(packId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    map['position'] = Variable<int>(position);
    map['aliases'] = Variable<String>(aliases);
    map['library_only'] = Variable<bool>(libraryOnly);
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<Uint8List>(embedding);
    }
    return map;
  }

  PackDocumentsCompanion toCompanion(bool nullToAbsent) {
    return PackDocumentsCompanion(
      id: Value(id),
      packId: Value(packId),
      title: Value(title),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      position: Value(position),
      aliases: Value(aliases),
      libraryOnly: Value(libraryOnly),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
    );
  }

  factory PackDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackDocument(
      id: serializer.fromJson<int>(json['id']),
      packId: serializer.fromJson<String>(json['packId']),
      title: serializer.fromJson<String>(json['title']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      position: serializer.fromJson<int>(json['position']),
      aliases: serializer.fromJson<String>(json['aliases']),
      libraryOnly: serializer.fromJson<bool>(json['libraryOnly']),
      embedding: serializer.fromJson<Uint8List?>(json['embedding']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packId': serializer.toJson<String>(packId),
      'title': serializer.toJson<String>(title),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'position': serializer.toJson<int>(position),
      'aliases': serializer.toJson<String>(aliases),
      'libraryOnly': serializer.toJson<bool>(libraryOnly),
      'embedding': serializer.toJson<Uint8List?>(embedding),
    };
  }

  PackDocument copyWith({
    int? id,
    String? packId,
    String? title,
    Value<String?> sourceUrl = const Value.absent(),
    int? position,
    String? aliases,
    bool? libraryOnly,
    Value<Uint8List?> embedding = const Value.absent(),
  }) => PackDocument(
    id: id ?? this.id,
    packId: packId ?? this.packId,
    title: title ?? this.title,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    position: position ?? this.position,
    aliases: aliases ?? this.aliases,
    libraryOnly: libraryOnly ?? this.libraryOnly,
    embedding: embedding.present ? embedding.value : this.embedding,
  );
  PackDocument copyWithCompanion(PackDocumentsCompanion data) {
    return PackDocument(
      id: data.id.present ? data.id.value : this.id,
      packId: data.packId.present ? data.packId.value : this.packId,
      title: data.title.present ? data.title.value : this.title,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      position: data.position.present ? data.position.value : this.position,
      aliases: data.aliases.present ? data.aliases.value : this.aliases,
      libraryOnly: data.libraryOnly.present
          ? data.libraryOnly.value
          : this.libraryOnly,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackDocument(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('position: $position, ')
          ..write('aliases: $aliases, ')
          ..write('libraryOnly: $libraryOnly, ')
          ..write('embedding: $embedding')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packId,
    title,
    sourceUrl,
    position,
    aliases,
    libraryOnly,
    $driftBlobEquality.hash(embedding),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackDocument &&
          other.id == this.id &&
          other.packId == this.packId &&
          other.title == this.title &&
          other.sourceUrl == this.sourceUrl &&
          other.position == this.position &&
          other.aliases == this.aliases &&
          other.libraryOnly == this.libraryOnly &&
          $driftBlobEquality.equals(other.embedding, this.embedding));
}

class PackDocumentsCompanion extends UpdateCompanion<PackDocument> {
  final Value<int> id;
  final Value<String> packId;
  final Value<String> title;
  final Value<String?> sourceUrl;
  final Value<int> position;
  final Value<String> aliases;
  final Value<bool> libraryOnly;
  final Value<Uint8List?> embedding;
  const PackDocumentsCompanion({
    this.id = const Value.absent(),
    this.packId = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.position = const Value.absent(),
    this.aliases = const Value.absent(),
    this.libraryOnly = const Value.absent(),
    this.embedding = const Value.absent(),
  });
  PackDocumentsCompanion.insert({
    this.id = const Value.absent(),
    required String packId,
    required String title,
    this.sourceUrl = const Value.absent(),
    required int position,
    this.aliases = const Value.absent(),
    this.libraryOnly = const Value.absent(),
    this.embedding = const Value.absent(),
  }) : packId = Value(packId),
       title = Value(title),
       position = Value(position);
  static Insertable<PackDocument> custom({
    Expression<int>? id,
    Expression<String>? packId,
    Expression<String>? title,
    Expression<String>? sourceUrl,
    Expression<int>? position,
    Expression<String>? aliases,
    Expression<bool>? libraryOnly,
    Expression<Uint8List>? embedding,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packId != null) 'pack_id': packId,
      if (title != null) 'title': title,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (position != null) 'position': position,
      if (aliases != null) 'aliases': aliases,
      if (libraryOnly != null) 'library_only': libraryOnly,
      if (embedding != null) 'embedding': embedding,
    });
  }

  PackDocumentsCompanion copyWith({
    Value<int>? id,
    Value<String>? packId,
    Value<String>? title,
    Value<String?>? sourceUrl,
    Value<int>? position,
    Value<String>? aliases,
    Value<bool>? libraryOnly,
    Value<Uint8List?>? embedding,
  }) {
    return PackDocumentsCompanion(
      id: id ?? this.id,
      packId: packId ?? this.packId,
      title: title ?? this.title,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      position: position ?? this.position,
      aliases: aliases ?? this.aliases,
      libraryOnly: libraryOnly ?? this.libraryOnly,
      embedding: embedding ?? this.embedding,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packId.present) {
      map['pack_id'] = Variable<String>(packId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (aliases.present) {
      map['aliases'] = Variable<String>(aliases.value);
    }
    if (libraryOnly.present) {
      map['library_only'] = Variable<bool>(libraryOnly.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('position: $position, ')
          ..write('aliases: $aliases, ')
          ..write('libraryOnly: $libraryOnly, ')
          ..write('embedding: $embedding')
          ..write(')'))
        .toString();
  }
}

class $PassagesTable extends Passages with TableInfo<$PassagesTable, Passage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PassagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pack_documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<String> heading = GeneratedColumn<String>(
    'heading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
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
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
    'images',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    heading,
    body,
    position,
    images,
    embedding,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'passages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Passage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    } else if (isInserting) {
      context.missing(_headingMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('images')) {
      context.handle(
        _imagesMeta,
        images.isAcceptableOrUnknown(data['images']!, _imagesMeta),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Passage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Passage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_id'],
      )!,
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heading'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      images: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}images'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding'],
      ),
    );
  }

  @override
  $PassagesTable createAlias(String alias) {
    return $PassagesTable(attachedDatabase, alias);
  }
}

class Passage extends DataClass implements Insertable<Passage> {
  final int id;
  final int documentId;
  final String heading;

  /// Section text. `{{img:N}}` marks where [images] entry N appears.
  final String body;
  final int position;

  /// JSON list of {asset, caption, kind} — figures and tables rendered
  /// from the original page (tables as images so values stay exact).
  final String? images;

  /// Meaning vector (int8, see `PassageVectors`) for semantic search;
  /// null when the pack shipped without vectors.
  final Uint8List? embedding;
  const Passage({
    required this.id,
    required this.documentId,
    required this.heading,
    required this.body,
    required this.position,
    this.images,
    this.embedding,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<int>(documentId);
    map['heading'] = Variable<String>(heading);
    map['body'] = Variable<String>(body);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || images != null) {
      map['images'] = Variable<String>(images);
    }
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<Uint8List>(embedding);
    }
    return map;
  }

  PassagesCompanion toCompanion(bool nullToAbsent) {
    return PassagesCompanion(
      id: Value(id),
      documentId: Value(documentId),
      heading: Value(heading),
      body: Value(body),
      position: Value(position),
      images: images == null && nullToAbsent
          ? const Value.absent()
          : Value(images),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
    );
  }

  factory Passage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Passage(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<int>(json['documentId']),
      heading: serializer.fromJson<String>(json['heading']),
      body: serializer.fromJson<String>(json['body']),
      position: serializer.fromJson<int>(json['position']),
      images: serializer.fromJson<String?>(json['images']),
      embedding: serializer.fromJson<Uint8List?>(json['embedding']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'documentId': serializer.toJson<int>(documentId),
      'heading': serializer.toJson<String>(heading),
      'body': serializer.toJson<String>(body),
      'position': serializer.toJson<int>(position),
      'images': serializer.toJson<String?>(images),
      'embedding': serializer.toJson<Uint8List?>(embedding),
    };
  }

  Passage copyWith({
    int? id,
    int? documentId,
    String? heading,
    String? body,
    int? position,
    Value<String?> images = const Value.absent(),
    Value<Uint8List?> embedding = const Value.absent(),
  }) => Passage(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    heading: heading ?? this.heading,
    body: body ?? this.body,
    position: position ?? this.position,
    images: images.present ? images.value : this.images,
    embedding: embedding.present ? embedding.value : this.embedding,
  );
  Passage copyWithCompanion(PassagesCompanion data) {
    return Passage(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      heading: data.heading.present ? data.heading.value : this.heading,
      body: data.body.present ? data.body.value : this.body,
      position: data.position.present ? data.position.value : this.position,
      images: data.images.present ? data.images.value : this.images,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Passage(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('heading: $heading, ')
          ..write('body: $body, ')
          ..write('position: $position, ')
          ..write('images: $images, ')
          ..write('embedding: $embedding')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    heading,
    body,
    position,
    images,
    $driftBlobEquality.hash(embedding),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Passage &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.heading == this.heading &&
          other.body == this.body &&
          other.position == this.position &&
          other.images == this.images &&
          $driftBlobEquality.equals(other.embedding, this.embedding));
}

class PassagesCompanion extends UpdateCompanion<Passage> {
  final Value<int> id;
  final Value<int> documentId;
  final Value<String> heading;
  final Value<String> body;
  final Value<int> position;
  final Value<String?> images;
  final Value<Uint8List?> embedding;
  const PassagesCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.heading = const Value.absent(),
    this.body = const Value.absent(),
    this.position = const Value.absent(),
    this.images = const Value.absent(),
    this.embedding = const Value.absent(),
  });
  PassagesCompanion.insert({
    this.id = const Value.absent(),
    required int documentId,
    required String heading,
    required String body,
    required int position,
    this.images = const Value.absent(),
    this.embedding = const Value.absent(),
  }) : documentId = Value(documentId),
       heading = Value(heading),
       body = Value(body),
       position = Value(position);
  static Insertable<Passage> custom({
    Expression<int>? id,
    Expression<int>? documentId,
    Expression<String>? heading,
    Expression<String>? body,
    Expression<int>? position,
    Expression<String>? images,
    Expression<Uint8List>? embedding,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (heading != null) 'heading': heading,
      if (body != null) 'body': body,
      if (position != null) 'position': position,
      if (images != null) 'images': images,
      if (embedding != null) 'embedding': embedding,
    });
  }

  PassagesCompanion copyWith({
    Value<int>? id,
    Value<int>? documentId,
    Value<String>? heading,
    Value<String>? body,
    Value<int>? position,
    Value<String?>? images,
    Value<Uint8List?>? embedding,
  }) {
    return PassagesCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      heading: heading ?? this.heading,
      body: body ?? this.body,
      position: position ?? this.position,
      images: images ?? this.images,
      embedding: embedding ?? this.embedding,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (heading.present) {
      map['heading'] = Variable<String>(heading.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PassagesCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('heading: $heading, ')
          ..write('body: $body, ')
          ..write('position: $position, ')
          ..write('images: $images, ')
          ..write('embedding: $embedding')
          ..write(')'))
        .toString();
  }
}

class $InstalledModelsTable extends InstalledModels
    with TableInfo<$InstalledModelsTable, InstalledModel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstalledModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectorFileNameMeta = const VerificationMeta(
    'projectorFileName',
  );
  @override
  late final GeneratedColumn<String> projectorFileName =
      GeneratedColumn<String>(
        'projector_file_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    fileName,
    sizeBytes,
    isActive,
    installedAt,
    projectorFileName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installed_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstalledModel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    if (data.containsKey('projector_file_name')) {
      context.handle(
        _projectorFileNameMeta,
        projectorFileName.isAcceptableOrUnknown(
          data['projector_file_name']!,
          _projectorFileNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstalledModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstalledModel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
      projectorFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}projector_file_name'],
      ),
    );
  }

  @override
  $InstalledModelsTable createAlias(String alias) {
    return $InstalledModelsTable(attachedDatabase, alias);
  }
}

class InstalledModel extends DataClass implements Insertable<InstalledModel> {
  final int id;
  final String displayName;

  /// File name inside the models directory (not an absolute path, so the
  /// app container can move between OS updates/restores).
  final String fileName;
  final int sizeBytes;
  final bool isActive;
  final DateTime installedAt;

  /// Multimodal projector (mmproj GGUF) file name in the models directory,
  /// when the model can see photos; null for text-only models.
  final String? projectorFileName;
  const InstalledModel({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.sizeBytes,
    required this.isActive,
    required this.installedAt,
    this.projectorFileName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['file_name'] = Variable<String>(fileName);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['is_active'] = Variable<bool>(isActive);
    map['installed_at'] = Variable<DateTime>(installedAt);
    if (!nullToAbsent || projectorFileName != null) {
      map['projector_file_name'] = Variable<String>(projectorFileName);
    }
    return map;
  }

  InstalledModelsCompanion toCompanion(bool nullToAbsent) {
    return InstalledModelsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      fileName: Value(fileName),
      sizeBytes: Value(sizeBytes),
      isActive: Value(isActive),
      installedAt: Value(installedAt),
      projectorFileName: projectorFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectorFileName),
    );
  }

  factory InstalledModel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstalledModel(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      fileName: serializer.fromJson<String>(json['fileName']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
      projectorFileName: serializer.fromJson<String?>(
        json['projectorFileName'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'fileName': serializer.toJson<String>(fileName),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'isActive': serializer.toJson<bool>(isActive),
      'installedAt': serializer.toJson<DateTime>(installedAt),
      'projectorFileName': serializer.toJson<String?>(projectorFileName),
    };
  }

  InstalledModel copyWith({
    int? id,
    String? displayName,
    String? fileName,
    int? sizeBytes,
    bool? isActive,
    DateTime? installedAt,
    Value<String?> projectorFileName = const Value.absent(),
  }) => InstalledModel(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    fileName: fileName ?? this.fileName,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    isActive: isActive ?? this.isActive,
    installedAt: installedAt ?? this.installedAt,
    projectorFileName: projectorFileName.present
        ? projectorFileName.value
        : this.projectorFileName,
  );
  InstalledModel copyWithCompanion(InstalledModelsCompanion data) {
    return InstalledModel(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
      projectorFileName: data.projectorFileName.present
          ? data.projectorFileName.value
          : this.projectorFileName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstalledModel(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isActive: $isActive, ')
          ..write('installedAt: $installedAt, ')
          ..write('projectorFileName: $projectorFileName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    fileName,
    sizeBytes,
    isActive,
    installedAt,
    projectorFileName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstalledModel &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.fileName == this.fileName &&
          other.sizeBytes == this.sizeBytes &&
          other.isActive == this.isActive &&
          other.installedAt == this.installedAt &&
          other.projectorFileName == this.projectorFileName);
}

class InstalledModelsCompanion extends UpdateCompanion<InstalledModel> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String> fileName;
  final Value<int> sizeBytes;
  final Value<bool> isActive;
  final Value<DateTime> installedAt;
  final Value<String?> projectorFileName;
  const InstalledModelsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.projectorFileName = const Value.absent(),
  });
  InstalledModelsCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    required String fileName,
    required int sizeBytes,
    this.isActive = const Value.absent(),
    required DateTime installedAt,
    this.projectorFileName = const Value.absent(),
  }) : displayName = Value(displayName),
       fileName = Value(fileName),
       sizeBytes = Value(sizeBytes),
       installedAt = Value(installedAt);
  static Insertable<InstalledModel> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? fileName,
    Expression<int>? sizeBytes,
    Expression<bool>? isActive,
    Expression<DateTime>? installedAt,
    Expression<String>? projectorFileName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (fileName != null) 'file_name': fileName,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (isActive != null) 'is_active': isActive,
      if (installedAt != null) 'installed_at': installedAt,
      if (projectorFileName != null) 'projector_file_name': projectorFileName,
    });
  }

  InstalledModelsCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String>? fileName,
    Value<int>? sizeBytes,
    Value<bool>? isActive,
    Value<DateTime>? installedAt,
    Value<String?>? projectorFileName,
  }) {
    return InstalledModelsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isActive: isActive ?? this.isActive,
      installedAt: installedAt ?? this.installedAt,
      projectorFileName: projectorFileName ?? this.projectorFileName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (projectorFileName.present) {
      map['projector_file_name'] = Variable<String>(projectorFileName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstalledModelsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isActive: $isActive, ')
          ..write('installedAt: $installedAt, ')
          ..write('projectorFileName: $projectorFileName')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $KnowledgePacksTable knowledgePacks = $KnowledgePacksTable(this);
  late final $PackDocumentsTable packDocuments = $PackDocumentsTable(this);
  late final $PassagesTable passages = $PassagesTable(this);
  late final $InstalledModelsTable installedModels = $InstalledModelsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    conversations,
    messages,
    knowledgePacks,
    packDocuments,
    passages,
    installedModels,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'knowledge_packs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pack_documents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pack_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('passages', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      required String title,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ConversationsTableReferences
    extends BaseReferences<_$AppDatabase, $ConversationsTable, Conversation> {
  $$ConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'conversations__id__messages__conversation_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
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

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
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
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (Conversation, $$ConversationsTableReferences),
          Conversation,
          PrefetchHooks Function({bool messagesRefs})
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ConversationsCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConversationsTable, Conversation>(table),
                  $$ConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedDataByColumns<
                      Conversation,
                      $ConversationsTable,
                      Message,
                      $MessagesTable
                    >(
                      currentTable: table,
                      referencedTable: $$ConversationsTableReferences
                          ._messagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConversationsTableReferences(
                            db,
                            table,
                            p0,
                          ).messagesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'conversation_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (Conversation, $$ConversationsTableReferences),
      Conversation,
      PrefetchHooks Function({bool messagesRefs})
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  required int conversationId,
  required MessageRole role,
  required String content,
  required MessageStatus status,
  required DateTime createdAt,
  Value<String?> citations,
  Value<String?> imagePath,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<int> conversationId,
  Value<MessageRole> role,
  Value<String> content,
  Value<MessageStatus> status,
  Value<DateTime> createdAt,
  Value<String?> citations,
  Value<String?> imagePath,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) => db
      .conversations
      .createAlias('messages__conversation_id__conversations__id');

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<int>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MessageRole, MessageRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MessageStatus, MessageStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get citations => $composableBuilder(
    column: $table.citations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get citations => $composableBuilder(
    column: $table.citations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get citations =>
      $composableBuilder(column: $table.citations, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, $$MessagesTableReferences),
          Message,
          PrefetchHooks Function({bool conversationId})
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> conversationId = const Value.absent(),
                Value<MessageRole> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<MessageStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> citations = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                status: status,
                createdAt: createdAt,
                citations: citations,
                imagePath: imagePath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int conversationId,
                required MessageRole role,
                required String content,
                required MessageStatus status,
                required DateTime createdAt,
                Value<String?> citations = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                status: status,
                createdAt: createdAt,
                citations: citations,
                imagePath: imagePath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, Message>(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
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
                    if (conversationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.conversationId,
                        referencedTable: $$MessagesTableReferences
                            ._conversationIdTable(db),
                        referencedColumn: $$MessagesTableReferences
                            ._conversationIdTable(db)
                            .id,
                      ) as T;
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

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, $$MessagesTableReferences),
      Message,
      PrefetchHooks Function({bool conversationId})
    >;
typedef $$KnowledgePacksTableCreateCompanionBuilder =
    KnowledgePacksCompanion Function({
      required String id,
      required String title,
      Value<String> description,
      required PackCategory category,
      required String version,
      required String publisher,
      required String license,
      Value<String> attribution,
      Value<ReviewStatus> reviewStatus,
      required int sizeBytes,
      required String source,
      required DateTime installedAt,
      Value<int> rowid,
    });
typedef $$KnowledgePacksTableUpdateCompanionBuilder =
    KnowledgePacksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<PackCategory> category,
      Value<String> version,
      Value<String> publisher,
      Value<String> license,
      Value<String> attribution,
      Value<ReviewStatus> reviewStatus,
      Value<int> sizeBytes,
      Value<String> source,
      Value<DateTime> installedAt,
      Value<int> rowid,
    });

final class $$KnowledgePacksTableReferences
    extends BaseReferences<_$AppDatabase, $KnowledgePacksTable, KnowledgePack> {
  $$KnowledgePacksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PackDocumentsTable, List<PackDocument>>
  _packDocumentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.packDocuments,
    aliasName: 'knowledge_packs__id__pack_documents__pack_id',
  );

  $$PackDocumentsTableProcessedTableManager get packDocumentsRefs {
    final manager = $$PackDocumentsTableTableManager(
      $_db,
      $_db.packDocuments,
    ).filter((f) => f.packId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_packDocumentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KnowledgePacksTableFilterComposer
    extends Composer<_$AppDatabase, $KnowledgePacksTable> {
  $$KnowledgePacksTableFilterComposer({
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

  ColumnWithTypeConverterFilters<PackCategory, PackCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReviewStatus, ReviewStatus, String>
  get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> packDocumentsRefs(
    Expression<bool> Function($$PackDocumentsTableFilterComposer f) f,
  ) {
    final $$PackDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.packDocuments,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.packDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KnowledgePacksTableOrderingComposer
    extends Composer<_$AppDatabase, $KnowledgePacksTable> {
  $$KnowledgePacksTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KnowledgePacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $KnowledgePacksTable> {
  $$KnowledgePacksTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<PackCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get license =>
      $composableBuilder(column: $table.license, builder: (column) => column);

  GeneratedColumn<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReviewStatus, String> get reviewStatus =>
      $composableBuilder(
        column: $table.reviewStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  Expression<T> packDocumentsRefs<T extends Object>(
    Expression<T> Function($$PackDocumentsTableAnnotationComposer a) f,
  ) {
    final $$PackDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.packDocuments,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.packDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KnowledgePacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KnowledgePacksTable,
          KnowledgePack,
          $$KnowledgePacksTableFilterComposer,
          $$KnowledgePacksTableOrderingComposer,
          $$KnowledgePacksTableAnnotationComposer,
          $$KnowledgePacksTableCreateCompanionBuilder,
          $$KnowledgePacksTableUpdateCompanionBuilder,
          (KnowledgePack, $$KnowledgePacksTableReferences),
          KnowledgePack,
          PrefetchHooks Function({bool packDocumentsRefs})
        > {
  $$KnowledgePacksTableTableManager(
    _$AppDatabase db,
    $KnowledgePacksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnowledgePacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnowledgePacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnowledgePacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<PackCategory> category = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> publisher = const Value.absent(),
                Value<String> license = const Value.absent(),
                Value<String> attribution = const Value.absent(),
                Value<ReviewStatus> reviewStatus = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnowledgePacksCompanion(
                id: id,
                title: title,
                description: description,
                category: category,
                version: version,
                publisher: publisher,
                license: license,
                attribution: attribution,
                reviewStatus: reviewStatus,
                sizeBytes: sizeBytes,
                source: source,
                installedAt: installedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> description = const Value.absent(),
                required PackCategory category,
                required String version,
                required String publisher,
                required String license,
                Value<String> attribution = const Value.absent(),
                Value<ReviewStatus> reviewStatus = const Value.absent(),
                required int sizeBytes,
                required String source,
                required DateTime installedAt,
                Value<int> rowid = const Value.absent(),
              }) => KnowledgePacksCompanion.insert(
                id: id,
                title: title,
                description: description,
                category: category,
                version: version,
                publisher: publisher,
                license: license,
                attribution: attribution,
                reviewStatus: reviewStatus,
                sizeBytes: sizeBytes,
                source: source,
                installedAt: installedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KnowledgePacksTable, KnowledgePack>(table),
                  $$KnowledgePacksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({packDocumentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (packDocumentsRefs) db.packDocuments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (packDocumentsRefs)
                    await $_getPrefetchedDataByColumns<
                      KnowledgePack,
                      $KnowledgePacksTable,
                      PackDocument,
                      $PackDocumentsTable
                    >(
                      currentTable: table,
                      referencedTable: $$KnowledgePacksTableReferences
                          ._packDocumentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$KnowledgePacksTableReferences(
                            db,
                            table,
                            p0,
                          ).packDocumentsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'pack_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$KnowledgePacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KnowledgePacksTable,
      KnowledgePack,
      $$KnowledgePacksTableFilterComposer,
      $$KnowledgePacksTableOrderingComposer,
      $$KnowledgePacksTableAnnotationComposer,
      $$KnowledgePacksTableCreateCompanionBuilder,
      $$KnowledgePacksTableUpdateCompanionBuilder,
      (KnowledgePack, $$KnowledgePacksTableReferences),
      KnowledgePack,
      PrefetchHooks Function({bool packDocumentsRefs})
    >;
typedef $$PackDocumentsTableCreateCompanionBuilder =
    PackDocumentsCompanion Function({
      Value<int> id,
      required String packId,
      required String title,
      Value<String?> sourceUrl,
      required int position,
      Value<String> aliases,
      Value<bool> libraryOnly,
      Value<Uint8List?> embedding,
    });
typedef $$PackDocumentsTableUpdateCompanionBuilder =
    PackDocumentsCompanion Function({
      Value<int> id,
      Value<String> packId,
      Value<String> title,
      Value<String?> sourceUrl,
      Value<int> position,
      Value<String> aliases,
      Value<bool> libraryOnly,
      Value<Uint8List?> embedding,
    });

final class $$PackDocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $PackDocumentsTable, PackDocument> {
  $$PackDocumentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $KnowledgePacksTable _packIdTable(_$AppDatabase db) => db
      .knowledgePacks
      .createAlias('pack_documents__pack_id__knowledge_packs__id');

  $$KnowledgePacksTableProcessedTableManager get packId {
    final $_column = $_itemColumn<String>('pack_id')!;

    final manager = $$KnowledgePacksTableTableManager(
      $_db,
      $_db.knowledgePacks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PassagesTable, List<Passage>> _passagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.passages,
    aliasName: 'pack_documents__id__passages__document_id',
  );

  $$PassagesTableProcessedTableManager get passagesRefs {
    final manager = $$PassagesTableTableManager(
      $_db,
      $_db.passages,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_passagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PackDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $PackDocumentsTable> {
  $$PackDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get libraryOnly => $composableBuilder(
    column: $table.libraryOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  $$KnowledgePacksTableFilterComposer get packId {
    final $$KnowledgePacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.knowledgePacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgePacksTableFilterComposer(
            $db: $db,
            $table: $db.knowledgePacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> passagesRefs(
    Expression<bool> Function($$PassagesTableFilterComposer f) f,
  ) {
    final $$PassagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableFilterComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PackDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PackDocumentsTable> {
  $$PackDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get libraryOnly => $composableBuilder(
    column: $table.libraryOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  $$KnowledgePacksTableOrderingComposer get packId {
    final $$KnowledgePacksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.knowledgePacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgePacksTableOrderingComposer(
            $db: $db,
            $table: $db.knowledgePacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PackDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackDocumentsTable> {
  $$PackDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get aliases =>
      $composableBuilder(column: $table.aliases, builder: (column) => column);

  GeneratedColumn<bool> get libraryOnly => $composableBuilder(
    column: $table.libraryOnly,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  $$KnowledgePacksTableAnnotationComposer get packId {
    final $$KnowledgePacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.knowledgePacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgePacksTableAnnotationComposer(
            $db: $db,
            $table: $db.knowledgePacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> passagesRefs<T extends Object>(
    Expression<T> Function($$PassagesTableAnnotationComposer a) f,
  ) {
    final $$PassagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableAnnotationComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PackDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PackDocumentsTable,
          PackDocument,
          $$PackDocumentsTableFilterComposer,
          $$PackDocumentsTableOrderingComposer,
          $$PackDocumentsTableAnnotationComposer,
          $$PackDocumentsTableCreateCompanionBuilder,
          $$PackDocumentsTableUpdateCompanionBuilder,
          (PackDocument, $$PackDocumentsTableReferences),
          PackDocument,
          PrefetchHooks Function({bool packId, bool passagesRefs})
        > {
  $$PackDocumentsTableTableManager(_$AppDatabase db, $PackDocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> packId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> aliases = const Value.absent(),
                Value<bool> libraryOnly = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
              }) => PackDocumentsCompanion(
                id: id,
                packId: packId,
                title: title,
                sourceUrl: sourceUrl,
                position: position,
                aliases: aliases,
                libraryOnly: libraryOnly,
                embedding: embedding,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String packId,
                required String title,
                Value<String?> sourceUrl = const Value.absent(),
                required int position,
                Value<String> aliases = const Value.absent(),
                Value<bool> libraryOnly = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
              }) => PackDocumentsCompanion.insert(
                id: id,
                packId: packId,
                title: title,
                sourceUrl: sourceUrl,
                position: position,
                aliases: aliases,
                libraryOnly: libraryOnly,
                embedding: embedding,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PackDocumentsTable, PackDocument>(table),
                  $$PackDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({packId = false, passagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (passagesRefs) db.passages],
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
                    if (packId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.packId,
                        referencedTable: $$PackDocumentsTableReferences
                            ._packIdTable(db),
                        referencedColumn: $$PackDocumentsTableReferences
                            ._packIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (passagesRefs)
                    await $_getPrefetchedDataByColumns<
                      PackDocument,
                      $PackDocumentsTable,
                      Passage,
                      $PassagesTable
                    >(
                      currentTable: table,
                      referencedTable: $$PackDocumentsTableReferences
                          ._passagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PackDocumentsTableReferences(
                            db,
                            table,
                            p0,
                          ).passagesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'document_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PackDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PackDocumentsTable,
      PackDocument,
      $$PackDocumentsTableFilterComposer,
      $$PackDocumentsTableOrderingComposer,
      $$PackDocumentsTableAnnotationComposer,
      $$PackDocumentsTableCreateCompanionBuilder,
      $$PackDocumentsTableUpdateCompanionBuilder,
      (PackDocument, $$PackDocumentsTableReferences),
      PackDocument,
      PrefetchHooks Function({bool packId, bool passagesRefs})
    >;
typedef $$PassagesTableCreateCompanionBuilder = PassagesCompanion Function({
  Value<int> id,
  required int documentId,
  required String heading,
  required String body,
  required int position,
  Value<String?> images,
  Value<Uint8List?> embedding,
});
typedef $$PassagesTableUpdateCompanionBuilder = PassagesCompanion Function({
  Value<int> id,
  Value<int> documentId,
  Value<String> heading,
  Value<String> body,
  Value<int> position,
  Value<String?> images,
  Value<Uint8List?> embedding,
});

final class $$PassagesTableReferences
    extends BaseReferences<_$AppDatabase, $PassagesTable, Passage> {
  $$PassagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PackDocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.packDocuments.createAlias('passages__document_id__pack_documents__id');

  $$PackDocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<int>('document_id')!;

    final manager = $$PackDocumentsTableTableManager(
      $_db,
      $_db.packDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PassagesTableFilterComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  $$PackDocumentsTableFilterComposer get documentId {
    final $$PackDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.packDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.packDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  $$PackDocumentsTableOrderingComposer get documentId {
    final $$PackDocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.packDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackDocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.packDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  $$PackDocumentsTableAnnotationComposer get documentId {
    final $$PackDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.packDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.packDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PassagesTable,
          Passage,
          $$PassagesTableFilterComposer,
          $$PassagesTableOrderingComposer,
          $$PassagesTableAnnotationComposer,
          $$PassagesTableCreateCompanionBuilder,
          $$PassagesTableUpdateCompanionBuilder,
          (Passage, $$PassagesTableReferences),
          Passage,
          PrefetchHooks Function({bool documentId})
        > {
  $$PassagesTableTableManager(_$AppDatabase db, $PassagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PassagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PassagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PassagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> documentId = const Value.absent(),
                Value<String> heading = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> images = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
              }) => PassagesCompanion(
                id: id,
                documentId: documentId,
                heading: heading,
                body: body,
                position: position,
                images: images,
                embedding: embedding,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int documentId,
                required String heading,
                required String body,
                required int position,
                Value<String?> images = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
              }) => PassagesCompanion.insert(
                id: id,
                documentId: documentId,
                heading: heading,
                body: body,
                position: position,
                images: images,
                embedding: embedding,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PassagesTable, Passage>(table),
                  $$PassagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
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
                    if (documentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.documentId,
                        referencedTable: $$PassagesTableReferences
                            ._documentIdTable(db),
                        referencedColumn: $$PassagesTableReferences
                            ._documentIdTable(db)
                            .id,
                      ) as T;
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

typedef $$PassagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PassagesTable,
      Passage,
      $$PassagesTableFilterComposer,
      $$PassagesTableOrderingComposer,
      $$PassagesTableAnnotationComposer,
      $$PassagesTableCreateCompanionBuilder,
      $$PassagesTableUpdateCompanionBuilder,
      (Passage, $$PassagesTableReferences),
      Passage,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$InstalledModelsTableCreateCompanionBuilder =
    InstalledModelsCompanion Function({
      Value<int> id,
      required String displayName,
      required String fileName,
      required int sizeBytes,
      Value<bool> isActive,
      required DateTime installedAt,
      Value<String?> projectorFileName,
    });
typedef $$InstalledModelsTableUpdateCompanionBuilder =
    InstalledModelsCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<String> fileName,
      Value<int> sizeBytes,
      Value<bool> isActive,
      Value<DateTime> installedAt,
      Value<String?> projectorFileName,
    });

class $$InstalledModelsTableFilterComposer
    extends Composer<_$AppDatabase, $InstalledModelsTable> {
  $$InstalledModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectorFileName => $composableBuilder(
    column: $table.projectorFileName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstalledModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstalledModelsTable> {
  $$InstalledModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectorFileName => $composableBuilder(
    column: $table.projectorFileName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstalledModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstalledModelsTable> {
  $$InstalledModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectorFileName => $composableBuilder(
    column: $table.projectorFileName,
    builder: (column) => column,
  );
}

class $$InstalledModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstalledModelsTable,
          InstalledModel,
          $$InstalledModelsTableFilterComposer,
          $$InstalledModelsTableOrderingComposer,
          $$InstalledModelsTableAnnotationComposer,
          $$InstalledModelsTableCreateCompanionBuilder,
          $$InstalledModelsTableUpdateCompanionBuilder,
          (
            InstalledModel,
            BaseReferences<
              _$AppDatabase,
              $InstalledModelsTable,
              InstalledModel
            >,
          ),
          InstalledModel,
          PrefetchHooks Function()
        > {
  $$InstalledModelsTableTableManager(
    _$AppDatabase db,
    $InstalledModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstalledModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstalledModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstalledModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<String?> projectorFileName = const Value.absent(),
              }) => InstalledModelsCompanion(
                id: id,
                displayName: displayName,
                fileName: fileName,
                sizeBytes: sizeBytes,
                isActive: isActive,
                installedAt: installedAt,
                projectorFileName: projectorFileName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                required String fileName,
                required int sizeBytes,
                Value<bool> isActive = const Value.absent(),
                required DateTime installedAt,
                Value<String?> projectorFileName = const Value.absent(),
              }) => InstalledModelsCompanion.insert(
                id: id,
                displayName: displayName,
                fileName: fileName,
                sizeBytes: sizeBytes,
                isActive: isActive,
                installedAt: installedAt,
                projectorFileName: projectorFileName,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstalledModelsTable, InstalledModel>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $InstalledModelsTable,
                    InstalledModel
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstalledModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstalledModelsTable,
      InstalledModel,
      $$InstalledModelsTableFilterComposer,
      $$InstalledModelsTableOrderingComposer,
      $$InstalledModelsTableAnnotationComposer,
      $$InstalledModelsTableCreateCompanionBuilder,
      $$InstalledModelsTableUpdateCompanionBuilder,
      (
        InstalledModel,
        BaseReferences<_$AppDatabase, $InstalledModelsTable, InstalledModel>,
      ),
      InstalledModel,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$KnowledgePacksTableTableManager get knowledgePacks =>
      $$KnowledgePacksTableTableManager(_db, _db.knowledgePacks);
  $$PackDocumentsTableTableManager get packDocuments =>
      $$PackDocumentsTableTableManager(_db, _db.packDocuments);
  $$PassagesTableTableManager get passages =>
      $$PassagesTableTableManager(_db, _db.passages);
  $$InstalledModelsTableTableManager get installedModels =>
      $$InstalledModelsTableTableManager(_db, _db.installedModels);
}
