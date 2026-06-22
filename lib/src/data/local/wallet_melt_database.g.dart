// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_melt_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'isDefault', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isDefault" IN (0, 1))'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updatedAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, icon, color, isDefault, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('isDefault')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['isDefault']!, _isDefaultMeta));
    } else if (isInserting) {
      context.missing(_isDefaultMeta);
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updatedAt')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updatedAt']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isDefault'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updatedAt'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;
  const Category(
      {required this.id,
      required this.name,
      required this.icon,
      required this.color,
      required this.isDefault,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<String>(color);
    map['isDefault'] = Variable<bool>(isDefault);
    map['createdAt'] = Variable<String>(createdAt);
    map['updatedAt'] = Variable<String>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<String>(json['color']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<String>(color),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Category copyWith(
          {String? id,
          String? name,
          String? icon,
          String? color,
          bool? isDefault,
          String? createdAt,
          String? updatedAt}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, color, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> color;
  final Value<bool> isDefault;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String icon,
    required String color,
    required bool isDefault,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        icon = Value(icon),
        color = Value(color),
        isDefault = Value(isDefault),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<bool>? isDefault,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (isDefault != null) 'isDefault': isDefault,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? icon,
      Value<String>? color,
      Value<bool>? isDefault,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (isDefault.present) {
      map['isDefault'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updatedAt'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoresTable extends Stores with TableInfo<$StoresTable, Store> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedNameMeta =
      const VerificationMeta('normalizedName');
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
      'normalizedName', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updatedAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<String> archivedAt = GeneratedColumn<String>(
      'archivedAt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, normalizedName, notes, createdAt, updatedAt, archivedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stores';
  @override
  VerificationContext validateIntegrity(Insertable<Store> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalizedName')) {
      context.handle(
          _normalizedNameMeta,
          normalizedName.isAcceptableOrUnknown(
              data['normalizedName']!, _normalizedNameMeta));
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updatedAt')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updatedAt']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archivedAt')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archivedAt']!, _archivedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {normalizedName},
      ];
  @override
  Store map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Store(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      normalizedName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}normalizedName'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updatedAt'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}archivedAt']),
    );
  }

  @override
  $StoresTable createAlias(String alias) {
    return $StoresTable(attachedDatabase, alias);
  }
}

class Store extends DataClass implements Insertable<Store> {
  final String id;
  final String name;
  final String normalizedName;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
  const Store(
      {required this.id,
      required this.name,
      required this.normalizedName,
      this.notes,
      required this.createdAt,
      required this.updatedAt,
      this.archivedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalizedName'] = Variable<String>(normalizedName);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['createdAt'] = Variable<String>(createdAt);
    map['updatedAt'] = Variable<String>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archivedAt'] = Variable<String>(archivedAt);
    }
    return map;
  }

  StoresCompanion toCompanion(bool nullToAbsent) {
    return StoresCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Store.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Store(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      archivedAt: serializer.fromJson<String?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'archivedAt': serializer.toJson<String?>(archivedAt),
    };
  }

  Store copyWith(
          {String? id,
          String? name,
          String? normalizedName,
          Value<String?> notes = const Value.absent(),
          String? createdAt,
          String? updatedAt,
          Value<String?> archivedAt = const Value.absent()}) =>
      Store(
        id: id ?? this.id,
        name: name ?? this.name,
        normalizedName: normalizedName ?? this.normalizedName,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
      );
  Store copyWithCompanion(StoresCompanion data) {
    return Store(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Store(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, normalizedName, notes, createdAt, updatedAt, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Store &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt);
}

class StoresCompanion extends UpdateCompanion<Store> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String?> notes;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> archivedAt;
  final Value<int> rowid;
  const StoresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoresCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    this.notes = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        normalizedName = Value(normalizedName),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Store> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? notes,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalizedName': normalizedName,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (archivedAt != null) 'archivedAt': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoresCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? normalizedName,
      Value<String?>? notes,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? archivedAt,
      Value<int>? rowid}) {
    return StoresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
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
    if (normalizedName.present) {
      map['normalizedName'] = Variable<String>(normalizedName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updatedAt'] = Variable<String>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archivedAt'] = Variable<String>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'categoryId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
      'vendor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'storeId', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES stores (id)'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receiptImageUriMeta =
      const VerificationMeta('receiptImageUri');
  @override
  late final GeneratedColumn<String> receiptImageUri = GeneratedColumn<String>(
      'receiptImageUri', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isRecurringMeta =
      const VerificationMeta('isRecurring');
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
      'isRecurring', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isRecurring" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _recurrenceFrequencyMeta =
      const VerificationMeta('recurrenceFrequency');
  @override
  late final GeneratedColumn<String> recurrenceFrequency =
      GeneratedColumn<String>('recurrenceFrequency', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemizationStatusMeta =
      const VerificationMeta('itemizationStatus');
  @override
  late final GeneratedColumn<String> itemizationStatus =
      GeneratedColumn<String>('itemizationStatus', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemTotalMismatchApprovedMeta =
      const VerificationMeta('itemTotalMismatchApproved');
  @override
  late final GeneratedColumn<bool> itemTotalMismatchApproved =
      GeneratedColumn<bool>('itemTotalMismatchApproved', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("itemTotalMismatchApproved" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updatedAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
      'deletedAt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        amount,
        currency,
        categoryId,
        title,
        vendor,
        storeId,
        date,
        notes,
        receiptImageUri,
        isRecurring,
        recurrenceFrequency,
        itemizationStatus,
        itemTotalMismatchApproved,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('categoryId')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['categoryId']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('vendor')) {
      context.handle(_vendorMeta,
          vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta));
    }
    if (data.containsKey('storeId')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['storeId']!, _storeIdMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('receiptImageUri')) {
      context.handle(
          _receiptImageUriMeta,
          receiptImageUri.isAcceptableOrUnknown(
              data['receiptImageUri']!, _receiptImageUriMeta));
    }
    if (data.containsKey('isRecurring')) {
      context.handle(
          _isRecurringMeta,
          isRecurring.isAcceptableOrUnknown(
              data['isRecurring']!, _isRecurringMeta));
    }
    if (data.containsKey('recurrenceFrequency')) {
      context.handle(
          _recurrenceFrequencyMeta,
          recurrenceFrequency.isAcceptableOrUnknown(
              data['recurrenceFrequency']!, _recurrenceFrequencyMeta));
    }
    if (data.containsKey('itemizationStatus')) {
      context.handle(
          _itemizationStatusMeta,
          itemizationStatus.isAcceptableOrUnknown(
              data['itemizationStatus']!, _itemizationStatusMeta));
    }
    if (data.containsKey('itemTotalMismatchApproved')) {
      context.handle(
          _itemTotalMismatchApprovedMeta,
          itemTotalMismatchApproved.isAcceptableOrUnknown(
              data['itemTotalMismatchApproved']!,
              _itemTotalMismatchApprovedMeta));
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updatedAt')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updatedAt']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deletedAt')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deletedAt']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoryId'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      vendor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vendor']),
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storeId']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      receiptImageUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receiptImageUri']),
      isRecurring: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isRecurring'])!,
      recurrenceFrequency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recurrenceFrequency']),
      itemizationStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}itemizationStatus']),
      itemTotalMismatchApproved: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}itemTotalMismatchApproved'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updatedAt'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deletedAt']),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final double amount;
  final String currency;
  final String categoryId;
  final String title;
  final String? vendor;
  final String? storeId;
  final String date;
  final String? notes;
  final String? receiptImageUri;
  final bool isRecurring;
  final String? recurrenceFrequency;
  final String? itemizationStatus;
  final bool itemTotalMismatchApproved;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  const Expense(
      {required this.id,
      required this.amount,
      required this.currency,
      required this.categoryId,
      required this.title,
      this.vendor,
      this.storeId,
      required this.date,
      this.notes,
      this.receiptImageUri,
      required this.isRecurring,
      this.recurrenceFrequency,
      this.itemizationStatus,
      required this.itemTotalMismatchApproved,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['categoryId'] = Variable<String>(categoryId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || vendor != null) {
      map['vendor'] = Variable<String>(vendor);
    }
    if (!nullToAbsent || storeId != null) {
      map['storeId'] = Variable<String>(storeId);
    }
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || receiptImageUri != null) {
      map['receiptImageUri'] = Variable<String>(receiptImageUri);
    }
    map['isRecurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || recurrenceFrequency != null) {
      map['recurrenceFrequency'] = Variable<String>(recurrenceFrequency);
    }
    if (!nullToAbsent || itemizationStatus != null) {
      map['itemizationStatus'] = Variable<String>(itemizationStatus);
    }
    map['itemTotalMismatchApproved'] =
        Variable<bool>(itemTotalMismatchApproved);
    map['createdAt'] = Variable<String>(createdAt);
    map['updatedAt'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deletedAt'] = Variable<String>(deletedAt);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      amount: Value(amount),
      currency: Value(currency),
      categoryId: Value(categoryId),
      title: Value(title),
      vendor:
          vendor == null && nullToAbsent ? const Value.absent() : Value(vendor),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      date: Value(date),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      receiptImageUri: receiptImageUri == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptImageUri),
      isRecurring: Value(isRecurring),
      recurrenceFrequency: recurrenceFrequency == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceFrequency),
      itemizationStatus: itemizationStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(itemizationStatus),
      itemTotalMismatchApproved: Value(itemTotalMismatchApproved),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      title: serializer.fromJson<String>(json['title']),
      vendor: serializer.fromJson<String?>(json['vendor']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      date: serializer.fromJson<String>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
      receiptImageUri: serializer.fromJson<String?>(json['receiptImageUri']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurrenceFrequency:
          serializer.fromJson<String?>(json['recurrenceFrequency']),
      itemizationStatus:
          serializer.fromJson<String?>(json['itemizationStatus']),
      itemTotalMismatchApproved:
          serializer.fromJson<bool>(json['itemTotalMismatchApproved']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'categoryId': serializer.toJson<String>(categoryId),
      'title': serializer.toJson<String>(title),
      'vendor': serializer.toJson<String?>(vendor),
      'storeId': serializer.toJson<String?>(storeId),
      'date': serializer.toJson<String>(date),
      'notes': serializer.toJson<String?>(notes),
      'receiptImageUri': serializer.toJson<String?>(receiptImageUri),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurrenceFrequency': serializer.toJson<String?>(recurrenceFrequency),
      'itemizationStatus': serializer.toJson<String?>(itemizationStatus),
      'itemTotalMismatchApproved':
          serializer.toJson<bool>(itemTotalMismatchApproved),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  Expense copyWith(
          {String? id,
          double? amount,
          String? currency,
          String? categoryId,
          String? title,
          Value<String?> vendor = const Value.absent(),
          Value<String?> storeId = const Value.absent(),
          String? date,
          Value<String?> notes = const Value.absent(),
          Value<String?> receiptImageUri = const Value.absent(),
          bool? isRecurring,
          Value<String?> recurrenceFrequency = const Value.absent(),
          Value<String?> itemizationStatus = const Value.absent(),
          bool? itemTotalMismatchApproved,
          String? createdAt,
          String? updatedAt,
          Value<String?> deletedAt = const Value.absent()}) =>
      Expense(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        categoryId: categoryId ?? this.categoryId,
        title: title ?? this.title,
        vendor: vendor.present ? vendor.value : this.vendor,
        storeId: storeId.present ? storeId.value : this.storeId,
        date: date ?? this.date,
        notes: notes.present ? notes.value : this.notes,
        receiptImageUri: receiptImageUri.present
            ? receiptImageUri.value
            : this.receiptImageUri,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrenceFrequency: recurrenceFrequency.present
            ? recurrenceFrequency.value
            : this.recurrenceFrequency,
        itemizationStatus: itemizationStatus.present
            ? itemizationStatus.value
            : this.itemizationStatus,
        itemTotalMismatchApproved:
            itemTotalMismatchApproved ?? this.itemTotalMismatchApproved,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      title: data.title.present ? data.title.value : this.title,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      receiptImageUri: data.receiptImageUri.present
          ? data.receiptImageUri.value
          : this.receiptImageUri,
      isRecurring:
          data.isRecurring.present ? data.isRecurring.value : this.isRecurring,
      recurrenceFrequency: data.recurrenceFrequency.present
          ? data.recurrenceFrequency.value
          : this.recurrenceFrequency,
      itemizationStatus: data.itemizationStatus.present
          ? data.itemizationStatus.value
          : this.itemizationStatus,
      itemTotalMismatchApproved: data.itemTotalMismatchApproved.present
          ? data.itemTotalMismatchApproved.value
          : this.itemTotalMismatchApproved,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('vendor: $vendor, ')
          ..write('storeId: $storeId, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('receiptImageUri: $receiptImageUri, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceFrequency: $recurrenceFrequency, ')
          ..write('itemizationStatus: $itemizationStatus, ')
          ..write('itemTotalMismatchApproved: $itemTotalMismatchApproved, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      amount,
      currency,
      categoryId,
      title,
      vendor,
      storeId,
      date,
      notes,
      receiptImageUri,
      isRecurring,
      recurrenceFrequency,
      itemizationStatus,
      itemTotalMismatchApproved,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.categoryId == this.categoryId &&
          other.title == this.title &&
          other.vendor == this.vendor &&
          other.storeId == this.storeId &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.receiptImageUri == this.receiptImageUri &&
          other.isRecurring == this.isRecurring &&
          other.recurrenceFrequency == this.recurrenceFrequency &&
          other.itemizationStatus == this.itemizationStatus &&
          other.itemTotalMismatchApproved == this.itemTotalMismatchApproved &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String> categoryId;
  final Value<String> title;
  final Value<String?> vendor;
  final Value<String?> storeId;
  final Value<String> date;
  final Value<String?> notes;
  final Value<String?> receiptImageUri;
  final Value<bool> isRecurring;
  final Value<String?> recurrenceFrequency;
  final Value<String?> itemizationStatus;
  final Value<bool> itemTotalMismatchApproved;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.vendor = const Value.absent(),
    this.storeId = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.receiptImageUri = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceFrequency = const Value.absent(),
    this.itemizationStatus = const Value.absent(),
    this.itemTotalMismatchApproved = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required double amount,
    required String currency,
    required String categoryId,
    required String title,
    this.vendor = const Value.absent(),
    this.storeId = const Value.absent(),
    required String date,
    this.notes = const Value.absent(),
    this.receiptImageUri = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceFrequency = const Value.absent(),
    this.itemizationStatus = const Value.absent(),
    this.itemTotalMismatchApproved = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        amount = Value(amount),
        currency = Value(currency),
        categoryId = Value(categoryId),
        title = Value(title),
        date = Value(date),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? categoryId,
    Expression<String>? title,
    Expression<String>? vendor,
    Expression<String>? storeId,
    Expression<String>? date,
    Expression<String>? notes,
    Expression<String>? receiptImageUri,
    Expression<bool>? isRecurring,
    Expression<String>? recurrenceFrequency,
    Expression<String>? itemizationStatus,
    Expression<bool>? itemTotalMismatchApproved,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (categoryId != null) 'categoryId': categoryId,
      if (title != null) 'title': title,
      if (vendor != null) 'vendor': vendor,
      if (storeId != null) 'storeId': storeId,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (receiptImageUri != null) 'receiptImageUri': receiptImageUri,
      if (isRecurring != null) 'isRecurring': isRecurring,
      if (recurrenceFrequency != null)
        'recurrenceFrequency': recurrenceFrequency,
      if (itemizationStatus != null) 'itemizationStatus': itemizationStatus,
      if (itemTotalMismatchApproved != null)
        'itemTotalMismatchApproved': itemTotalMismatchApproved,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith(
      {Value<String>? id,
      Value<double>? amount,
      Value<String>? currency,
      Value<String>? categoryId,
      Value<String>? title,
      Value<String?>? vendor,
      Value<String?>? storeId,
      Value<String>? date,
      Value<String?>? notes,
      Value<String?>? receiptImageUri,
      Value<bool>? isRecurring,
      Value<String?>? recurrenceFrequency,
      Value<String?>? itemizationStatus,
      Value<bool>? itemTotalMismatchApproved,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? deletedAt,
      Value<int>? rowid}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      vendor: vendor ?? this.vendor,
      storeId: storeId ?? this.storeId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptImageUri: receiptImageUri ?? this.receiptImageUri,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      itemizationStatus: itemizationStatus ?? this.itemizationStatus,
      itemTotalMismatchApproved:
          itemTotalMismatchApproved ?? this.itemTotalMismatchApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (categoryId.present) {
      map['categoryId'] = Variable<String>(categoryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (storeId.present) {
      map['storeId'] = Variable<String>(storeId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (receiptImageUri.present) {
      map['receiptImageUri'] = Variable<String>(receiptImageUri.value);
    }
    if (isRecurring.present) {
      map['isRecurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurrenceFrequency.present) {
      map['recurrenceFrequency'] = Variable<String>(recurrenceFrequency.value);
    }
    if (itemizationStatus.present) {
      map['itemizationStatus'] = Variable<String>(itemizationStatus.value);
    }
    if (itemTotalMismatchApproved.present) {
      map['itemTotalMismatchApproved'] =
          Variable<bool>(itemTotalMismatchApproved.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updatedAt'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deletedAt'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('vendor: $vendor, ')
          ..write('storeId: $storeId, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('receiptImageUri: $receiptImageUri, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceFrequency: $recurrenceFrequency, ')
          ..write('itemizationStatus: $itemizationStatus, ')
          ..write('itemTotalMismatchApproved: $itemTotalMismatchApproved, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroceryItemsTable extends GroceryItems
    with TableInfo<$GroceryItemsTable, GroceryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroceryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expenseIdMeta =
      const VerificationMeta('expenseId');
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
      'expenseId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES expenses (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, expenseId, name, amount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grocery_items';
  @override
  VerificationContext validateIntegrity(Insertable<GroceryItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expenseId')) {
      context.handle(_expenseIdMeta,
          expenseId.isAcceptableOrUnknown(data['expenseId']!, _expenseIdMeta));
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroceryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroceryItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      expenseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expenseId'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
    );
  }

  @override
  $GroceryItemsTable createAlias(String alias) {
    return $GroceryItemsTable(attachedDatabase, alias);
  }
}

class GroceryItem extends DataClass implements Insertable<GroceryItem> {
  final String id;
  final String expenseId;
  final String name;
  final double amount;
  final String createdAt;
  const GroceryItem(
      {required this.id,
      required this.expenseId,
      required this.name,
      required this.amount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expenseId'] = Variable<String>(expenseId);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['createdAt'] = Variable<String>(createdAt);
    return map;
  }

  GroceryItemsCompanion toCompanion(bool nullToAbsent) {
    return GroceryItemsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      name: Value(name),
      amount: Value(amount),
      createdAt: Value(createdAt),
    );
  }

  factory GroceryItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroceryItem(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  GroceryItem copyWith(
          {String? id,
          String? expenseId,
          String? name,
          double? amount,
          String? createdAt}) =>
      GroceryItem(
        id: id ?? this.id,
        expenseId: expenseId ?? this.expenseId,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        createdAt: createdAt ?? this.createdAt,
      );
  GroceryItem copyWithCompanion(GroceryItemsCompanion data) {
    return GroceryItem(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroceryItem(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, expenseId, name, amount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroceryItem &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt);
}

class GroceryItemsCompanion extends UpdateCompanion<GroceryItem> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String> name;
  final Value<double> amount;
  final Value<String> createdAt;
  final Value<int> rowid;
  const GroceryItemsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroceryItemsCompanion.insert({
    required String id,
    required String expenseId,
    required String name,
    required double amount,
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        expenseId = Value(expenseId),
        name = Value(name),
        amount = Value(amount),
        createdAt = Value(createdAt);
  static Insertable<GroceryItem> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expenseId': expenseId,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (createdAt != null) 'createdAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroceryItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? expenseId,
      Value<String>? name,
      Value<double>? amount,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return GroceryItemsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
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
    if (expenseId.present) {
      map['expenseId'] = Variable<String>(expenseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroceryItemsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryBudgetsTable extends CategoryBudgets
    with TableInfo<$CategoryBudgetsTable, CategoryBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'categoryId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
      'month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updatedAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryId, amount, currency, month, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_budgets';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryBudget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('categoryId')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['categoryId']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updatedAt')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updatedAt']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {categoryId, month},
      ];
  @override
  CategoryBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryBudget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoryId'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updatedAt'])!,
    );
  }

  @override
  $CategoryBudgetsTable createAlias(String alias) {
    return $CategoryBudgetsTable(attachedDatabase, alias);
  }
}

class CategoryBudget extends DataClass implements Insertable<CategoryBudget> {
  final String id;
  final String categoryId;
  final double amount;
  final String currency;
  final String month;
  final String createdAt;
  final String updatedAt;
  const CategoryBudget(
      {required this.id,
      required this.categoryId,
      required this.amount,
      required this.currency,
      required this.month,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['categoryId'] = Variable<String>(categoryId);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['month'] = Variable<String>(month);
    map['createdAt'] = Variable<String>(createdAt);
    map['updatedAt'] = Variable<String>(updatedAt);
    return map;
  }

  CategoryBudgetsCompanion toCompanion(bool nullToAbsent) {
    return CategoryBudgetsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      amount: Value(amount),
      currency: Value(currency),
      month: Value(month),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryBudget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryBudget(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      month: serializer.fromJson<String>(json['month']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'month': serializer.toJson<String>(month),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CategoryBudget copyWith(
          {String? id,
          String? categoryId,
          double? amount,
          String? currency,
          String? month,
          String? createdAt,
          String? updatedAt}) =>
      CategoryBudget(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        month: month ?? this.month,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CategoryBudget copyWithCompanion(CategoryBudgetsCompanion data) {
    return CategoryBudget(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      month: data.month.present ? data.month.value : this.month,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('month: $month, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, categoryId, amount, currency, month, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryBudget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.month == this.month &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoryBudgetsCompanion extends UpdateCompanion<CategoryBudget> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String> month;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CategoryBudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.month = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryBudgetsCompanion.insert({
    required String id,
    required String categoryId,
    required double amount,
    required String currency,
    required String month,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        categoryId = Value(categoryId),
        amount = Value(amount),
        currency = Value(currency),
        month = Value(month),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CategoryBudget> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? month,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'categoryId': categoryId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (month != null) 'month': month,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryBudgetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? categoryId,
      Value<double>? amount,
      Value<String>? currency,
      Value<String>? month,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return CategoryBudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      month: month ?? this.month,
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
    if (categoryId.present) {
      map['categoryId'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updatedAt'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('month: $month, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entityType', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entityId', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localVersionMeta =
      const VerificationMeta('localVersion');
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
      'localVersion', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remoteId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<String> lastSyncedAt = GeneratedColumn<String>(
      'lastSyncedAt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'syncState', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local_only'));
  @override
  List<GeneratedColumn> get $columns =>
      [entityType, entityId, localVersion, remoteId, lastSyncedAt, syncState];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entityType')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entityType']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entityId')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entityId']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('localVersion')) {
      context.handle(
          _localVersionMeta,
          localVersion.isAcceptableOrUnknown(
              data['localVersion']!, _localVersionMeta));
    }
    if (data.containsKey('remoteId')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remoteId']!, _remoteIdMeta));
    }
    if (data.containsKey('lastSyncedAt')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['lastSyncedAt']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('syncState')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['syncState']!, _syncStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entityType'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entityId'])!,
      localVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}localVersion'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remoteId']),
      lastSyncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSyncedAt']),
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}syncState'])!,
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  final String entityType;
  final String entityId;
  final int localVersion;
  final String? remoteId;
  final String? lastSyncedAt;
  final String syncState;
  const SyncMetadataData(
      {required this.entityType,
      required this.entityId,
      required this.localVersion,
      this.remoteId,
      this.lastSyncedAt,
      required this.syncState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entityType'] = Variable<String>(entityType);
    map['entityId'] = Variable<String>(entityId);
    map['localVersion'] = Variable<int>(localVersion);
    if (!nullToAbsent || remoteId != null) {
      map['remoteId'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['lastSyncedAt'] = Variable<String>(lastSyncedAt);
    }
    map['syncState'] = Variable<String>(syncState);
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      localVersion: Value(localVersion),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncState: Value(syncState),
    );
  }

  factory SyncMetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      localVersion: serializer.fromJson<int>(json['localVersion']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      lastSyncedAt: serializer.fromJson<String?>(json['lastSyncedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'localVersion': serializer.toJson<int>(localVersion),
      'remoteId': serializer.toJson<String?>(remoteId),
      'lastSyncedAt': serializer.toJson<String?>(lastSyncedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  SyncMetadataData copyWith(
          {String? entityType,
          String? entityId,
          int? localVersion,
          Value<String?> remoteId = const Value.absent(),
          Value<String?> lastSyncedAt = const Value.absent(),
          String? syncState}) =>
      SyncMetadataData(
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        localVersion: localVersion ?? this.localVersion,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        syncState: syncState ?? this.syncState,
      );
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('localVersion: $localVersion, ')
          ..write('remoteId: $remoteId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      entityType, entityId, localVersion, remoteId, lastSyncedAt, syncState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.localVersion == this.localVersion &&
          other.remoteId == this.remoteId &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncState == this.syncState);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<int> localVersion;
  final Value<String?> remoteId;
  final Value<String?> lastSyncedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String entityType,
    required String entityId,
    this.localVersion = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId);
  static Insertable<SyncMetadataData> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? localVersion,
    Expression<String>? remoteId,
    Expression<String>? lastSyncedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entityType': entityType,
      if (entityId != null) 'entityId': entityId,
      if (localVersion != null) 'localVersion': localVersion,
      if (remoteId != null) 'remoteId': remoteId,
      if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt,
      if (syncState != null) 'syncState': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith(
      {Value<String>? entityType,
      Value<String>? entityId,
      Value<int>? localVersion,
      Value<String?>? remoteId,
      Value<String?>? lastSyncedAt,
      Value<String>? syncState,
      Value<int>? rowid}) {
    return SyncMetadataCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localVersion: localVersion ?? this.localVersion,
      remoteId: remoteId ?? this.remoteId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entityType'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entityId'] = Variable<String>(entityId.value);
    }
    if (localVersion.present) {
      map['localVersion'] = Variable<int>(localVersion.value);
    }
    if (remoteId.present) {
      map['remoteId'] = Variable<String>(remoteId.value);
    }
    if (lastSyncedAt.present) {
      map['lastSyncedAt'] = Variable<String>(lastSyncedAt.value);
    }
    if (syncState.present) {
      map['syncState'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('localVersion: $localVersion, ')
          ..write('remoteId: $remoteId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, Unit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _abbreviationMeta =
      const VerificationMeta('abbreviation');
  @override
  late final GeneratedColumn<String> abbreviation = GeneratedColumn<String>(
      'abbreviation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dimensionMeta =
      const VerificationMeta('dimension');
  @override
  late final GeneratedColumn<String> dimension = GeneratedColumn<String>(
      'dimension', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseUnitIdMeta =
      const VerificationMeta('baseUnitId');
  @override
  late final GeneratedColumn<String> baseUnitId = GeneratedColumn<String>(
      'baseUnitId', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _factorToBaseMeta =
      const VerificationMeta('factorToBase');
  @override
  late final GeneratedColumn<double> factorToBase = GeneratedColumn<double>(
      'factorToBase', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'isDefault', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isDefault" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updatedAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        abbreviation,
        dimension,
        baseUnitId,
        factorToBase,
        isDefault,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(Insertable<Unit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('abbreviation')) {
      context.handle(
          _abbreviationMeta,
          abbreviation.isAcceptableOrUnknown(
              data['abbreviation']!, _abbreviationMeta));
    } else if (isInserting) {
      context.missing(_abbreviationMeta);
    }
    if (data.containsKey('dimension')) {
      context.handle(_dimensionMeta,
          dimension.isAcceptableOrUnknown(data['dimension']!, _dimensionMeta));
    } else if (isInserting) {
      context.missing(_dimensionMeta);
    }
    if (data.containsKey('baseUnitId')) {
      context.handle(
          _baseUnitIdMeta,
          baseUnitId.isAcceptableOrUnknown(
              data['baseUnitId']!, _baseUnitIdMeta));
    }
    if (data.containsKey('factorToBase')) {
      context.handle(
          _factorToBaseMeta,
          factorToBase.isAcceptableOrUnknown(
              data['factorToBase']!, _factorToBaseMeta));
    }
    if (data.containsKey('isDefault')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['isDefault']!, _isDefaultMeta));
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updatedAt')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updatedAt']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Unit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Unit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      abbreviation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}abbreviation'])!,
      dimension: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dimension'])!,
      baseUnitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}baseUnitId']),
      factorToBase: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}factorToBase']),
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isDefault'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updatedAt'])!,
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class Unit extends DataClass implements Insertable<Unit> {
  final String id;
  final String name;
  final String abbreviation;
  final String dimension;
  final String? baseUnitId;
  final double? factorToBase;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;
  const Unit(
      {required this.id,
      required this.name,
      required this.abbreviation,
      required this.dimension,
      this.baseUnitId,
      this.factorToBase,
      required this.isDefault,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['abbreviation'] = Variable<String>(abbreviation);
    map['dimension'] = Variable<String>(dimension);
    if (!nullToAbsent || baseUnitId != null) {
      map['baseUnitId'] = Variable<String>(baseUnitId);
    }
    if (!nullToAbsent || factorToBase != null) {
      map['factorToBase'] = Variable<double>(factorToBase);
    }
    map['isDefault'] = Variable<bool>(isDefault);
    map['createdAt'] = Variable<String>(createdAt);
    map['updatedAt'] = Variable<String>(updatedAt);
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      name: Value(name),
      abbreviation: Value(abbreviation),
      dimension: Value(dimension),
      baseUnitId: baseUnitId == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUnitId),
      factorToBase: factorToBase == null && nullToAbsent
          ? const Value.absent()
          : Value(factorToBase),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Unit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Unit(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      abbreviation: serializer.fromJson<String>(json['abbreviation']),
      dimension: serializer.fromJson<String>(json['dimension']),
      baseUnitId: serializer.fromJson<String?>(json['baseUnitId']),
      factorToBase: serializer.fromJson<double?>(json['factorToBase']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'abbreviation': serializer.toJson<String>(abbreviation),
      'dimension': serializer.toJson<String>(dimension),
      'baseUnitId': serializer.toJson<String?>(baseUnitId),
      'factorToBase': serializer.toJson<double?>(factorToBase),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Unit copyWith(
          {String? id,
          String? name,
          String? abbreviation,
          String? dimension,
          Value<String?> baseUnitId = const Value.absent(),
          Value<double?> factorToBase = const Value.absent(),
          bool? isDefault,
          String? createdAt,
          String? updatedAt}) =>
      Unit(
        id: id ?? this.id,
        name: name ?? this.name,
        abbreviation: abbreviation ?? this.abbreviation,
        dimension: dimension ?? this.dimension,
        baseUnitId: baseUnitId.present ? baseUnitId.value : this.baseUnitId,
        factorToBase:
            factorToBase.present ? factorToBase.value : this.factorToBase,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Unit copyWithCompanion(UnitsCompanion data) {
    return Unit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      abbreviation: data.abbreviation.present
          ? data.abbreviation.value
          : this.abbreviation,
      dimension: data.dimension.present ? data.dimension.value : this.dimension,
      baseUnitId:
          data.baseUnitId.present ? data.baseUnitId.value : this.baseUnitId,
      factorToBase: data.factorToBase.present
          ? data.factorToBase.value
          : this.factorToBase,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Unit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbreviation: $abbreviation, ')
          ..write('dimension: $dimension, ')
          ..write('baseUnitId: $baseUnitId, ')
          ..write('factorToBase: $factorToBase, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, abbreviation, dimension, baseUnitId,
      factorToBase, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Unit &&
          other.id == this.id &&
          other.name == this.name &&
          other.abbreviation == this.abbreviation &&
          other.dimension == this.dimension &&
          other.baseUnitId == this.baseUnitId &&
          other.factorToBase == this.factorToBase &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UnitsCompanion extends UpdateCompanion<Unit> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> abbreviation;
  final Value<String> dimension;
  final Value<String?> baseUnitId;
  final Value<double?> factorToBase;
  final Value<bool> isDefault;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.abbreviation = const Value.absent(),
    this.dimension = const Value.absent(),
    this.baseUnitId = const Value.absent(),
    this.factorToBase = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsCompanion.insert({
    required String id,
    required String name,
    required String abbreviation,
    required String dimension,
    this.baseUnitId = const Value.absent(),
    this.factorToBase = const Value.absent(),
    this.isDefault = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        abbreviation = Value(abbreviation),
        dimension = Value(dimension),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Unit> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? abbreviation,
    Expression<String>? dimension,
    Expression<String>? baseUnitId,
    Expression<double>? factorToBase,
    Expression<bool>? isDefault,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (abbreviation != null) 'abbreviation': abbreviation,
      if (dimension != null) 'dimension': dimension,
      if (baseUnitId != null) 'baseUnitId': baseUnitId,
      if (factorToBase != null) 'factorToBase': factorToBase,
      if (isDefault != null) 'isDefault': isDefault,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? abbreviation,
      Value<String>? dimension,
      Value<String?>? baseUnitId,
      Value<double?>? factorToBase,
      Value<bool>? isDefault,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return UnitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      dimension: dimension ?? this.dimension,
      baseUnitId: baseUnitId ?? this.baseUnitId,
      factorToBase: factorToBase ?? this.factorToBase,
      isDefault: isDefault ?? this.isDefault,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (abbreviation.present) {
      map['abbreviation'] = Variable<String>(abbreviation.value);
    }
    if (dimension.present) {
      map['dimension'] = Variable<String>(dimension.value);
    }
    if (baseUnitId.present) {
      map['baseUnitId'] = Variable<String>(baseUnitId.value);
    }
    if (factorToBase.present) {
      map['factorToBase'] = Variable<double>(factorToBase.value);
    }
    if (isDefault.present) {
      map['isDefault'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updatedAt'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbreviation: $abbreviation, ')
          ..write('dimension: $dimension, ')
          ..write('baseUnitId: $baseUnitId, ')
          ..write('factorToBase: $factorToBase, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedNameMeta =
      const VerificationMeta('normalizedName');
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
      'normalizedName', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _defaultUnitIdMeta =
      const VerificationMeta('defaultUnitId');
  @override
  late final GeneratedColumn<String> defaultUnitId = GeneratedColumn<String>(
      'defaultUnitId', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'categoryId', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updatedAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<String> archivedAt = GeneratedColumn<String>(
      'archivedAt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        normalizedName,
        defaultUnitId,
        categoryId,
        createdAt,
        updatedAt,
        archivedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(Insertable<Item> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalizedName')) {
      context.handle(
          _normalizedNameMeta,
          normalizedName.isAcceptableOrUnknown(
              data['normalizedName']!, _normalizedNameMeta));
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('defaultUnitId')) {
      context.handle(
          _defaultUnitIdMeta,
          defaultUnitId.isAcceptableOrUnknown(
              data['defaultUnitId']!, _defaultUnitIdMeta));
    }
    if (data.containsKey('categoryId')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['categoryId']!, _categoryIdMeta));
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updatedAt')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updatedAt']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archivedAt')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archivedAt']!, _archivedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {normalizedName},
      ];
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      normalizedName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}normalizedName'])!,
      defaultUnitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}defaultUnitId']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoryId']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updatedAt'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}archivedAt']),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final String id;
  final String name;
  final String normalizedName;
  final String? defaultUnitId;
  final String? categoryId;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
  const Item(
      {required this.id,
      required this.name,
      required this.normalizedName,
      this.defaultUnitId,
      this.categoryId,
      required this.createdAt,
      required this.updatedAt,
      this.archivedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalizedName'] = Variable<String>(normalizedName);
    if (!nullToAbsent || defaultUnitId != null) {
      map['defaultUnitId'] = Variable<String>(defaultUnitId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['categoryId'] = Variable<String>(categoryId);
    }
    map['createdAt'] = Variable<String>(createdAt);
    map['updatedAt'] = Variable<String>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archivedAt'] = Variable<String>(archivedAt);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      defaultUnitId: defaultUnitId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultUnitId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Item.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      defaultUnitId: serializer.fromJson<String?>(json['defaultUnitId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      archivedAt: serializer.fromJson<String?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'defaultUnitId': serializer.toJson<String?>(defaultUnitId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'archivedAt': serializer.toJson<String?>(archivedAt),
    };
  }

  Item copyWith(
          {String? id,
          String? name,
          String? normalizedName,
          Value<String?> defaultUnitId = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          String? createdAt,
          String? updatedAt,
          Value<String?> archivedAt = const Value.absent()}) =>
      Item(
        id: id ?? this.id,
        name: name ?? this.name,
        normalizedName: normalizedName ?? this.normalizedName,
        defaultUnitId:
            defaultUnitId.present ? defaultUnitId.value : this.defaultUnitId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
      );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      defaultUnitId: data.defaultUnitId.present
          ? data.defaultUnitId.value
          : this.defaultUnitId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('defaultUnitId: $defaultUnitId, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, normalizedName, defaultUnitId,
      categoryId, createdAt, updatedAt, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.defaultUnitId == this.defaultUnitId &&
          other.categoryId == this.categoryId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String?> defaultUnitId;
  final Value<String?> categoryId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> archivedAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.defaultUnitId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    this.defaultUnitId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        normalizedName = Value(normalizedName),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? defaultUnitId,
    Expression<String>? categoryId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalizedName': normalizedName,
      if (defaultUnitId != null) 'defaultUnitId': defaultUnitId,
      if (categoryId != null) 'categoryId': categoryId,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (archivedAt != null) 'archivedAt': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? normalizedName,
      Value<String?>? defaultUnitId,
      Value<String?>? categoryId,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? archivedAt,
      Value<int>? rowid}) {
    return ItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      defaultUnitId: defaultUnitId ?? this.defaultUnitId,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
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
    if (normalizedName.present) {
      map['normalizedName'] = Variable<String>(normalizedName.value);
    }
    if (defaultUnitId.present) {
      map['defaultUnitId'] = Variable<String>(defaultUnitId.value);
    }
    if (categoryId.present) {
      map['categoryId'] = Variable<String>(categoryId.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updatedAt'] = Variable<String>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archivedAt'] = Variable<String>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('defaultUnitId: $defaultUnitId, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemAliasesTable extends ItemAliases
    with TableInfo<$ItemAliasesTable, ItemAliase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'itemId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES items (id) ON DELETE CASCADE'));
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
      'alias', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedAliasMeta =
      const VerificationMeta('normalizedAlias');
  @override
  late final GeneratedColumn<String> normalizedAlias = GeneratedColumn<String>(
      'normalizedAlias', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, itemId, alias, normalizedAlias, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_aliases';
  @override
  VerificationContext validateIntegrity(Insertable<ItemAliase> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('itemId')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['itemId']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
          _aliasMeta, alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta));
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('normalizedAlias')) {
      context.handle(
          _normalizedAliasMeta,
          normalizedAlias.isAcceptableOrUnknown(
              data['normalizedAlias']!, _normalizedAliasMeta));
    } else if (isInserting) {
      context.missing(_normalizedAliasMeta);
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {normalizedAlias},
      ];
  @override
  ItemAliase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemAliase(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}itemId'])!,
      alias: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alias'])!,
      normalizedAlias: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalizedAlias'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
    );
  }

  @override
  $ItemAliasesTable createAlias(String alias) {
    return $ItemAliasesTable(attachedDatabase, alias);
  }
}

class ItemAliase extends DataClass implements Insertable<ItemAliase> {
  final String id;
  final String itemId;
  final String alias;
  final String normalizedAlias;
  final String createdAt;
  const ItemAliase(
      {required this.id,
      required this.itemId,
      required this.alias,
      required this.normalizedAlias,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['itemId'] = Variable<String>(itemId);
    map['alias'] = Variable<String>(alias);
    map['normalizedAlias'] = Variable<String>(normalizedAlias);
    map['createdAt'] = Variable<String>(createdAt);
    return map;
  }

  ItemAliasesCompanion toCompanion(bool nullToAbsent) {
    return ItemAliasesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      alias: Value(alias),
      normalizedAlias: Value(normalizedAlias),
      createdAt: Value(createdAt),
    );
  }

  factory ItemAliase.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemAliase(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      alias: serializer.fromJson<String>(json['alias']),
      normalizedAlias: serializer.fromJson<String>(json['normalizedAlias']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'alias': serializer.toJson<String>(alias),
      'normalizedAlias': serializer.toJson<String>(normalizedAlias),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ItemAliase copyWith(
          {String? id,
          String? itemId,
          String? alias,
          String? normalizedAlias,
          String? createdAt}) =>
      ItemAliase(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        alias: alias ?? this.alias,
        normalizedAlias: normalizedAlias ?? this.normalizedAlias,
        createdAt: createdAt ?? this.createdAt,
      );
  ItemAliase copyWithCompanion(ItemAliasesCompanion data) {
    return ItemAliase(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      alias: data.alias.present ? data.alias.value : this.alias,
      normalizedAlias: data.normalizedAlias.present
          ? data.normalizedAlias.value
          : this.normalizedAlias,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemAliase(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('alias: $alias, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, alias, normalizedAlias, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemAliase &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.alias == this.alias &&
          other.normalizedAlias == this.normalizedAlias &&
          other.createdAt == this.createdAt);
}

class ItemAliasesCompanion extends UpdateCompanion<ItemAliase> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> alias;
  final Value<String> normalizedAlias;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ItemAliasesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.alias = const Value.absent(),
    this.normalizedAlias = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemAliasesCompanion.insert({
    required String id,
    required String itemId,
    required String alias,
    required String normalizedAlias,
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        itemId = Value(itemId),
        alias = Value(alias),
        normalizedAlias = Value(normalizedAlias),
        createdAt = Value(createdAt);
  static Insertable<ItemAliase> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? alias,
    Expression<String>? normalizedAlias,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'itemId': itemId,
      if (alias != null) 'alias': alias,
      if (normalizedAlias != null) 'normalizedAlias': normalizedAlias,
      if (createdAt != null) 'createdAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemAliasesCompanion copyWith(
      {Value<String>? id,
      Value<String>? itemId,
      Value<String>? alias,
      Value<String>? normalizedAlias,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return ItemAliasesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      alias: alias ?? this.alias,
      normalizedAlias: normalizedAlias ?? this.normalizedAlias,
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
    if (itemId.present) {
      map['itemId'] = Variable<String>(itemId.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (normalizedAlias.present) {
      map['normalizedAlias'] = Variable<String>(normalizedAlias.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemAliasesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('alias: $alias, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseItemsTable extends ExpenseItems
    with TableInfo<$ExpenseItemsTable, ExpenseItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expenseIdMeta =
      const VerificationMeta('expenseId');
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
      'expenseId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES expenses (id) ON DELETE CASCADE'));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'itemId', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES items (id)'));
  static const VerificationMeta _nameSnapshotMeta =
      const VerificationMeta('nameSnapshot');
  @override
  late final GeneratedColumn<String> nameSnapshot = GeneratedColumn<String>(
      'nameSnapshot', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unitId', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _unitPriceMeta =
      const VerificationMeta('unitPrice');
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
      'unitPrice', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalPriceMeta =
      const VerificationMeta('totalPrice');
  @override
  late final GeneratedColumn<double> totalPrice = GeneratedColumn<double>(
      'totalPrice', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
      'brand', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'storeId', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES stores (id)'));
  static const VerificationMeta _dateOverrideMeta =
      const VerificationMeta('dateOverride');
  @override
  late final GeneratedColumn<String> dateOverride = GeneratedColumn<String>(
      'dateOverride', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'categoryId', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _subcategoryMeta =
      const VerificationMeta('subcategory');
  @override
  late final GeneratedColumn<String> subcategory = GeneratedColumn<String>(
      'subcategory', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updatedAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
      'deletedAt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        expenseId,
        itemId,
        nameSnapshot,
        quantity,
        unitId,
        unitPrice,
        totalPrice,
        currency,
        brand,
        storeId,
        dateOverride,
        categoryId,
        subcategory,
        notes,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_items';
  @override
  VerificationContext validateIntegrity(Insertable<ExpenseItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expenseId')) {
      context.handle(_expenseIdMeta,
          expenseId.isAcceptableOrUnknown(data['expenseId']!, _expenseIdMeta));
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('itemId')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['itemId']!, _itemIdMeta));
    }
    if (data.containsKey('nameSnapshot')) {
      context.handle(
          _nameSnapshotMeta,
          nameSnapshot.isAcceptableOrUnknown(
              data['nameSnapshot']!, _nameSnapshotMeta));
    } else if (isInserting) {
      context.missing(_nameSnapshotMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unitId')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unitId']!, _unitIdMeta));
    }
    if (data.containsKey('unitPrice')) {
      context.handle(_unitPriceMeta,
          unitPrice.isAcceptableOrUnknown(data['unitPrice']!, _unitPriceMeta));
    }
    if (data.containsKey('totalPrice')) {
      context.handle(
          _totalPriceMeta,
          totalPrice.isAcceptableOrUnknown(
              data['totalPrice']!, _totalPriceMeta));
    } else if (isInserting) {
      context.missing(_totalPriceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
          _brandMeta, brand.isAcceptableOrUnknown(data['brand']!, _brandMeta));
    }
    if (data.containsKey('storeId')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['storeId']!, _storeIdMeta));
    }
    if (data.containsKey('dateOverride')) {
      context.handle(
          _dateOverrideMeta,
          dateOverride.isAcceptableOrUnknown(
              data['dateOverride']!, _dateOverrideMeta));
    }
    if (data.containsKey('categoryId')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['categoryId']!, _categoryIdMeta));
    }
    if (data.containsKey('subcategory')) {
      context.handle(
          _subcategoryMeta,
          subcategory.isAcceptableOrUnknown(
              data['subcategory']!, _subcategoryMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updatedAt')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updatedAt']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deletedAt')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deletedAt']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      expenseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expenseId'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}itemId']),
      nameSnapshot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nameSnapshot'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unitId']),
      unitPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unitPrice']),
      totalPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}totalPrice'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      brand: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brand']),
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storeId']),
      dateOverride: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dateOverride']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoryId']),
      subcategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subcategory']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updatedAt'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deletedAt']),
    );
  }

  @override
  $ExpenseItemsTable createAlias(String alias) {
    return $ExpenseItemsTable(attachedDatabase, alias);
  }
}

class ExpenseItem extends DataClass implements Insertable<ExpenseItem> {
  final String id;
  final String expenseId;
  final String? itemId;
  final String nameSnapshot;
  final double? quantity;
  final String? unitId;
  final double? unitPrice;
  final double totalPrice;
  final String currency;
  final String? brand;
  final String? storeId;
  final String? dateOverride;
  final String? categoryId;
  final String? subcategory;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  const ExpenseItem(
      {required this.id,
      required this.expenseId,
      this.itemId,
      required this.nameSnapshot,
      this.quantity,
      this.unitId,
      this.unitPrice,
      required this.totalPrice,
      required this.currency,
      this.brand,
      this.storeId,
      this.dateOverride,
      this.categoryId,
      this.subcategory,
      this.notes,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expenseId'] = Variable<String>(expenseId);
    if (!nullToAbsent || itemId != null) {
      map['itemId'] = Variable<String>(itemId);
    }
    map['nameSnapshot'] = Variable<String>(nameSnapshot);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unitId != null) {
      map['unitId'] = Variable<String>(unitId);
    }
    if (!nullToAbsent || unitPrice != null) {
      map['unitPrice'] = Variable<double>(unitPrice);
    }
    map['totalPrice'] = Variable<double>(totalPrice);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || storeId != null) {
      map['storeId'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || dateOverride != null) {
      map['dateOverride'] = Variable<String>(dateOverride);
    }
    if (!nullToAbsent || categoryId != null) {
      map['categoryId'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || subcategory != null) {
      map['subcategory'] = Variable<String>(subcategory);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['createdAt'] = Variable<String>(createdAt);
    map['updatedAt'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deletedAt'] = Variable<String>(deletedAt);
    }
    return map;
  }

  ExpenseItemsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseItemsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      itemId:
          itemId == null && nullToAbsent ? const Value.absent() : Value(itemId),
      nameSnapshot: Value(nameSnapshot),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      unitPrice: unitPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPrice),
      totalPrice: Value(totalPrice),
      currency: Value(currency),
      brand:
          brand == null && nullToAbsent ? const Value.absent() : Value(brand),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      dateOverride: dateOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOverride),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      subcategory: subcategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategory),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ExpenseItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseItem(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      nameSnapshot: serializer.fromJson<String>(json['nameSnapshot']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      unitPrice: serializer.fromJson<double?>(json['unitPrice']),
      totalPrice: serializer.fromJson<double>(json['totalPrice']),
      currency: serializer.fromJson<String>(json['currency']),
      brand: serializer.fromJson<String?>(json['brand']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      dateOverride: serializer.fromJson<String?>(json['dateOverride']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      subcategory: serializer.fromJson<String?>(json['subcategory']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'itemId': serializer.toJson<String?>(itemId),
      'nameSnapshot': serializer.toJson<String>(nameSnapshot),
      'quantity': serializer.toJson<double?>(quantity),
      'unitId': serializer.toJson<String?>(unitId),
      'unitPrice': serializer.toJson<double?>(unitPrice),
      'totalPrice': serializer.toJson<double>(totalPrice),
      'currency': serializer.toJson<String>(currency),
      'brand': serializer.toJson<String?>(brand),
      'storeId': serializer.toJson<String?>(storeId),
      'dateOverride': serializer.toJson<String?>(dateOverride),
      'categoryId': serializer.toJson<String?>(categoryId),
      'subcategory': serializer.toJson<String?>(subcategory),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  ExpenseItem copyWith(
          {String? id,
          String? expenseId,
          Value<String?> itemId = const Value.absent(),
          String? nameSnapshot,
          Value<double?> quantity = const Value.absent(),
          Value<String?> unitId = const Value.absent(),
          Value<double?> unitPrice = const Value.absent(),
          double? totalPrice,
          String? currency,
          Value<String?> brand = const Value.absent(),
          Value<String?> storeId = const Value.absent(),
          Value<String?> dateOverride = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          Value<String?> subcategory = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? createdAt,
          String? updatedAt,
          Value<String?> deletedAt = const Value.absent()}) =>
      ExpenseItem(
        id: id ?? this.id,
        expenseId: expenseId ?? this.expenseId,
        itemId: itemId.present ? itemId.value : this.itemId,
        nameSnapshot: nameSnapshot ?? this.nameSnapshot,
        quantity: quantity.present ? quantity.value : this.quantity,
        unitId: unitId.present ? unitId.value : this.unitId,
        unitPrice: unitPrice.present ? unitPrice.value : this.unitPrice,
        totalPrice: totalPrice ?? this.totalPrice,
        currency: currency ?? this.currency,
        brand: brand.present ? brand.value : this.brand,
        storeId: storeId.present ? storeId.value : this.storeId,
        dateOverride:
            dateOverride.present ? dateOverride.value : this.dateOverride,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        subcategory: subcategory.present ? subcategory.value : this.subcategory,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ExpenseItem copyWithCompanion(ExpenseItemsCompanion data) {
    return ExpenseItem(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      nameSnapshot: data.nameSnapshot.present
          ? data.nameSnapshot.value
          : this.nameSnapshot,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      totalPrice:
          data.totalPrice.present ? data.totalPrice.value : this.totalPrice,
      currency: data.currency.present ? data.currency.value : this.currency,
      brand: data.brand.present ? data.brand.value : this.brand,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      dateOverride: data.dateOverride.present
          ? data.dateOverride.value
          : this.dateOverride,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      subcategory:
          data.subcategory.present ? data.subcategory.value : this.subcategory,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseItem(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('itemId: $itemId, ')
          ..write('nameSnapshot: $nameSnapshot, ')
          ..write('quantity: $quantity, ')
          ..write('unitId: $unitId, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('totalPrice: $totalPrice, ')
          ..write('currency: $currency, ')
          ..write('brand: $brand, ')
          ..write('storeId: $storeId, ')
          ..write('dateOverride: $dateOverride, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategory: $subcategory, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      expenseId,
      itemId,
      nameSnapshot,
      quantity,
      unitId,
      unitPrice,
      totalPrice,
      currency,
      brand,
      storeId,
      dateOverride,
      categoryId,
      subcategory,
      notes,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseItem &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.itemId == this.itemId &&
          other.nameSnapshot == this.nameSnapshot &&
          other.quantity == this.quantity &&
          other.unitId == this.unitId &&
          other.unitPrice == this.unitPrice &&
          other.totalPrice == this.totalPrice &&
          other.currency == this.currency &&
          other.brand == this.brand &&
          other.storeId == this.storeId &&
          other.dateOverride == this.dateOverride &&
          other.categoryId == this.categoryId &&
          other.subcategory == this.subcategory &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ExpenseItemsCompanion extends UpdateCompanion<ExpenseItem> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String?> itemId;
  final Value<String> nameSnapshot;
  final Value<double?> quantity;
  final Value<String?> unitId;
  final Value<double?> unitPrice;
  final Value<double> totalPrice;
  final Value<String> currency;
  final Value<String?> brand;
  final Value<String?> storeId;
  final Value<String?> dateOverride;
  final Value<String?> categoryId;
  final Value<String?> subcategory;
  final Value<String?> notes;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const ExpenseItemsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.nameSnapshot = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitId = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.totalPrice = const Value.absent(),
    this.currency = const Value.absent(),
    this.brand = const Value.absent(),
    this.storeId = const Value.absent(),
    this.dateOverride = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseItemsCompanion.insert({
    required String id,
    required String expenseId,
    this.itemId = const Value.absent(),
    required String nameSnapshot,
    this.quantity = const Value.absent(),
    this.unitId = const Value.absent(),
    this.unitPrice = const Value.absent(),
    required double totalPrice,
    required String currency,
    this.brand = const Value.absent(),
    this.storeId = const Value.absent(),
    this.dateOverride = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        expenseId = Value(expenseId),
        nameSnapshot = Value(nameSnapshot),
        totalPrice = Value(totalPrice),
        currency = Value(currency),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ExpenseItem> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? itemId,
    Expression<String>? nameSnapshot,
    Expression<double>? quantity,
    Expression<String>? unitId,
    Expression<double>? unitPrice,
    Expression<double>? totalPrice,
    Expression<String>? currency,
    Expression<String>? brand,
    Expression<String>? storeId,
    Expression<String>? dateOverride,
    Expression<String>? categoryId,
    Expression<String>? subcategory,
    Expression<String>? notes,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expenseId': expenseId,
      if (itemId != null) 'itemId': itemId,
      if (nameSnapshot != null) 'nameSnapshot': nameSnapshot,
      if (quantity != null) 'quantity': quantity,
      if (unitId != null) 'unitId': unitId,
      if (unitPrice != null) 'unitPrice': unitPrice,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (currency != null) 'currency': currency,
      if (brand != null) 'brand': brand,
      if (storeId != null) 'storeId': storeId,
      if (dateOverride != null) 'dateOverride': dateOverride,
      if (categoryId != null) 'categoryId': categoryId,
      if (subcategory != null) 'subcategory': subcategory,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? expenseId,
      Value<String?>? itemId,
      Value<String>? nameSnapshot,
      Value<double?>? quantity,
      Value<String?>? unitId,
      Value<double?>? unitPrice,
      Value<double>? totalPrice,
      Value<String>? currency,
      Value<String?>? brand,
      Value<String?>? storeId,
      Value<String?>? dateOverride,
      Value<String?>? categoryId,
      Value<String?>? subcategory,
      Value<String?>? notes,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? deletedAt,
      Value<int>? rowid}) {
    return ExpenseItemsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      itemId: itemId ?? this.itemId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      currency: currency ?? this.currency,
      brand: brand ?? this.brand,
      storeId: storeId ?? this.storeId,
      dateOverride: dateOverride ?? this.dateOverride,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expenseId'] = Variable<String>(expenseId.value);
    }
    if (itemId.present) {
      map['itemId'] = Variable<String>(itemId.value);
    }
    if (nameSnapshot.present) {
      map['nameSnapshot'] = Variable<String>(nameSnapshot.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitId.present) {
      map['unitId'] = Variable<String>(unitId.value);
    }
    if (unitPrice.present) {
      map['unitPrice'] = Variable<double>(unitPrice.value);
    }
    if (totalPrice.present) {
      map['totalPrice'] = Variable<double>(totalPrice.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (storeId.present) {
      map['storeId'] = Variable<String>(storeId.value);
    }
    if (dateOverride.present) {
      map['dateOverride'] = Variable<String>(dateOverride.value);
    }
    if (categoryId.present) {
      map['categoryId'] = Variable<String>(categoryId.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(subcategory.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updatedAt'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deletedAt'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseItemsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('itemId: $itemId, ')
          ..write('nameSnapshot: $nameSnapshot, ')
          ..write('quantity: $quantity, ')
          ..write('unitId: $unitId, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('totalPrice: $totalPrice, ')
          ..write('currency: $currency, ')
          ..write('brand: $brand, ')
          ..write('storeId: $storeId, ')
          ..write('dateOverride: $dateOverride, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategory: $subcategory, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expenseIdMeta =
      const VerificationMeta('expenseId');
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
      'expenseId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES expenses (id) ON DELETE CASCADE'));
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
      'uri', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mimeType', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'fileSizeBytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
      'deletedAt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, expenseId, uri, mimeType, fileSizeBytes, createdAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(Insertable<Receipt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expenseId')) {
      context.handle(_expenseIdMeta,
          expenseId.isAcceptableOrUnknown(data['expenseId']!, _expenseIdMeta));
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
          _uriMeta, uri.isAcceptableOrUnknown(data['uri']!, _uriMeta));
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('mimeType')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mimeType']!, _mimeTypeMeta));
    }
    if (data.containsKey('fileSizeBytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['fileSizeBytes']!, _fileSizeBytesMeta));
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deletedAt')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deletedAt']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      expenseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expenseId'])!,
      uri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uri'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mimeType']),
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fileSizeBytes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deletedAt']),
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final String id;
  final String expenseId;
  final String uri;
  final String? mimeType;
  final int? fileSizeBytes;
  final String createdAt;
  final String? deletedAt;
  const Receipt(
      {required this.id,
      required this.expenseId,
      required this.uri,
      this.mimeType,
      this.fileSizeBytes,
      required this.createdAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expenseId'] = Variable<String>(expenseId);
    map['uri'] = Variable<String>(uri);
    if (!nullToAbsent || mimeType != null) {
      map['mimeType'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || fileSizeBytes != null) {
      map['fileSizeBytes'] = Variable<int>(fileSizeBytes);
    }
    map['createdAt'] = Variable<String>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deletedAt'] = Variable<String>(deletedAt);
    }
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      uri: Value(uri),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Receipt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      uri: serializer.fromJson<String>(json['uri']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'uri': serializer.toJson<String>(uri),
      'mimeType': serializer.toJson<String?>(mimeType),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'createdAt': serializer.toJson<String>(createdAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  Receipt copyWith(
          {String? id,
          String? expenseId,
          String? uri,
          Value<String?> mimeType = const Value.absent(),
          Value<int?> fileSizeBytes = const Value.absent(),
          String? createdAt,
          Value<String?> deletedAt = const Value.absent()}) =>
      Receipt(
        id: id ?? this.id,
        expenseId: expenseId ?? this.expenseId,
        uri: uri ?? this.uri,
        mimeType: mimeType.present ? mimeType.value : this.mimeType,
        fileSizeBytes:
            fileSizeBytes.present ? fileSizeBytes.value : this.fileSizeBytes,
        createdAt: createdAt ?? this.createdAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      uri: data.uri.present ? data.uri.value : this.uri,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('uri: $uri, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, expenseId, uri, mimeType, fileSizeBytes, createdAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.uri == this.uri &&
          other.mimeType == this.mimeType &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String> uri;
  final Value<String?> mimeType;
  final Value<int?> fileSizeBytes;
  final Value<String> createdAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.uri = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required String id,
    required String expenseId,
    required String uri,
    this.mimeType = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    required String createdAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        expenseId = Value(expenseId),
        uri = Value(uri),
        createdAt = Value(createdAt);
  static Insertable<Receipt> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? uri,
    Expression<String>? mimeType,
    Expression<int>? fileSizeBytes,
    Expression<String>? createdAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expenseId': expenseId,
      if (uri != null) 'uri': uri,
      if (mimeType != null) 'mimeType': mimeType,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      if (createdAt != null) 'createdAt': createdAt,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith(
      {Value<String>? id,
      Value<String>? expenseId,
      Value<String>? uri,
      Value<String?>? mimeType,
      Value<int?>? fileSizeBytes,
      Value<String>? createdAt,
      Value<String?>? deletedAt,
      Value<int>? rowid}) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      uri: uri ?? this.uri,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expenseId'] = Variable<String>(expenseId.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (mimeType.present) {
      map['mimeType'] = Variable<String>(mimeType.value);
    }
    if (fileSizeBytes.present) {
      map['fileSizeBytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deletedAt'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('uri: $uri, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MigrationAuditTable extends MigrationAudit
    with TableInfo<$MigrationAuditTable, MigrationAuditData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationAuditTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromVersionMeta =
      const VerificationMeta('fromVersion');
  @override
  late final GeneratedColumn<int> fromVersion = GeneratedColumn<int>(
      'fromVersion', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _toVersionMeta =
      const VerificationMeta('toVersion');
  @override
  late final GeneratedColumn<int> toVersion = GeneratedColumn<int>(
      'toVersion', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
      'startedAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
      'completedAt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'errorMessage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _preMigrationBackupPathMeta =
      const VerificationMeta('preMigrationBackupPath');
  @override
  late final GeneratedColumn<String> preMigrationBackupPath =
      GeneratedColumn<String>('preMigrationBackupPath', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fromVersion,
        toVersion,
        startedAt,
        completedAt,
        status,
        errorMessage,
        preMigrationBackupPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_audit';
  @override
  VerificationContext validateIntegrity(Insertable<MigrationAuditData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fromVersion')) {
      context.handle(
          _fromVersionMeta,
          fromVersion.isAcceptableOrUnknown(
              data['fromVersion']!, _fromVersionMeta));
    } else if (isInserting) {
      context.missing(_fromVersionMeta);
    }
    if (data.containsKey('toVersion')) {
      context.handle(_toVersionMeta,
          toVersion.isAcceptableOrUnknown(data['toVersion']!, _toVersionMeta));
    } else if (isInserting) {
      context.missing(_toVersionMeta);
    }
    if (data.containsKey('startedAt')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['startedAt']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completedAt')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completedAt']!, _completedAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('errorMessage')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['errorMessage']!, _errorMessageMeta));
    }
    if (data.containsKey('preMigrationBackupPath')) {
      context.handle(
          _preMigrationBackupPathMeta,
          preMigrationBackupPath.isAcceptableOrUnknown(
              data['preMigrationBackupPath']!, _preMigrationBackupPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MigrationAuditData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationAuditData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fromVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fromVersion'])!,
      toVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}toVersion'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}startedAt'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}completedAt']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}errorMessage']),
      preMigrationBackupPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}preMigrationBackupPath']),
    );
  }

  @override
  $MigrationAuditTable createAlias(String alias) {
    return $MigrationAuditTable(attachedDatabase, alias);
  }
}

class MigrationAuditData extends DataClass
    implements Insertable<MigrationAuditData> {
  final String id;
  final int fromVersion;
  final int toVersion;
  final String startedAt;
  final String? completedAt;
  final String status;
  final String? errorMessage;
  final String? preMigrationBackupPath;
  const MigrationAuditData(
      {required this.id,
      required this.fromVersion,
      required this.toVersion,
      required this.startedAt,
      this.completedAt,
      required this.status,
      this.errorMessage,
      this.preMigrationBackupPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fromVersion'] = Variable<int>(fromVersion);
    map['toVersion'] = Variable<int>(toVersion);
    map['startedAt'] = Variable<String>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completedAt'] = Variable<String>(completedAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['errorMessage'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || preMigrationBackupPath != null) {
      map['preMigrationBackupPath'] = Variable<String>(preMigrationBackupPath);
    }
    return map;
  }

  MigrationAuditCompanion toCompanion(bool nullToAbsent) {
    return MigrationAuditCompanion(
      id: Value(id),
      fromVersion: Value(fromVersion),
      toVersion: Value(toVersion),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      preMigrationBackupPath: preMigrationBackupPath == null && nullToAbsent
          ? const Value.absent()
          : Value(preMigrationBackupPath),
    );
  }

  factory MigrationAuditData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationAuditData(
      id: serializer.fromJson<String>(json['id']),
      fromVersion: serializer.fromJson<int>(json['fromVersion']),
      toVersion: serializer.fromJson<int>(json['toVersion']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      preMigrationBackupPath:
          serializer.fromJson<String?>(json['preMigrationBackupPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromVersion': serializer.toJson<int>(fromVersion),
      'toVersion': serializer.toJson<int>(toVersion),
      'startedAt': serializer.toJson<String>(startedAt),
      'completedAt': serializer.toJson<String?>(completedAt),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'preMigrationBackupPath':
          serializer.toJson<String?>(preMigrationBackupPath),
    };
  }

  MigrationAuditData copyWith(
          {String? id,
          int? fromVersion,
          int? toVersion,
          String? startedAt,
          Value<String?> completedAt = const Value.absent(),
          String? status,
          Value<String?> errorMessage = const Value.absent(),
          Value<String?> preMigrationBackupPath = const Value.absent()}) =>
      MigrationAuditData(
        id: id ?? this.id,
        fromVersion: fromVersion ?? this.fromVersion,
        toVersion: toVersion ?? this.toVersion,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        status: status ?? this.status,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        preMigrationBackupPath: preMigrationBackupPath.present
            ? preMigrationBackupPath.value
            : this.preMigrationBackupPath,
      );
  MigrationAuditData copyWithCompanion(MigrationAuditCompanion data) {
    return MigrationAuditData(
      id: data.id.present ? data.id.value : this.id,
      fromVersion:
          data.fromVersion.present ? data.fromVersion.value : this.fromVersion,
      toVersion: data.toVersion.present ? data.toVersion.value : this.toVersion,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      preMigrationBackupPath: data.preMigrationBackupPath.present
          ? data.preMigrationBackupPath.value
          : this.preMigrationBackupPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationAuditData(')
          ..write('id: $id, ')
          ..write('fromVersion: $fromVersion, ')
          ..write('toVersion: $toVersion, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('preMigrationBackupPath: $preMigrationBackupPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fromVersion, toVersion, startedAt,
      completedAt, status, errorMessage, preMigrationBackupPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationAuditData &&
          other.id == this.id &&
          other.fromVersion == this.fromVersion &&
          other.toVersion == this.toVersion &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.preMigrationBackupPath == this.preMigrationBackupPath);
}

class MigrationAuditCompanion extends UpdateCompanion<MigrationAuditData> {
  final Value<String> id;
  final Value<int> fromVersion;
  final Value<int> toVersion;
  final Value<String> startedAt;
  final Value<String?> completedAt;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<String?> preMigrationBackupPath;
  final Value<int> rowid;
  const MigrationAuditCompanion({
    this.id = const Value.absent(),
    this.fromVersion = const Value.absent(),
    this.toVersion = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.preMigrationBackupPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationAuditCompanion.insert({
    required String id,
    required int fromVersion,
    required int toVersion,
    required String startedAt,
    this.completedAt = const Value.absent(),
    required String status,
    this.errorMessage = const Value.absent(),
    this.preMigrationBackupPath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fromVersion = Value(fromVersion),
        toVersion = Value(toVersion),
        startedAt = Value(startedAt),
        status = Value(status);
  static Insertable<MigrationAuditData> custom({
    Expression<String>? id,
    Expression<int>? fromVersion,
    Expression<int>? toVersion,
    Expression<String>? startedAt,
    Expression<String>? completedAt,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<String>? preMigrationBackupPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromVersion != null) 'fromVersion': fromVersion,
      if (toVersion != null) 'toVersion': toVersion,
      if (startedAt != null) 'startedAt': startedAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (status != null) 'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (preMigrationBackupPath != null)
        'preMigrationBackupPath': preMigrationBackupPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationAuditCompanion copyWith(
      {Value<String>? id,
      Value<int>? fromVersion,
      Value<int>? toVersion,
      Value<String>? startedAt,
      Value<String?>? completedAt,
      Value<String>? status,
      Value<String?>? errorMessage,
      Value<String?>? preMigrationBackupPath,
      Value<int>? rowid}) {
    return MigrationAuditCompanion(
      id: id ?? this.id,
      fromVersion: fromVersion ?? this.fromVersion,
      toVersion: toVersion ?? this.toVersion,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      preMigrationBackupPath:
          preMigrationBackupPath ?? this.preMigrationBackupPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fromVersion.present) {
      map['fromVersion'] = Variable<int>(fromVersion.value);
    }
    if (toVersion.present) {
      map['toVersion'] = Variable<int>(toVersion.value);
    }
    if (startedAt.present) {
      map['startedAt'] = Variable<String>(startedAt.value);
    }
    if (completedAt.present) {
      map['completedAt'] = Variable<String>(completedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['errorMessage'] = Variable<String>(errorMessage.value);
    }
    if (preMigrationBackupPath.present) {
      map['preMigrationBackupPath'] =
          Variable<String>(preMigrationBackupPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationAuditCompanion(')
          ..write('id: $id, ')
          ..write('fromVersion: $fromVersion, ')
          ..write('toVersion: $toVersion, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('preMigrationBackupPath: $preMigrationBackupPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtRecordsTable extends DebtRecords
    with TableInfo<$DebtRecordsTable, DebtRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _personNameMeta =
      const VerificationMeta('personName');
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
      'personName', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _principalAmountMeta =
      const VerificationMeta('principalAmount');
  @override
  late final GeneratedColumn<double> principalAmount = GeneratedColumn<double>(
      'principalAmount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _remainingAmountMeta =
      const VerificationMeta('remainingAmount');
  @override
  late final GeneratedColumn<double> remainingAmount = GeneratedColumn<double>(
      'remainingAmount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
      'dueDate', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _settledAtMeta =
      const VerificationMeta('settledAt');
  @override
  late final GeneratedColumn<String> settledAt = GeneratedColumn<String>(
      'settledAt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        personName,
        type,
        principalAmount,
        remainingAmount,
        currency,
        description,
        createdAt,
        dueDate,
        settledAt,
        status,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_records';
  @override
  VerificationContext validateIntegrity(Insertable<DebtRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('personName')) {
      context.handle(
          _personNameMeta,
          personName.isAcceptableOrUnknown(
              data['personName']!, _personNameMeta));
    } else if (isInserting) {
      context.missing(_personNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('principalAmount')) {
      context.handle(
          _principalAmountMeta,
          principalAmount.isAcceptableOrUnknown(
              data['principalAmount']!, _principalAmountMeta));
    } else if (isInserting) {
      context.missing(_principalAmountMeta);
    }
    if (data.containsKey('remainingAmount')) {
      context.handle(
          _remainingAmountMeta,
          remainingAmount.isAcceptableOrUnknown(
              data['remainingAmount']!, _remainingAmountMeta));
    } else if (isInserting) {
      context.missing(_remainingAmountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('dueDate')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['dueDate']!, _dueDateMeta));
    }
    if (data.containsKey('settledAt')) {
      context.handle(_settledAtMeta,
          settledAt.isAcceptableOrUnknown(data['settledAt']!, _settledAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      personName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}personName'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      principalAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}principalAmount'])!,
      remainingAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}remainingAmount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dueDate']),
      settledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}settledAt']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $DebtRecordsTable createAlias(String alias) {
    return $DebtRecordsTable(attachedDatabase, alias);
  }
}

class DebtRecord extends DataClass implements Insertable<DebtRecord> {
  final String id;
  final String personName;
  final String type;
  final double principalAmount;
  final double remainingAmount;
  final String currency;
  final String? description;
  final String createdAt;
  final String? dueDate;
  final String? settledAt;
  final String status;
  final String? notes;
  const DebtRecord(
      {required this.id,
      required this.personName,
      required this.type,
      required this.principalAmount,
      required this.remainingAmount,
      required this.currency,
      this.description,
      required this.createdAt,
      this.dueDate,
      this.settledAt,
      required this.status,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['personName'] = Variable<String>(personName);
    map['type'] = Variable<String>(type);
    map['principalAmount'] = Variable<double>(principalAmount);
    map['remainingAmount'] = Variable<double>(remainingAmount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['createdAt'] = Variable<String>(createdAt);
    if (!nullToAbsent || dueDate != null) {
      map['dueDate'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || settledAt != null) {
      map['settledAt'] = Variable<String>(settledAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  DebtRecordsCompanion toCompanion(bool nullToAbsent) {
    return DebtRecordsCompanion(
      id: Value(id),
      personName: Value(personName),
      type: Value(type),
      principalAmount: Value(principalAmount),
      remainingAmount: Value(remainingAmount),
      currency: Value(currency),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      settledAt: settledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAt),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory DebtRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtRecord(
      id: serializer.fromJson<String>(json['id']),
      personName: serializer.fromJson<String>(json['personName']),
      type: serializer.fromJson<String>(json['type']),
      principalAmount: serializer.fromJson<double>(json['principalAmount']),
      remainingAmount: serializer.fromJson<double>(json['remainingAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      settledAt: serializer.fromJson<String?>(json['settledAt']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personName': serializer.toJson<String>(personName),
      'type': serializer.toJson<String>(type),
      'principalAmount': serializer.toJson<double>(principalAmount),
      'remainingAmount': serializer.toJson<double>(remainingAmount),
      'currency': serializer.toJson<String>(currency),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<String>(createdAt),
      'dueDate': serializer.toJson<String?>(dueDate),
      'settledAt': serializer.toJson<String?>(settledAt),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  DebtRecord copyWith(
          {String? id,
          String? personName,
          String? type,
          double? principalAmount,
          double? remainingAmount,
          String? currency,
          Value<String?> description = const Value.absent(),
          String? createdAt,
          Value<String?> dueDate = const Value.absent(),
          Value<String?> settledAt = const Value.absent(),
          String? status,
          Value<String?> notes = const Value.absent()}) =>
      DebtRecord(
        id: id ?? this.id,
        personName: personName ?? this.personName,
        type: type ?? this.type,
        principalAmount: principalAmount ?? this.principalAmount,
        remainingAmount: remainingAmount ?? this.remainingAmount,
        currency: currency ?? this.currency,
        description: description.present ? description.value : this.description,
        createdAt: createdAt ?? this.createdAt,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        settledAt: settledAt.present ? settledAt.value : this.settledAt,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
      );
  DebtRecord copyWithCompanion(DebtRecordsCompanion data) {
    return DebtRecord(
      id: data.id.present ? data.id.value : this.id,
      personName:
          data.personName.present ? data.personName.value : this.personName,
      type: data.type.present ? data.type.value : this.type,
      principalAmount: data.principalAmount.present
          ? data.principalAmount.value
          : this.principalAmount,
      remainingAmount: data.remainingAmount.present
          ? data.remainingAmount.value
          : this.remainingAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtRecord(')
          ..write('id: $id, ')
          ..write('personName: $personName, ')
          ..write('type: $type, ')
          ..write('principalAmount: $principalAmount, ')
          ..write('remainingAmount: $remainingAmount, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('settledAt: $settledAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      personName,
      type,
      principalAmount,
      remainingAmount,
      currency,
      description,
      createdAt,
      dueDate,
      settledAt,
      status,
      notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtRecord &&
          other.id == this.id &&
          other.personName == this.personName &&
          other.type == this.type &&
          other.principalAmount == this.principalAmount &&
          other.remainingAmount == this.remainingAmount &&
          other.currency == this.currency &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.dueDate == this.dueDate &&
          other.settledAt == this.settledAt &&
          other.status == this.status &&
          other.notes == this.notes);
}

class DebtRecordsCompanion extends UpdateCompanion<DebtRecord> {
  final Value<String> id;
  final Value<String> personName;
  final Value<String> type;
  final Value<double> principalAmount;
  final Value<double> remainingAmount;
  final Value<String> currency;
  final Value<String?> description;
  final Value<String> createdAt;
  final Value<String?> dueDate;
  final Value<String?> settledAt;
  final Value<String> status;
  final Value<String?> notes;
  final Value<int> rowid;
  const DebtRecordsCompanion({
    this.id = const Value.absent(),
    this.personName = const Value.absent(),
    this.type = const Value.absent(),
    this.principalAmount = const Value.absent(),
    this.remainingAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtRecordsCompanion.insert({
    required String id,
    required String personName,
    required String type,
    required double principalAmount,
    required double remainingAmount,
    required String currency,
    this.description = const Value.absent(),
    required String createdAt,
    this.dueDate = const Value.absent(),
    this.settledAt = const Value.absent(),
    required String status,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        personName = Value(personName),
        type = Value(type),
        principalAmount = Value(principalAmount),
        remainingAmount = Value(remainingAmount),
        currency = Value(currency),
        createdAt = Value(createdAt),
        status = Value(status);
  static Insertable<DebtRecord> custom({
    Expression<String>? id,
    Expression<String>? personName,
    Expression<String>? type,
    Expression<double>? principalAmount,
    Expression<double>? remainingAmount,
    Expression<String>? currency,
    Expression<String>? description,
    Expression<String>? createdAt,
    Expression<String>? dueDate,
    Expression<String>? settledAt,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personName != null) 'personName': personName,
      if (type != null) 'type': type,
      if (principalAmount != null) 'principalAmount': principalAmount,
      if (remainingAmount != null) 'remainingAmount': remainingAmount,
      if (currency != null) 'currency': currency,
      if (description != null) 'description': description,
      if (createdAt != null) 'createdAt': createdAt,
      if (dueDate != null) 'dueDate': dueDate,
      if (settledAt != null) 'settledAt': settledAt,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? personName,
      Value<String>? type,
      Value<double>? principalAmount,
      Value<double>? remainingAmount,
      Value<String>? currency,
      Value<String?>? description,
      Value<String>? createdAt,
      Value<String?>? dueDate,
      Value<String?>? settledAt,
      Value<String>? status,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return DebtRecordsCompanion(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      type: type ?? this.type,
      principalAmount: principalAmount ?? this.principalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      settledAt: settledAt ?? this.settledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personName.present) {
      map['personName'] = Variable<String>(personName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (principalAmount.present) {
      map['principalAmount'] = Variable<double>(principalAmount.value);
    }
    if (remainingAmount.present) {
      map['remainingAmount'] = Variable<double>(remainingAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (dueDate.present) {
      map['dueDate'] = Variable<String>(dueDate.value);
    }
    if (settledAt.present) {
      map['settledAt'] = Variable<String>(settledAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtRecordsCompanion(')
          ..write('id: $id, ')
          ..write('personName: $personName, ')
          ..write('type: $type, ')
          ..write('principalAmount: $principalAmount, ')
          ..write('remainingAmount: $remainingAmount, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('settledAt: $settledAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtRepaymentsTable extends DebtRepayments
    with TableInfo<$DebtRepaymentsTable, DebtRepayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtRepaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<String> debtId = GeneratedColumn<String>(
      'debtId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES debt_records (id) ON DELETE CASCADE'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, debtId, amount, createdAt, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_repayments';
  @override
  VerificationContext validateIntegrity(Insertable<DebtRepayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('debtId')) {
      context.handle(_debtIdMeta,
          debtId.isAcceptableOrUnknown(data['debtId']!, _debtIdMeta));
    } else if (isInserting) {
      context.missing(_debtIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtRepayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtRepayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      debtId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}debtId'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $DebtRepaymentsTable createAlias(String alias) {
    return $DebtRepaymentsTable(attachedDatabase, alias);
  }
}

class DebtRepayment extends DataClass implements Insertable<DebtRepayment> {
  final String id;
  final String debtId;
  final double amount;
  final String createdAt;
  final String? notes;
  const DebtRepayment(
      {required this.id,
      required this.debtId,
      required this.amount,
      required this.createdAt,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['debtId'] = Variable<String>(debtId);
    map['amount'] = Variable<double>(amount);
    map['createdAt'] = Variable<String>(createdAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  DebtRepaymentsCompanion toCompanion(bool nullToAbsent) {
    return DebtRepaymentsCompanion(
      id: Value(id),
      debtId: Value(debtId),
      amount: Value(amount),
      createdAt: Value(createdAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory DebtRepayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtRepayment(
      id: serializer.fromJson<String>(json['id']),
      debtId: serializer.fromJson<String>(json['debtId']),
      amount: serializer.fromJson<double>(json['amount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'debtId': serializer.toJson<String>(debtId),
      'amount': serializer.toJson<double>(amount),
      'createdAt': serializer.toJson<String>(createdAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  DebtRepayment copyWith(
          {String? id,
          String? debtId,
          double? amount,
          String? createdAt,
          Value<String?> notes = const Value.absent()}) =>
      DebtRepayment(
        id: id ?? this.id,
        debtId: debtId ?? this.debtId,
        amount: amount ?? this.amount,
        createdAt: createdAt ?? this.createdAt,
        notes: notes.present ? notes.value : this.notes,
      );
  DebtRepayment copyWithCompanion(DebtRepaymentsCompanion data) {
    return DebtRepayment(
      id: data.id.present ? data.id.value : this.id,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      amount: data.amount.present ? data.amount.value : this.amount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtRepayment(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, debtId, amount, createdAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtRepayment &&
          other.id == this.id &&
          other.debtId == this.debtId &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt &&
          other.notes == this.notes);
}

class DebtRepaymentsCompanion extends UpdateCompanion<DebtRepayment> {
  final Value<String> id;
  final Value<String> debtId;
  final Value<double> amount;
  final Value<String> createdAt;
  final Value<String?> notes;
  final Value<int> rowid;
  const DebtRepaymentsCompanion({
    this.id = const Value.absent(),
    this.debtId = const Value.absent(),
    this.amount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtRepaymentsCompanion.insert({
    required String id,
    required String debtId,
    required double amount,
    required String createdAt,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        debtId = Value(debtId),
        amount = Value(amount),
        createdAt = Value(createdAt);
  static Insertable<DebtRepayment> custom({
    Expression<String>? id,
    Expression<String>? debtId,
    Expression<double>? amount,
    Expression<String>? createdAt,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debtId != null) 'debtId': debtId,
      if (amount != null) 'amount': amount,
      if (createdAt != null) 'createdAt': createdAt,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtRepaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? debtId,
      Value<double>? amount,
      Value<String>? createdAt,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return DebtRepaymentsCompanion(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (debtId.present) {
      map['debtId'] = Variable<String>(debtId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtRepaymentsCompanion(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroceryTemplatesTable extends GroceryTemplates
    with TableInfo<$GroceryTemplatesTable, GroceryTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroceryTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<String> items = GeneratedColumn<String>(
      'items', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'createdAt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, items, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grocery_templates';
  @override
  VerificationContext validateIntegrity(Insertable<GroceryTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('items')) {
      context.handle(
          _itemsMeta, items.isAcceptableOrUnknown(data['items']!, _itemsMeta));
    } else if (isInserting) {
      context.missing(_itemsMeta);
    }
    if (data.containsKey('createdAt')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroceryTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroceryTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      items: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}items'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createdAt'])!,
    );
  }

  @override
  $GroceryTemplatesTable createAlias(String alias) {
    return $GroceryTemplatesTable(attachedDatabase, alias);
  }
}

class GroceryTemplate extends DataClass implements Insertable<GroceryTemplate> {
  final String id;
  final String name;
  final String items;
  final String createdAt;
  const GroceryTemplate(
      {required this.id,
      required this.name,
      required this.items,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['items'] = Variable<String>(items);
    map['createdAt'] = Variable<String>(createdAt);
    return map;
  }

  GroceryTemplatesCompanion toCompanion(bool nullToAbsent) {
    return GroceryTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      items: Value(items),
      createdAt: Value(createdAt),
    );
  }

  factory GroceryTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroceryTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      items: serializer.fromJson<String>(json['items']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'items': serializer.toJson<String>(items),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  GroceryTemplate copyWith(
          {String? id, String? name, String? items, String? createdAt}) =>
      GroceryTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        items: items ?? this.items,
        createdAt: createdAt ?? this.createdAt,
      );
  GroceryTemplate copyWithCompanion(GroceryTemplatesCompanion data) {
    return GroceryTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      items: data.items.present ? data.items.value : this.items,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroceryTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('items: $items, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, items, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroceryTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.items == this.items &&
          other.createdAt == this.createdAt);
}

class GroceryTemplatesCompanion extends UpdateCompanion<GroceryTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> items;
  final Value<String> createdAt;
  final Value<int> rowid;
  const GroceryTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.items = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroceryTemplatesCompanion.insert({
    required String id,
    required String name,
    required String items,
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        items = Value(items),
        createdAt = Value(createdAt);
  static Insertable<GroceryTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? items,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (items != null) 'items': items,
      if (createdAt != null) 'createdAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroceryTemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? items,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return GroceryTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
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
    if (items.present) {
      map['items'] = Variable<String>(items.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroceryTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('items: $items, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WalletMeltDatabase extends GeneratedDatabase {
  _$WalletMeltDatabase(QueryExecutor e) : super(e);
  $WalletMeltDatabaseManager get managers => $WalletMeltDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $StoresTable stores = $StoresTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $GroceryItemsTable groceryItems = $GroceryItemsTable(this);
  late final $CategoryBudgetsTable categoryBudgets =
      $CategoryBudgetsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ItemAliasesTable itemAliases = $ItemAliasesTable(this);
  late final $ExpenseItemsTable expenseItems = $ExpenseItemsTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $MigrationAuditTable migrationAudit = $MigrationAuditTable(this);
  late final $DebtRecordsTable debtRecords = $DebtRecordsTable(this);
  late final $DebtRepaymentsTable debtRepayments = $DebtRepaymentsTable(this);
  late final $GroceryTemplatesTable groceryTemplates =
      $GroceryTemplatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        categories,
        stores,
        expenses,
        groceryItems,
        categoryBudgets,
        syncMetadata,
        units,
        items,
        itemAliases,
        expenseItems,
        receipts,
        migrationAudit,
        debtRecords,
        debtRepayments,
        groceryTemplates
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('expenses',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('grocery_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('items',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('item_aliases', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('expenses',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('expense_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('expenses',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('receipts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('debt_records',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('debt_repayments', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required String icon,
  required String color,
  required bool isDefault,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> icon,
  Value<String> color,
  Value<bool> isDefault,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$WalletMeltDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
          _$WalletMeltDatabase db) =>
      MultiTypedResultKey.fromTable(db.expenses,
          aliasName: 'categories__id__expenses__categoryId');

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CategoryBudgetsTable, List<CategoryBudget>>
      _categoryBudgetsRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.categoryBudgets,
              aliasName: 'categories__id__category_budgets__categoryId');

  $$CategoryBudgetsTableProcessedTableManager get categoryBudgetsRefs {
    final manager = $$CategoryBudgetsTableTableManager(
            $_db, $_db.categoryBudgets)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_categoryBudgetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
          _$WalletMeltDatabase db) =>
      MultiTypedResultKey.fromTable(db.items,
          aliasName: 'categories__id__items__categoryId');

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager($_db, $_db.items)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExpenseItemsTable, List<ExpenseItem>>
      _expenseItemsRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.expenseItems,
              aliasName: 'categories__id__expense_items__categoryId');

  $$ExpenseItemsTableProcessedTableManager get expenseItemsRefs {
    final manager = $$ExpenseItemsTableTableManager($_db, $_db.expenseItems)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> expensesRefs(
      Expression<bool> Function($$ExpensesTableFilterComposer f) f) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> categoryBudgetsRefs(
      Expression<bool> Function($$CategoryBudgetsTableFilterComposer f) f) {
    final $$CategoryBudgetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categoryBudgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoryBudgetsTableFilterComposer(
              $db: $db,
              $table: $db.categoryBudgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> itemsRefs(
      Expression<bool> Function($$ItemsTableFilterComposer f) f) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableFilterComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> expenseItemsRefs(
      Expression<bool> Function($$ExpenseItemsTableFilterComposer f) f) {
    final $$ExpenseItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableFilterComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> expensesRefs<T extends Object>(
      Expression<T> Function($$ExpensesTableAnnotationComposer a) f) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> categoryBudgetsRefs<T extends Object>(
      Expression<T> Function($$CategoryBudgetsTableAnnotationComposer a) f) {
    final $$CategoryBudgetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categoryBudgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoryBudgetsTableAnnotationComposer(
              $db: $db,
              $table: $db.categoryBudgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> itemsRefs<T extends Object>(
      Expression<T> Function($$ItemsTableAnnotationComposer a) f) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> expenseItemsRefs<T extends Object>(
      Expression<T> Function($$ExpenseItemsTableAnnotationComposer a) f) {
    final $$ExpenseItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool expensesRefs,
        bool categoryBudgetsRefs,
        bool itemsRefs,
        bool expenseItemsRefs})> {
  $$CategoriesTableTableManager(_$WalletMeltDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            icon: icon,
            color: color,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String icon,
            required String color,
            required bool isDefault,
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            color: color,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {expensesRefs = false,
              categoryBudgetsRefs = false,
              itemsRefs = false,
              expenseItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (expensesRefs) db.expenses,
                if (categoryBudgetsRefs) db.categoryBudgets,
                if (itemsRefs) db.items,
                if (expenseItemsRefs) db.expenseItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (expensesRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Expense>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._expensesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .expensesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (categoryBudgetsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            CategoryBudget>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._categoryBudgetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .categoryBudgetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (itemsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable, Item>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._itemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .itemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (expenseItemsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            ExpenseItem>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._expenseItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .expenseItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool expensesRefs,
        bool categoryBudgetsRefs,
        bool itemsRefs,
        bool expenseItemsRefs})>;
typedef $$StoresTableCreateCompanionBuilder = StoresCompanion Function({
  required String id,
  required String name,
  required String normalizedName,
  Value<String?> notes,
  required String createdAt,
  required String updatedAt,
  Value<String?> archivedAt,
  Value<int> rowid,
});
typedef $$StoresTableUpdateCompanionBuilder = StoresCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> normalizedName,
  Value<String?> notes,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> archivedAt,
  Value<int> rowid,
});

final class $$StoresTableReferences
    extends BaseReferences<_$WalletMeltDatabase, $StoresTable, Store> {
  $$StoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
          _$WalletMeltDatabase db) =>
      MultiTypedResultKey.fromTable(db.expenses,
          aliasName: 'stores__id__expenses__storeId');

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.storeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExpenseItemsTable, List<ExpenseItem>>
      _expenseItemsRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.expenseItems,
              aliasName: 'stores__id__expense_items__storeId');

  $$ExpenseItemsTableProcessedTableManager get expenseItemsRefs {
    final manager = $$ExpenseItemsTableTableManager($_db, $_db.expenseItems)
        .filter((f) => f.storeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StoresTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $StoresTable> {
  $$StoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> expensesRefs(
      Expression<bool> Function($$ExpensesTableFilterComposer f) f) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.storeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> expenseItemsRefs(
      Expression<bool> Function($$ExpenseItemsTableFilterComposer f) f) {
    final $$ExpenseItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.storeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableFilterComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StoresTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $StoresTable> {
  $$StoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));
}

class $$StoresTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $StoresTable> {
  $$StoresTableAnnotationComposer({
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

  GeneratedColumn<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  Expression<T> expensesRefs<T extends Object>(
      Expression<T> Function($$ExpensesTableAnnotationComposer a) f) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.storeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> expenseItemsRefs<T extends Object>(
      Expression<T> Function($$ExpenseItemsTableAnnotationComposer a) f) {
    final $$ExpenseItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.storeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StoresTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $StoresTable,
    Store,
    $$StoresTableFilterComposer,
    $$StoresTableOrderingComposer,
    $$StoresTableAnnotationComposer,
    $$StoresTableCreateCompanionBuilder,
    $$StoresTableUpdateCompanionBuilder,
    (Store, $$StoresTableReferences),
    Store,
    PrefetchHooks Function({bool expensesRefs, bool expenseItemsRefs})> {
  $$StoresTableTableManager(_$WalletMeltDatabase db, $StoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> normalizedName = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoresCompanion(
            id: id,
            name: name,
            normalizedName: normalizedName,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String normalizedName,
            Value<String?> notes = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoresCompanion.insert(
            id: id,
            name: name,
            normalizedName: normalizedName,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$StoresTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {expensesRefs = false, expenseItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (expensesRefs) db.expenses,
                if (expenseItemsRefs) db.expenseItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (expensesRefs)
                    await $_getPrefetchedData<Store, $StoresTable, Expense>(
                        currentTable: table,
                        referencedTable:
                            $$StoresTableReferences._expensesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StoresTableReferences(db, table, p0).expensesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.storeId == item.id),
                        typedResults: items),
                  if (expenseItemsRefs)
                    await $_getPrefetchedData<Store, $StoresTable, ExpenseItem>(
                        currentTable: table,
                        referencedTable:
                            $$StoresTableReferences._expenseItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StoresTableReferences(db, table, p0)
                                .expenseItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.storeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$StoresTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $StoresTable,
    Store,
    $$StoresTableFilterComposer,
    $$StoresTableOrderingComposer,
    $$StoresTableAnnotationComposer,
    $$StoresTableCreateCompanionBuilder,
    $$StoresTableUpdateCompanionBuilder,
    (Store, $$StoresTableReferences),
    Store,
    PrefetchHooks Function({bool expensesRefs, bool expenseItemsRefs})>;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required double amount,
  required String currency,
  required String categoryId,
  required String title,
  Value<String?> vendor,
  Value<String?> storeId,
  required String date,
  Value<String?> notes,
  Value<String?> receiptImageUri,
  Value<bool> isRecurring,
  Value<String?> recurrenceFrequency,
  Value<String?> itemizationStatus,
  Value<bool> itemTotalMismatchApproved,
  required String createdAt,
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<double> amount,
  Value<String> currency,
  Value<String> categoryId,
  Value<String> title,
  Value<String?> vendor,
  Value<String?> storeId,
  Value<String> date,
  Value<String?> notes,
  Value<String?> receiptImageUri,
  Value<bool> isRecurring,
  Value<String?> recurrenceFrequency,
  Value<String?> itemizationStatus,
  Value<bool> itemTotalMismatchApproved,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$WalletMeltDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$WalletMeltDatabase db) =>
      db.categories.createAlias('expenses__categoryId__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('categoryId')!;

    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $StoresTable _storeIdTable(_$WalletMeltDatabase db) =>
      db.stores.createAlias('expenses__storeId__stores__id');

  $$StoresTableProcessedTableManager? get storeId {
    final $_column = $_itemColumn<String>('storeId');
    if ($_column == null) return null;
    final manager = $$StoresTableTableManager($_db, $_db.stores)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$GroceryItemsTable, List<GroceryItem>>
      _groceryItemsRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.groceryItems,
              aliasName: 'expenses__id__grocery_items__expenseId');

  $$GroceryItemsTableProcessedTableManager get groceryItemsRefs {
    final manager = $$GroceryItemsTableTableManager($_db, $_db.groceryItems)
        .filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groceryItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExpenseItemsTable, List<ExpenseItem>>
      _expenseItemsRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.expenseItems,
              aliasName: 'expenses__id__expense_items__expenseId');

  $$ExpenseItemsTableProcessedTableManager get expenseItemsRefs {
    final manager = $$ExpenseItemsTableTableManager($_db, $_db.expenseItems)
        .filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReceiptsTable, List<Receipt>> _receiptsRefsTable(
          _$WalletMeltDatabase db) =>
      MultiTypedResultKey.fromTable(db.receipts,
          aliasName: 'expenses__id__receipts__expenseId');

  $$ReceiptsTableProcessedTableManager get receiptsRefs {
    final manager = $$ReceiptsTableTableManager($_db, $_db.receipts)
        .filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vendor => $composableBuilder(
      column: $table.vendor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptImageUri => $composableBuilder(
      column: $table.receiptImageUri,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrenceFrequency => $composableBuilder(
      column: $table.recurrenceFrequency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemizationStatus => $composableBuilder(
      column: $table.itemizationStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get itemTotalMismatchApproved => $composableBuilder(
      column: $table.itemTotalMismatchApproved,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StoresTableFilterComposer get storeId {
    final $$StoresTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableFilterComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> groceryItemsRefs(
      Expression<bool> Function($$GroceryItemsTableFilterComposer f) f) {
    final $$GroceryItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groceryItems,
        getReferencedColumn: (t) => t.expenseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroceryItemsTableFilterComposer(
              $db: $db,
              $table: $db.groceryItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> expenseItemsRefs(
      Expression<bool> Function($$ExpenseItemsTableFilterComposer f) f) {
    final $$ExpenseItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.expenseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableFilterComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> receiptsRefs(
      Expression<bool> Function($$ReceiptsTableFilterComposer f) f) {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.receipts,
        getReferencedColumn: (t) => t.expenseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReceiptsTableFilterComposer(
              $db: $db,
              $table: $db.receipts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vendor => $composableBuilder(
      column: $table.vendor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptImageUri => $composableBuilder(
      column: $table.receiptImageUri,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrenceFrequency => $composableBuilder(
      column: $table.recurrenceFrequency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemizationStatus => $composableBuilder(
      column: $table.itemizationStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get itemTotalMismatchApproved => $composableBuilder(
      column: $table.itemTotalMismatchApproved,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StoresTableOrderingComposer get storeId {
    final $$StoresTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableOrderingComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get receiptImageUri => $composableBuilder(
      column: $table.receiptImageUri, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => column);

  GeneratedColumn<String> get recurrenceFrequency => $composableBuilder(
      column: $table.recurrenceFrequency, builder: (column) => column);

  GeneratedColumn<String> get itemizationStatus => $composableBuilder(
      column: $table.itemizationStatus, builder: (column) => column);

  GeneratedColumn<bool> get itemTotalMismatchApproved => $composableBuilder(
      column: $table.itemTotalMismatchApproved, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StoresTableAnnotationComposer get storeId {
    final $$StoresTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableAnnotationComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> groceryItemsRefs<T extends Object>(
      Expression<T> Function($$GroceryItemsTableAnnotationComposer a) f) {
    final $$GroceryItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groceryItems,
        getReferencedColumn: (t) => t.expenseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroceryItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.groceryItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> expenseItemsRefs<T extends Object>(
      Expression<T> Function($$ExpenseItemsTableAnnotationComposer a) f) {
    final $$ExpenseItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.expenseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> receiptsRefs<T extends Object>(
      Expression<T> Function($$ReceiptsTableAnnotationComposer a) f) {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.receipts,
        getReferencedColumn: (t) => t.expenseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReceiptsTableAnnotationComposer(
              $db: $db,
              $table: $db.receipts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExpensesTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, $$ExpensesTableReferences),
    Expense,
    PrefetchHooks Function(
        {bool categoryId,
        bool storeId,
        bool groceryItemsRefs,
        bool expenseItemsRefs,
        bool receiptsRefs})> {
  $$ExpensesTableTableManager(_$WalletMeltDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> vendor = const Value.absent(),
            Value<String?> storeId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> receiptImageUri = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<String?> recurrenceFrequency = const Value.absent(),
            Value<String?> itemizationStatus = const Value.absent(),
            Value<bool> itemTotalMismatchApproved = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            amount: amount,
            currency: currency,
            categoryId: categoryId,
            title: title,
            vendor: vendor,
            storeId: storeId,
            date: date,
            notes: notes,
            receiptImageUri: receiptImageUri,
            isRecurring: isRecurring,
            recurrenceFrequency: recurrenceFrequency,
            itemizationStatus: itemizationStatus,
            itemTotalMismatchApproved: itemTotalMismatchApproved,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required double amount,
            required String currency,
            required String categoryId,
            required String title,
            Value<String?> vendor = const Value.absent(),
            Value<String?> storeId = const Value.absent(),
            required String date,
            Value<String?> notes = const Value.absent(),
            Value<String?> receiptImageUri = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<String?> recurrenceFrequency = const Value.absent(),
            Value<String?> itemizationStatus = const Value.absent(),
            Value<bool> itemTotalMismatchApproved = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            amount: amount,
            currency: currency,
            categoryId: categoryId,
            title: title,
            vendor: vendor,
            storeId: storeId,
            date: date,
            notes: notes,
            receiptImageUri: receiptImageUri,
            isRecurring: isRecurring,
            recurrenceFrequency: recurrenceFrequency,
            itemizationStatus: itemizationStatus,
            itemTotalMismatchApproved: itemTotalMismatchApproved,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ExpensesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false,
              storeId = false,
              groceryItemsRefs = false,
              expenseItemsRefs = false,
              receiptsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (groceryItemsRefs) db.groceryItems,
                if (expenseItemsRefs) db.expenseItems,
                if (receiptsRefs) db.receipts
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$ExpensesTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$ExpensesTableReferences._categoryIdTable(db).id,
                  ) as T;
                }
                if (storeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.storeId,
                    referencedTable:
                        $$ExpensesTableReferences._storeIdTable(db),
                    referencedColumn:
                        $$ExpensesTableReferences._storeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groceryItemsRefs)
                    await $_getPrefetchedData<Expense, $ExpensesTable,
                            GroceryItem>(
                        currentTable: table,
                        referencedTable: $$ExpensesTableReferences
                            ._groceryItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExpensesTableReferences(db, table, p0)
                                .groceryItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.expenseId == item.id),
                        typedResults: items),
                  if (expenseItemsRefs)
                    await $_getPrefetchedData<Expense, $ExpensesTable,
                            ExpenseItem>(
                        currentTable: table,
                        referencedTable: $$ExpensesTableReferences
                            ._expenseItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExpensesTableReferences(db, table, p0)
                                .expenseItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.expenseId == item.id),
                        typedResults: items),
                  if (receiptsRefs)
                    await $_getPrefetchedData<Expense, $ExpensesTable, Receipt>(
                        currentTable: table,
                        referencedTable:
                            $$ExpensesTableReferences._receiptsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExpensesTableReferences(db, table, p0)
                                .receiptsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.expenseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExpensesTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, $$ExpensesTableReferences),
    Expense,
    PrefetchHooks Function(
        {bool categoryId,
        bool storeId,
        bool groceryItemsRefs,
        bool expenseItemsRefs,
        bool receiptsRefs})>;
typedef $$GroceryItemsTableCreateCompanionBuilder = GroceryItemsCompanion
    Function({
  required String id,
  required String expenseId,
  required String name,
  required double amount,
  required String createdAt,
  Value<int> rowid,
});
typedef $$GroceryItemsTableUpdateCompanionBuilder = GroceryItemsCompanion
    Function({
  Value<String> id,
  Value<String> expenseId,
  Value<String> name,
  Value<double> amount,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $$GroceryItemsTableReferences extends BaseReferences<
    _$WalletMeltDatabase, $GroceryItemsTable, GroceryItem> {
  $$GroceryItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExpensesTable _expenseIdTable(_$WalletMeltDatabase db) =>
      db.expenses.createAlias('grocery_items__expenseId__expenses__id');

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expenseId')!;

    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GroceryItemsTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $GroceryItemsTable> {
  $$GroceryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroceryItemsTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $GroceryItemsTable> {
  $$GroceryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableOrderingComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroceryItemsTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $GroceryItemsTable> {
  $$GroceryItemsTableAnnotationComposer({
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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroceryItemsTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $GroceryItemsTable,
    GroceryItem,
    $$GroceryItemsTableFilterComposer,
    $$GroceryItemsTableOrderingComposer,
    $$GroceryItemsTableAnnotationComposer,
    $$GroceryItemsTableCreateCompanionBuilder,
    $$GroceryItemsTableUpdateCompanionBuilder,
    (GroceryItem, $$GroceryItemsTableReferences),
    GroceryItem,
    PrefetchHooks Function({bool expenseId})> {
  $$GroceryItemsTableTableManager(
      _$WalletMeltDatabase db, $GroceryItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroceryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroceryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroceryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> expenseId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroceryItemsCompanion(
            id: id,
            expenseId: expenseId,
            name: name,
            amount: amount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String expenseId,
            required String name,
            required double amount,
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GroceryItemsCompanion.insert(
            id: id,
            expenseId: expenseId,
            name: name,
            amount: amount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GroceryItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({expenseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (expenseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.expenseId,
                    referencedTable:
                        $$GroceryItemsTableReferences._expenseIdTable(db),
                    referencedColumn:
                        $$GroceryItemsTableReferences._expenseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GroceryItemsTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $GroceryItemsTable,
    GroceryItem,
    $$GroceryItemsTableFilterComposer,
    $$GroceryItemsTableOrderingComposer,
    $$GroceryItemsTableAnnotationComposer,
    $$GroceryItemsTableCreateCompanionBuilder,
    $$GroceryItemsTableUpdateCompanionBuilder,
    (GroceryItem, $$GroceryItemsTableReferences),
    GroceryItem,
    PrefetchHooks Function({bool expenseId})>;
typedef $$CategoryBudgetsTableCreateCompanionBuilder = CategoryBudgetsCompanion
    Function({
  required String id,
  required String categoryId,
  required double amount,
  required String currency,
  required String month,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$CategoryBudgetsTableUpdateCompanionBuilder = CategoryBudgetsCompanion
    Function({
  Value<String> id,
  Value<String> categoryId,
  Value<double> amount,
  Value<String> currency,
  Value<String> month,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$CategoryBudgetsTableReferences extends BaseReferences<
    _$WalletMeltDatabase, $CategoryBudgetsTable, CategoryBudget> {
  $$CategoryBudgetsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$WalletMeltDatabase db) =>
      db.categories.createAlias('category_budgets__categoryId__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('categoryId')!;

    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CategoryBudgetsTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoryBudgetsTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoryBudgetsTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoryBudgetsTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $CategoryBudgetsTable,
    CategoryBudget,
    $$CategoryBudgetsTableFilterComposer,
    $$CategoryBudgetsTableOrderingComposer,
    $$CategoryBudgetsTableAnnotationComposer,
    $$CategoryBudgetsTableCreateCompanionBuilder,
    $$CategoryBudgetsTableUpdateCompanionBuilder,
    (CategoryBudget, $$CategoryBudgetsTableReferences),
    CategoryBudget,
    PrefetchHooks Function({bool categoryId})> {
  $$CategoryBudgetsTableTableManager(
      _$WalletMeltDatabase db, $CategoryBudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> month = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryBudgetsCompanion(
            id: id,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            month: month,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String categoryId,
            required double amount,
            required String currency,
            required String month,
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryBudgetsCompanion.insert(
            id: id,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            month: month,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoryBudgetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$CategoryBudgetsTableReferences._categoryIdTable(db),
                    referencedColumn: $$CategoryBudgetsTableReferences
                        ._categoryIdTable(db)
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
        ));
}

typedef $$CategoryBudgetsTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $CategoryBudgetsTable,
    CategoryBudget,
    $$CategoryBudgetsTableFilterComposer,
    $$CategoryBudgetsTableOrderingComposer,
    $$CategoryBudgetsTableAnnotationComposer,
    $$CategoryBudgetsTableCreateCompanionBuilder,
    $$CategoryBudgetsTableUpdateCompanionBuilder,
    (CategoryBudget, $$CategoryBudgetsTableReferences),
    CategoryBudget,
    PrefetchHooks Function({bool categoryId})>;
typedef $$SyncMetadataTableCreateCompanionBuilder = SyncMetadataCompanion
    Function({
  required String entityType,
  required String entityId,
  Value<int> localVersion,
  Value<String?> remoteId,
  Value<String?> lastSyncedAt,
  Value<String> syncState,
  Value<int> rowid,
});
typedef $$SyncMetadataTableUpdateCompanionBuilder = SyncMetadataCompanion
    Function({
  Value<String> entityType,
  Value<String> entityId,
  Value<int> localVersion,
  Value<String?> remoteId,
  Value<String?> lastSyncedAt,
  Value<String> syncState,
  Value<int> rowid,
});

class $$SyncMetadataTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get localVersion => $composableBuilder(
      column: $table.localVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get localVersion => $composableBuilder(
      column: $table.localVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get localVersion => $composableBuilder(
      column: $table.localVersion, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$SyncMetadataTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $SyncMetadataTable,
    SyncMetadataData,
    $$SyncMetadataTableFilterComposer,
    $$SyncMetadataTableOrderingComposer,
    $$SyncMetadataTableAnnotationComposer,
    $$SyncMetadataTableCreateCompanionBuilder,
    $$SyncMetadataTableUpdateCompanionBuilder,
    (
      SyncMetadataData,
      BaseReferences<_$WalletMeltDatabase, $SyncMetadataTable, SyncMetadataData>
    ),
    SyncMetadataData,
    PrefetchHooks Function()> {
  $$SyncMetadataTableTableManager(
      _$WalletMeltDatabase db, $SyncMetadataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<int> localVersion = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<String?> lastSyncedAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetadataCompanion(
            entityType: entityType,
            entityId: entityId,
            localVersion: localVersion,
            remoteId: remoteId,
            lastSyncedAt: lastSyncedAt,
            syncState: syncState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entityType,
            required String entityId,
            Value<int> localVersion = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<String?> lastSyncedAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetadataCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            localVersion: localVersion,
            remoteId: remoteId,
            lastSyncedAt: lastSyncedAt,
            syncState: syncState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetadataTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $SyncMetadataTable,
    SyncMetadataData,
    $$SyncMetadataTableFilterComposer,
    $$SyncMetadataTableOrderingComposer,
    $$SyncMetadataTableAnnotationComposer,
    $$SyncMetadataTableCreateCompanionBuilder,
    $$SyncMetadataTableUpdateCompanionBuilder,
    (
      SyncMetadataData,
      BaseReferences<_$WalletMeltDatabase, $SyncMetadataTable, SyncMetadataData>
    ),
    SyncMetadataData,
    PrefetchHooks Function()>;
typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  required String id,
  required String name,
  required String abbreviation,
  required String dimension,
  Value<String?> baseUnitId,
  Value<double?> factorToBase,
  Value<bool> isDefault,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> abbreviation,
  Value<String> dimension,
  Value<String?> baseUnitId,
  Value<double?> factorToBase,
  Value<bool> isDefault,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$UnitsTableReferences
    extends BaseReferences<_$WalletMeltDatabase, $UnitsTable, Unit> {
  $$UnitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UnitsTable _baseUnitIdTable(_$WalletMeltDatabase db) =>
      db.units.createAlias('units__baseUnitId__units__id');

  $$UnitsTableProcessedTableManager? get baseUnitId {
    final $_column = $_itemColumn<String>('baseUnitId');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
          _$WalletMeltDatabase db) =>
      MultiTypedResultKey.fromTable(db.items,
          aliasName: 'units__id__items__defaultUnitId');

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager($_db, $_db.items).filter(
        (f) => f.defaultUnitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExpenseItemsTable, List<ExpenseItem>>
      _expenseItemsRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.expenseItems,
              aliasName: 'units__id__expense_items__unitId');

  $$ExpenseItemsTableProcessedTableManager get expenseItemsRefs {
    final manager = $$ExpenseItemsTableTableManager($_db, $_db.expenseItems)
        .filter((f) => f.unitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UnitsTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get abbreviation => $composableBuilder(
      column: $table.abbreviation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dimension => $composableBuilder(
      column: $table.dimension, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get factorToBase => $composableBuilder(
      column: $table.factorToBase, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$UnitsTableFilterComposer get baseUnitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> itemsRefs(
      Expression<bool> Function($$ItemsTableFilterComposer f) f) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.defaultUnitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableFilterComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> expenseItemsRefs(
      Expression<bool> Function($$ExpenseItemsTableFilterComposer f) f) {
    final $$ExpenseItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableFilterComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get abbreviation => $composableBuilder(
      column: $table.abbreviation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dimension => $composableBuilder(
      column: $table.dimension, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get factorToBase => $composableBuilder(
      column: $table.factorToBase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$UnitsTableOrderingComposer get baseUnitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
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

  GeneratedColumn<String> get abbreviation => $composableBuilder(
      column: $table.abbreviation, builder: (column) => column);

  GeneratedColumn<String> get dimension =>
      $composableBuilder(column: $table.dimension, builder: (column) => column);

  GeneratedColumn<double> get factorToBase => $composableBuilder(
      column: $table.factorToBase, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UnitsTableAnnotationComposer get baseUnitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> itemsRefs<T extends Object>(
      Expression<T> Function($$ItemsTableAnnotationComposer a) f) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.defaultUnitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> expenseItemsRefs<T extends Object>(
      Expression<T> Function($$ExpenseItemsTableAnnotationComposer a) f) {
    final $$ExpenseItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $UnitsTable,
    Unit,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (Unit, $$UnitsTableReferences),
    Unit,
    PrefetchHooks Function(
        {bool baseUnitId, bool itemsRefs, bool expenseItemsRefs})> {
  $$UnitsTableTableManager(_$WalletMeltDatabase db, $UnitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> abbreviation = const Value.absent(),
            Value<String> dimension = const Value.absent(),
            Value<String?> baseUnitId = const Value.absent(),
            Value<double?> factorToBase = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitsCompanion(
            id: id,
            name: name,
            abbreviation: abbreviation,
            dimension: dimension,
            baseUnitId: baseUnitId,
            factorToBase: factorToBase,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String abbreviation,
            required String dimension,
            Value<String?> baseUnitId = const Value.absent(),
            Value<double?> factorToBase = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitsCompanion.insert(
            id: id,
            name: name,
            abbreviation: abbreviation,
            dimension: dimension,
            baseUnitId: baseUnitId,
            factorToBase: factorToBase,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UnitsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {baseUnitId = false,
              itemsRefs = false,
              expenseItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (itemsRefs) db.items,
                if (expenseItemsRefs) db.expenseItems
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (baseUnitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.baseUnitId,
                    referencedTable:
                        $$UnitsTableReferences._baseUnitIdTable(db),
                    referencedColumn:
                        $$UnitsTableReferences._baseUnitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemsRefs)
                    await $_getPrefetchedData<Unit, $UnitsTable, Item>(
                        currentTable: table,
                        referencedTable:
                            $$UnitsTableReferences._itemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0).itemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.defaultUnitId == item.id),
                        typedResults: items),
                  if (expenseItemsRefs)
                    await $_getPrefetchedData<Unit, $UnitsTable, ExpenseItem>(
                        currentTable: table,
                        referencedTable:
                            $$UnitsTableReferences._expenseItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0)
                                .expenseItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UnitsTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $UnitsTable,
    Unit,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (Unit, $$UnitsTableReferences),
    Unit,
    PrefetchHooks Function(
        {bool baseUnitId, bool itemsRefs, bool expenseItemsRefs})>;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  required String id,
  required String name,
  required String normalizedName,
  Value<String?> defaultUnitId,
  Value<String?> categoryId,
  required String createdAt,
  required String updatedAt,
  Value<String?> archivedAt,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> normalizedName,
  Value<String?> defaultUnitId,
  Value<String?> categoryId,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> archivedAt,
  Value<int> rowid,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$WalletMeltDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UnitsTable _defaultUnitIdTable(_$WalletMeltDatabase db) =>
      db.units.createAlias('items__defaultUnitId__units__id');

  $$UnitsTableProcessedTableManager? get defaultUnitId {
    final $_column = $_itemColumn<String>('defaultUnitId');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_defaultUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$WalletMeltDatabase db) =>
      db.categories.createAlias('items__categoryId__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('categoryId');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ItemAliasesTable, List<ItemAliase>>
      _itemAliasesRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.itemAliases,
              aliasName: 'items__id__item_aliases__itemId');

  $$ItemAliasesTableProcessedTableManager get itemAliasesRefs {
    final manager = $$ItemAliasesTableTableManager($_db, $_db.itemAliases)
        .filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemAliasesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExpenseItemsTable, List<ExpenseItem>>
      _expenseItemsRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.expenseItems,
              aliasName: 'items__id__expense_items__itemId');

  $$ExpenseItemsTableProcessedTableManager get expenseItemsRefs {
    final manager = $$ExpenseItemsTableTableManager($_db, $_db.expenseItems)
        .filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ItemsTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  $$UnitsTableFilterComposer get defaultUnitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.defaultUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> itemAliasesRefs(
      Expression<bool> Function($$ItemAliasesTableFilterComposer f) f) {
    final $$ItemAliasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itemAliases,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemAliasesTableFilterComposer(
              $db: $db,
              $table: $db.itemAliases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> expenseItemsRefs(
      Expression<bool> Function($$ExpenseItemsTableFilterComposer f) f) {
    final $$ExpenseItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableFilterComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  $$UnitsTableOrderingComposer get defaultUnitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.defaultUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  $$UnitsTableAnnotationComposer get defaultUnitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.defaultUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> itemAliasesRefs<T extends Object>(
      Expression<T> Function($$ItemAliasesTableAnnotationComposer a) f) {
    final $$ItemAliasesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itemAliases,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemAliasesTableAnnotationComposer(
              $db: $db,
              $table: $db.itemAliases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> expenseItemsRefs<T extends Object>(
      Expression<T> Function($$ExpenseItemsTableAnnotationComposer a) f) {
    final $$ExpenseItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenseItems,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpenseItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.expenseItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemsTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $ItemsTable,
    Item,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (Item, $$ItemsTableReferences),
    Item,
    PrefetchHooks Function(
        {bool defaultUnitId,
        bool categoryId,
        bool itemAliasesRefs,
        bool expenseItemsRefs})> {
  $$ItemsTableTableManager(_$WalletMeltDatabase db, $ItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> normalizedName = const Value.absent(),
            Value<String?> defaultUnitId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemsCompanion(
            id: id,
            name: name,
            normalizedName: normalizedName,
            defaultUnitId: defaultUnitId,
            categoryId: categoryId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String normalizedName,
            Value<String?> defaultUnitId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemsCompanion.insert(
            id: id,
            name: name,
            normalizedName: normalizedName,
            defaultUnitId: defaultUnitId,
            categoryId: categoryId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ItemsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {defaultUnitId = false,
              categoryId = false,
              itemAliasesRefs = false,
              expenseItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (itemAliasesRefs) db.itemAliases,
                if (expenseItemsRefs) db.expenseItems
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (defaultUnitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.defaultUnitId,
                    referencedTable:
                        $$ItemsTableReferences._defaultUnitIdTable(db),
                    referencedColumn:
                        $$ItemsTableReferences._defaultUnitIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$ItemsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$ItemsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemAliasesRefs)
                    await $_getPrefetchedData<Item, $ItemsTable, ItemAliase>(
                        currentTable: table,
                        referencedTable:
                            $$ItemsTableReferences._itemAliasesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ItemsTableReferences(db, table, p0)
                                .itemAliasesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.itemId == item.id),
                        typedResults: items),
                  if (expenseItemsRefs)
                    await $_getPrefetchedData<Item, $ItemsTable, ExpenseItem>(
                        currentTable: table,
                        referencedTable:
                            $$ItemsTableReferences._expenseItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ItemsTableReferences(db, table, p0)
                                .expenseItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.itemId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ItemsTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $ItemsTable,
    Item,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (Item, $$ItemsTableReferences),
    Item,
    PrefetchHooks Function(
        {bool defaultUnitId,
        bool categoryId,
        bool itemAliasesRefs,
        bool expenseItemsRefs})>;
typedef $$ItemAliasesTableCreateCompanionBuilder = ItemAliasesCompanion
    Function({
  required String id,
  required String itemId,
  required String alias,
  required String normalizedAlias,
  required String createdAt,
  Value<int> rowid,
});
typedef $$ItemAliasesTableUpdateCompanionBuilder = ItemAliasesCompanion
    Function({
  Value<String> id,
  Value<String> itemId,
  Value<String> alias,
  Value<String> normalizedAlias,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $$ItemAliasesTableReferences extends BaseReferences<
    _$WalletMeltDatabase, $ItemAliasesTable, ItemAliase> {
  $$ItemAliasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$WalletMeltDatabase db) =>
      db.items.createAlias('item_aliases__itemId__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('itemId')!;

    final manager = $$ItemsTableTableManager($_db, $_db.items)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ItemAliasesTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $ItemAliasesTable> {
  $$ItemAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alias => $composableBuilder(
      column: $table.alias, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedAlias => $composableBuilder(
      column: $table.normalizedAlias,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableFilterComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemAliasesTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $ItemAliasesTable> {
  $$ItemAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alias => $composableBuilder(
      column: $table.alias, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedAlias => $composableBuilder(
      column: $table.normalizedAlias,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableOrderingComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemAliasesTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $ItemAliasesTable> {
  $$ItemAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get normalizedAlias => $composableBuilder(
      column: $table.normalizedAlias, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemAliasesTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $ItemAliasesTable,
    ItemAliase,
    $$ItemAliasesTableFilterComposer,
    $$ItemAliasesTableOrderingComposer,
    $$ItemAliasesTableAnnotationComposer,
    $$ItemAliasesTableCreateCompanionBuilder,
    $$ItemAliasesTableUpdateCompanionBuilder,
    (ItemAliase, $$ItemAliasesTableReferences),
    ItemAliase,
    PrefetchHooks Function({bool itemId})> {
  $$ItemAliasesTableTableManager(
      _$WalletMeltDatabase db, $ItemAliasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<String> alias = const Value.absent(),
            Value<String> normalizedAlias = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemAliasesCompanion(
            id: id,
            itemId: itemId,
            alias: alias,
            normalizedAlias: normalizedAlias,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String itemId,
            required String alias,
            required String normalizedAlias,
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemAliasesCompanion.insert(
            id: id,
            itemId: itemId,
            alias: alias,
            normalizedAlias: normalizedAlias,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItemAliasesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (itemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemId,
                    referencedTable:
                        $$ItemAliasesTableReferences._itemIdTable(db),
                    referencedColumn:
                        $$ItemAliasesTableReferences._itemIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ItemAliasesTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $ItemAliasesTable,
    ItemAliase,
    $$ItemAliasesTableFilterComposer,
    $$ItemAliasesTableOrderingComposer,
    $$ItemAliasesTableAnnotationComposer,
    $$ItemAliasesTableCreateCompanionBuilder,
    $$ItemAliasesTableUpdateCompanionBuilder,
    (ItemAliase, $$ItemAliasesTableReferences),
    ItemAliase,
    PrefetchHooks Function({bool itemId})>;
typedef $$ExpenseItemsTableCreateCompanionBuilder = ExpenseItemsCompanion
    Function({
  required String id,
  required String expenseId,
  Value<String?> itemId,
  required String nameSnapshot,
  Value<double?> quantity,
  Value<String?> unitId,
  Value<double?> unitPrice,
  required double totalPrice,
  required String currency,
  Value<String?> brand,
  Value<String?> storeId,
  Value<String?> dateOverride,
  Value<String?> categoryId,
  Value<String?> subcategory,
  Value<String?> notes,
  required String createdAt,
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$ExpenseItemsTableUpdateCompanionBuilder = ExpenseItemsCompanion
    Function({
  Value<String> id,
  Value<String> expenseId,
  Value<String?> itemId,
  Value<String> nameSnapshot,
  Value<double?> quantity,
  Value<String?> unitId,
  Value<double?> unitPrice,
  Value<double> totalPrice,
  Value<String> currency,
  Value<String?> brand,
  Value<String?> storeId,
  Value<String?> dateOverride,
  Value<String?> categoryId,
  Value<String?> subcategory,
  Value<String?> notes,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

final class $$ExpenseItemsTableReferences extends BaseReferences<
    _$WalletMeltDatabase, $ExpenseItemsTable, ExpenseItem> {
  $$ExpenseItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExpensesTable _expenseIdTable(_$WalletMeltDatabase db) =>
      db.expenses.createAlias('expense_items__expenseId__expenses__id');

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expenseId')!;

    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ItemsTable _itemIdTable(_$WalletMeltDatabase db) =>
      db.items.createAlias('expense_items__itemId__items__id');

  $$ItemsTableProcessedTableManager? get itemId {
    final $_column = $_itemColumn<String>('itemId');
    if ($_column == null) return null;
    final manager = $$ItemsTableTableManager($_db, $_db.items)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UnitsTable _unitIdTable(_$WalletMeltDatabase db) =>
      db.units.createAlias('expense_items__unitId__units__id');

  $$UnitsTableProcessedTableManager? get unitId {
    final $_column = $_itemColumn<String>('unitId');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $StoresTable _storeIdTable(_$WalletMeltDatabase db) =>
      db.stores.createAlias('expense_items__storeId__stores__id');

  $$StoresTableProcessedTableManager? get storeId {
    final $_column = $_itemColumn<String>('storeId');
    if ($_column == null) return null;
    final manager = $$StoresTableTableManager($_db, $_db.stores)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$WalletMeltDatabase db) =>
      db.categories.createAlias('expense_items__categoryId__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('categoryId');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExpenseItemsTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $ExpenseItemsTable> {
  $$ExpenseItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameSnapshot => $composableBuilder(
      column: $table.nameSnapshot, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalPrice => $composableBuilder(
      column: $table.totalPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateOverride => $composableBuilder(
      column: $table.dateOverride, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableFilterComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableFilterComposer get unitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StoresTableFilterComposer get storeId {
    final $$StoresTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableFilterComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpenseItemsTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $ExpenseItemsTable> {
  $$ExpenseItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameSnapshot => $composableBuilder(
      column: $table.nameSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalPrice => $composableBuilder(
      column: $table.totalPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateOverride => $composableBuilder(
      column: $table.dateOverride,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableOrderingComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableOrderingComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableOrderingComposer get unitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StoresTableOrderingComposer get storeId {
    final $$StoresTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableOrderingComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpenseItemsTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $ExpenseItemsTable> {
  $$ExpenseItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameSnapshot => $composableBuilder(
      column: $table.nameSnapshot, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get totalPrice => $composableBuilder(
      column: $table.totalPrice, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get dateOverride => $composableBuilder(
      column: $table.dateOverride, builder: (column) => column);

  GeneratedColumn<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.items,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.items,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableAnnotationComposer get unitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StoresTableAnnotationComposer get storeId {
    final $$StoresTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.storeId,
        referencedTable: $db.stores,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoresTableAnnotationComposer(
              $db: $db,
              $table: $db.stores,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpenseItemsTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $ExpenseItemsTable,
    ExpenseItem,
    $$ExpenseItemsTableFilterComposer,
    $$ExpenseItemsTableOrderingComposer,
    $$ExpenseItemsTableAnnotationComposer,
    $$ExpenseItemsTableCreateCompanionBuilder,
    $$ExpenseItemsTableUpdateCompanionBuilder,
    (ExpenseItem, $$ExpenseItemsTableReferences),
    ExpenseItem,
    PrefetchHooks Function(
        {bool expenseId,
        bool itemId,
        bool unitId,
        bool storeId,
        bool categoryId})> {
  $$ExpenseItemsTableTableManager(
      _$WalletMeltDatabase db, $ExpenseItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> expenseId = const Value.absent(),
            Value<String?> itemId = const Value.absent(),
            Value<String> nameSnapshot = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<double?> unitPrice = const Value.absent(),
            Value<double> totalPrice = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> brand = const Value.absent(),
            Value<String?> storeId = const Value.absent(),
            Value<String?> dateOverride = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> subcategory = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpenseItemsCompanion(
            id: id,
            expenseId: expenseId,
            itemId: itemId,
            nameSnapshot: nameSnapshot,
            quantity: quantity,
            unitId: unitId,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            currency: currency,
            brand: brand,
            storeId: storeId,
            dateOverride: dateOverride,
            categoryId: categoryId,
            subcategory: subcategory,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String expenseId,
            Value<String?> itemId = const Value.absent(),
            required String nameSnapshot,
            Value<double?> quantity = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<double?> unitPrice = const Value.absent(),
            required double totalPrice,
            required String currency,
            Value<String?> brand = const Value.absent(),
            Value<String?> storeId = const Value.absent(),
            Value<String?> dateOverride = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> subcategory = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpenseItemsCompanion.insert(
            id: id,
            expenseId: expenseId,
            itemId: itemId,
            nameSnapshot: nameSnapshot,
            quantity: quantity,
            unitId: unitId,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            currency: currency,
            brand: brand,
            storeId: storeId,
            dateOverride: dateOverride,
            categoryId: categoryId,
            subcategory: subcategory,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExpenseItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {expenseId = false,
              itemId = false,
              unitId = false,
              storeId = false,
              categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (expenseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.expenseId,
                    referencedTable:
                        $$ExpenseItemsTableReferences._expenseIdTable(db),
                    referencedColumn:
                        $$ExpenseItemsTableReferences._expenseIdTable(db).id,
                  ) as T;
                }
                if (itemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemId,
                    referencedTable:
                        $$ExpenseItemsTableReferences._itemIdTable(db),
                    referencedColumn:
                        $$ExpenseItemsTableReferences._itemIdTable(db).id,
                  ) as T;
                }
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$ExpenseItemsTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$ExpenseItemsTableReferences._unitIdTable(db).id,
                  ) as T;
                }
                if (storeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.storeId,
                    referencedTable:
                        $$ExpenseItemsTableReferences._storeIdTable(db),
                    referencedColumn:
                        $$ExpenseItemsTableReferences._storeIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$ExpenseItemsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$ExpenseItemsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ExpenseItemsTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $ExpenseItemsTable,
    ExpenseItem,
    $$ExpenseItemsTableFilterComposer,
    $$ExpenseItemsTableOrderingComposer,
    $$ExpenseItemsTableAnnotationComposer,
    $$ExpenseItemsTableCreateCompanionBuilder,
    $$ExpenseItemsTableUpdateCompanionBuilder,
    (ExpenseItem, $$ExpenseItemsTableReferences),
    ExpenseItem,
    PrefetchHooks Function(
        {bool expenseId,
        bool itemId,
        bool unitId,
        bool storeId,
        bool categoryId})>;
typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  required String id,
  required String expenseId,
  required String uri,
  Value<String?> mimeType,
  Value<int?> fileSizeBytes,
  required String createdAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<String> id,
  Value<String> expenseId,
  Value<String> uri,
  Value<String?> mimeType,
  Value<int?> fileSizeBytes,
  Value<String> createdAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

final class $$ReceiptsTableReferences
    extends BaseReferences<_$WalletMeltDatabase, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExpensesTable _expenseIdTable(_$WalletMeltDatabase db) =>
      db.expenses.createAlias('receipts__expenseId__expenses__id');

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expenseId')!;

    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uri => $composableBuilder(
      column: $table.uri, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uri => $composableBuilder(
      column: $table.uri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableOrderingComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.expenseId,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $ReceiptsTable,
    Receipt,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (Receipt, $$ReceiptsTableReferences),
    Receipt,
    PrefetchHooks Function({bool expenseId})> {
  $$ReceiptsTableTableManager(_$WalletMeltDatabase db, $ReceiptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> expenseId = const Value.absent(),
            Value<String> uri = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<int?> fileSizeBytes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptsCompanion(
            id: id,
            expenseId: expenseId,
            uri: uri,
            mimeType: mimeType,
            fileSizeBytes: fileSizeBytes,
            createdAt: createdAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String expenseId,
            required String uri,
            Value<String?> mimeType = const Value.absent(),
            Value<int?> fileSizeBytes = const Value.absent(),
            required String createdAt,
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptsCompanion.insert(
            id: id,
            expenseId: expenseId,
            uri: uri,
            mimeType: mimeType,
            fileSizeBytes: fileSizeBytes,
            createdAt: createdAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ReceiptsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({expenseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (expenseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.expenseId,
                    referencedTable:
                        $$ReceiptsTableReferences._expenseIdTable(db),
                    referencedColumn:
                        $$ReceiptsTableReferences._expenseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReceiptsTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $ReceiptsTable,
    Receipt,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (Receipt, $$ReceiptsTableReferences),
    Receipt,
    PrefetchHooks Function({bool expenseId})>;
typedef $$MigrationAuditTableCreateCompanionBuilder = MigrationAuditCompanion
    Function({
  required String id,
  required int fromVersion,
  required int toVersion,
  required String startedAt,
  Value<String?> completedAt,
  required String status,
  Value<String?> errorMessage,
  Value<String?> preMigrationBackupPath,
  Value<int> rowid,
});
typedef $$MigrationAuditTableUpdateCompanionBuilder = MigrationAuditCompanion
    Function({
  Value<String> id,
  Value<int> fromVersion,
  Value<int> toVersion,
  Value<String> startedAt,
  Value<String?> completedAt,
  Value<String> status,
  Value<String?> errorMessage,
  Value<String?> preMigrationBackupPath,
  Value<int> rowid,
});

class $$MigrationAuditTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $MigrationAuditTable> {
  $$MigrationAuditTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fromVersion => $composableBuilder(
      column: $table.fromVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get toVersion => $composableBuilder(
      column: $table.toVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get preMigrationBackupPath => $composableBuilder(
      column: $table.preMigrationBackupPath,
      builder: (column) => ColumnFilters(column));
}

class $$MigrationAuditTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $MigrationAuditTable> {
  $$MigrationAuditTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fromVersion => $composableBuilder(
      column: $table.fromVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get toVersion => $composableBuilder(
      column: $table.toVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get preMigrationBackupPath => $composableBuilder(
      column: $table.preMigrationBackupPath,
      builder: (column) => ColumnOrderings(column));
}

class $$MigrationAuditTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $MigrationAuditTable> {
  $$MigrationAuditTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get fromVersion => $composableBuilder(
      column: $table.fromVersion, builder: (column) => column);

  GeneratedColumn<int> get toVersion =>
      $composableBuilder(column: $table.toVersion, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<String> get preMigrationBackupPath => $composableBuilder(
      column: $table.preMigrationBackupPath, builder: (column) => column);
}

class $$MigrationAuditTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $MigrationAuditTable,
    MigrationAuditData,
    $$MigrationAuditTableFilterComposer,
    $$MigrationAuditTableOrderingComposer,
    $$MigrationAuditTableAnnotationComposer,
    $$MigrationAuditTableCreateCompanionBuilder,
    $$MigrationAuditTableUpdateCompanionBuilder,
    (
      MigrationAuditData,
      BaseReferences<_$WalletMeltDatabase, $MigrationAuditTable,
          MigrationAuditData>
    ),
    MigrationAuditData,
    PrefetchHooks Function()> {
  $$MigrationAuditTableTableManager(
      _$WalletMeltDatabase db, $MigrationAuditTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationAuditTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MigrationAuditTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MigrationAuditTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> fromVersion = const Value.absent(),
            Value<int> toVersion = const Value.absent(),
            Value<String> startedAt = const Value.absent(),
            Value<String?> completedAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> preMigrationBackupPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MigrationAuditCompanion(
            id: id,
            fromVersion: fromVersion,
            toVersion: toVersion,
            startedAt: startedAt,
            completedAt: completedAt,
            status: status,
            errorMessage: errorMessage,
            preMigrationBackupPath: preMigrationBackupPath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int fromVersion,
            required int toVersion,
            required String startedAt,
            Value<String?> completedAt = const Value.absent(),
            required String status,
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> preMigrationBackupPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MigrationAuditCompanion.insert(
            id: id,
            fromVersion: fromVersion,
            toVersion: toVersion,
            startedAt: startedAt,
            completedAt: completedAt,
            status: status,
            errorMessage: errorMessage,
            preMigrationBackupPath: preMigrationBackupPath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MigrationAuditTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $MigrationAuditTable,
    MigrationAuditData,
    $$MigrationAuditTableFilterComposer,
    $$MigrationAuditTableOrderingComposer,
    $$MigrationAuditTableAnnotationComposer,
    $$MigrationAuditTableCreateCompanionBuilder,
    $$MigrationAuditTableUpdateCompanionBuilder,
    (
      MigrationAuditData,
      BaseReferences<_$WalletMeltDatabase, $MigrationAuditTable,
          MigrationAuditData>
    ),
    MigrationAuditData,
    PrefetchHooks Function()>;
typedef $$DebtRecordsTableCreateCompanionBuilder = DebtRecordsCompanion
    Function({
  required String id,
  required String personName,
  required String type,
  required double principalAmount,
  required double remainingAmount,
  required String currency,
  Value<String?> description,
  required String createdAt,
  Value<String?> dueDate,
  Value<String?> settledAt,
  required String status,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$DebtRecordsTableUpdateCompanionBuilder = DebtRecordsCompanion
    Function({
  Value<String> id,
  Value<String> personName,
  Value<String> type,
  Value<double> principalAmount,
  Value<double> remainingAmount,
  Value<String> currency,
  Value<String?> description,
  Value<String> createdAt,
  Value<String?> dueDate,
  Value<String?> settledAt,
  Value<String> status,
  Value<String?> notes,
  Value<int> rowid,
});

final class $$DebtRecordsTableReferences extends BaseReferences<
    _$WalletMeltDatabase, $DebtRecordsTable, DebtRecord> {
  $$DebtRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DebtRepaymentsTable, List<DebtRepayment>>
      _debtRepaymentsRefsTable(_$WalletMeltDatabase db) =>
          MultiTypedResultKey.fromTable(db.debtRepayments,
              aliasName: 'debt_records__id__debt_repayments__debtId');

  $$DebtRepaymentsTableProcessedTableManager get debtRepaymentsRefs {
    final manager = $$DebtRepaymentsTableTableManager($_db, $_db.debtRepayments)
        .filter((f) => f.debtId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_debtRepaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DebtRecordsTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $DebtRecordsTable> {
  $$DebtRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get principalAmount => $composableBuilder(
      column: $table.principalAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get remainingAmount => $composableBuilder(
      column: $table.remainingAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get settledAt => $composableBuilder(
      column: $table.settledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  Expression<bool> debtRepaymentsRefs(
      Expression<bool> Function($$DebtRepaymentsTableFilterComposer f) f) {
    final $$DebtRepaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debtRepayments,
        getReferencedColumn: (t) => t.debtId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtRepaymentsTableFilterComposer(
              $db: $db,
              $table: $db.debtRepayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DebtRecordsTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $DebtRecordsTable> {
  $$DebtRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get principalAmount => $composableBuilder(
      column: $table.principalAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get remainingAmount => $composableBuilder(
      column: $table.remainingAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get settledAt => $composableBuilder(
      column: $table.settledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$DebtRecordsTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $DebtRecordsTable> {
  $$DebtRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get principalAmount => $composableBuilder(
      column: $table.principalAmount, builder: (column) => column);

  GeneratedColumn<double> get remainingAmount => $composableBuilder(
      column: $table.remainingAmount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> debtRepaymentsRefs<T extends Object>(
      Expression<T> Function($$DebtRepaymentsTableAnnotationComposer a) f) {
    final $$DebtRepaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debtRepayments,
        getReferencedColumn: (t) => t.debtId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtRepaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.debtRepayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DebtRecordsTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $DebtRecordsTable,
    DebtRecord,
    $$DebtRecordsTableFilterComposer,
    $$DebtRecordsTableOrderingComposer,
    $$DebtRecordsTableAnnotationComposer,
    $$DebtRecordsTableCreateCompanionBuilder,
    $$DebtRecordsTableUpdateCompanionBuilder,
    (DebtRecord, $$DebtRecordsTableReferences),
    DebtRecord,
    PrefetchHooks Function({bool debtRepaymentsRefs})> {
  $$DebtRecordsTableTableManager(
      _$WalletMeltDatabase db, $DebtRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> personName = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> principalAmount = const Value.absent(),
            Value<double> remainingAmount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String?> dueDate = const Value.absent(),
            Value<String?> settledAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DebtRecordsCompanion(
            id: id,
            personName: personName,
            type: type,
            principalAmount: principalAmount,
            remainingAmount: remainingAmount,
            currency: currency,
            description: description,
            createdAt: createdAt,
            dueDate: dueDate,
            settledAt: settledAt,
            status: status,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String personName,
            required String type,
            required double principalAmount,
            required double remainingAmount,
            required String currency,
            Value<String?> description = const Value.absent(),
            required String createdAt,
            Value<String?> dueDate = const Value.absent(),
            Value<String?> settledAt = const Value.absent(),
            required String status,
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DebtRecordsCompanion.insert(
            id: id,
            personName: personName,
            type: type,
            principalAmount: principalAmount,
            remainingAmount: remainingAmount,
            currency: currency,
            description: description,
            createdAt: createdAt,
            dueDate: dueDate,
            settledAt: settledAt,
            status: status,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DebtRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({debtRepaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (debtRepaymentsRefs) db.debtRepayments
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (debtRepaymentsRefs)
                    await $_getPrefetchedData<DebtRecord, $DebtRecordsTable,
                            DebtRepayment>(
                        currentTable: table,
                        referencedTable: $$DebtRecordsTableReferences
                            ._debtRepaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DebtRecordsTableReferences(db, table, p0)
                                .debtRepaymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.debtId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DebtRecordsTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $DebtRecordsTable,
    DebtRecord,
    $$DebtRecordsTableFilterComposer,
    $$DebtRecordsTableOrderingComposer,
    $$DebtRecordsTableAnnotationComposer,
    $$DebtRecordsTableCreateCompanionBuilder,
    $$DebtRecordsTableUpdateCompanionBuilder,
    (DebtRecord, $$DebtRecordsTableReferences),
    DebtRecord,
    PrefetchHooks Function({bool debtRepaymentsRefs})>;
typedef $$DebtRepaymentsTableCreateCompanionBuilder = DebtRepaymentsCompanion
    Function({
  required String id,
  required String debtId,
  required double amount,
  required String createdAt,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$DebtRepaymentsTableUpdateCompanionBuilder = DebtRepaymentsCompanion
    Function({
  Value<String> id,
  Value<String> debtId,
  Value<double> amount,
  Value<String> createdAt,
  Value<String?> notes,
  Value<int> rowid,
});

final class $$DebtRepaymentsTableReferences extends BaseReferences<
    _$WalletMeltDatabase, $DebtRepaymentsTable, DebtRepayment> {
  $$DebtRepaymentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DebtRecordsTable _debtIdTable(_$WalletMeltDatabase db) =>
      db.debtRecords.createAlias('debt_repayments__debtId__debt_records__id');

  $$DebtRecordsTableProcessedTableManager get debtId {
    final $_column = $_itemColumn<String>('debtId')!;

    final manager = $$DebtRecordsTableTableManager($_db, $_db.debtRecords)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DebtRepaymentsTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $DebtRepaymentsTable> {
  $$DebtRepaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$DebtRecordsTableFilterComposer get debtId {
    final $$DebtRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debtRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtRecordsTableFilterComposer(
              $db: $db,
              $table: $db.debtRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DebtRepaymentsTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $DebtRepaymentsTable> {
  $$DebtRepaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$DebtRecordsTableOrderingComposer get debtId {
    final $$DebtRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debtRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.debtRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DebtRepaymentsTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $DebtRepaymentsTable> {
  $$DebtRepaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$DebtRecordsTableAnnotationComposer get debtId {
    final $$DebtRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debtRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.debtRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DebtRepaymentsTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $DebtRepaymentsTable,
    DebtRepayment,
    $$DebtRepaymentsTableFilterComposer,
    $$DebtRepaymentsTableOrderingComposer,
    $$DebtRepaymentsTableAnnotationComposer,
    $$DebtRepaymentsTableCreateCompanionBuilder,
    $$DebtRepaymentsTableUpdateCompanionBuilder,
    (DebtRepayment, $$DebtRepaymentsTableReferences),
    DebtRepayment,
    PrefetchHooks Function({bool debtId})> {
  $$DebtRepaymentsTableTableManager(
      _$WalletMeltDatabase db, $DebtRepaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtRepaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtRepaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtRepaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> debtId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DebtRepaymentsCompanion(
            id: id,
            debtId: debtId,
            amount: amount,
            createdAt: createdAt,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String debtId,
            required double amount,
            required String createdAt,
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DebtRepaymentsCompanion.insert(
            id: id,
            debtId: debtId,
            amount: amount,
            createdAt: createdAt,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DebtRepaymentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({debtId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (debtId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.debtId,
                    referencedTable:
                        $$DebtRepaymentsTableReferences._debtIdTable(db),
                    referencedColumn:
                        $$DebtRepaymentsTableReferences._debtIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DebtRepaymentsTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $DebtRepaymentsTable,
    DebtRepayment,
    $$DebtRepaymentsTableFilterComposer,
    $$DebtRepaymentsTableOrderingComposer,
    $$DebtRepaymentsTableAnnotationComposer,
    $$DebtRepaymentsTableCreateCompanionBuilder,
    $$DebtRepaymentsTableUpdateCompanionBuilder,
    (DebtRepayment, $$DebtRepaymentsTableReferences),
    DebtRepayment,
    PrefetchHooks Function({bool debtId})>;
typedef $$GroceryTemplatesTableCreateCompanionBuilder
    = GroceryTemplatesCompanion Function({
  required String id,
  required String name,
  required String items,
  required String createdAt,
  Value<int> rowid,
});
typedef $$GroceryTemplatesTableUpdateCompanionBuilder
    = GroceryTemplatesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> items,
  Value<String> createdAt,
  Value<int> rowid,
});

class $$GroceryTemplatesTableFilterComposer
    extends Composer<_$WalletMeltDatabase, $GroceryTemplatesTable> {
  $$GroceryTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get items => $composableBuilder(
      column: $table.items, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GroceryTemplatesTableOrderingComposer
    extends Composer<_$WalletMeltDatabase, $GroceryTemplatesTable> {
  $$GroceryTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get items => $composableBuilder(
      column: $table.items, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GroceryTemplatesTableAnnotationComposer
    extends Composer<_$WalletMeltDatabase, $GroceryTemplatesTable> {
  $$GroceryTemplatesTableAnnotationComposer({
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

  GeneratedColumn<String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GroceryTemplatesTableTableManager extends RootTableManager<
    _$WalletMeltDatabase,
    $GroceryTemplatesTable,
    GroceryTemplate,
    $$GroceryTemplatesTableFilterComposer,
    $$GroceryTemplatesTableOrderingComposer,
    $$GroceryTemplatesTableAnnotationComposer,
    $$GroceryTemplatesTableCreateCompanionBuilder,
    $$GroceryTemplatesTableUpdateCompanionBuilder,
    (
      GroceryTemplate,
      BaseReferences<_$WalletMeltDatabase, $GroceryTemplatesTable,
          GroceryTemplate>
    ),
    GroceryTemplate,
    PrefetchHooks Function()> {
  $$GroceryTemplatesTableTableManager(
      _$WalletMeltDatabase db, $GroceryTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroceryTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroceryTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroceryTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> items = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroceryTemplatesCompanion(
            id: id,
            name: name,
            items: items,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String items,
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GroceryTemplatesCompanion.insert(
            id: id,
            name: name,
            items: items,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroceryTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$WalletMeltDatabase,
    $GroceryTemplatesTable,
    GroceryTemplate,
    $$GroceryTemplatesTableFilterComposer,
    $$GroceryTemplatesTableOrderingComposer,
    $$GroceryTemplatesTableAnnotationComposer,
    $$GroceryTemplatesTableCreateCompanionBuilder,
    $$GroceryTemplatesTableUpdateCompanionBuilder,
    (
      GroceryTemplate,
      BaseReferences<_$WalletMeltDatabase, $GroceryTemplatesTable,
          GroceryTemplate>
    ),
    GroceryTemplate,
    PrefetchHooks Function()>;

class $WalletMeltDatabaseManager {
  final _$WalletMeltDatabase _db;
  $WalletMeltDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db, _db.stores);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$GroceryItemsTableTableManager get groceryItems =>
      $$GroceryItemsTableTableManager(_db, _db.groceryItems);
  $$CategoryBudgetsTableTableManager get categoryBudgets =>
      $$CategoryBudgetsTableTableManager(_db, _db.categoryBudgets);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ItemAliasesTableTableManager get itemAliases =>
      $$ItemAliasesTableTableManager(_db, _db.itemAliases);
  $$ExpenseItemsTableTableManager get expenseItems =>
      $$ExpenseItemsTableTableManager(_db, _db.expenseItems);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$MigrationAuditTableTableManager get migrationAudit =>
      $$MigrationAuditTableTableManager(_db, _db.migrationAudit);
  $$DebtRecordsTableTableManager get debtRecords =>
      $$DebtRecordsTableTableManager(_db, _db.debtRecords);
  $$DebtRepaymentsTableTableManager get debtRepayments =>
      $$DebtRepaymentsTableTableManager(_db, _db.debtRepayments);
  $$GroceryTemplatesTableTableManager get groceryTemplates =>
      $$GroceryTemplatesTableTableManager(_db, _db.groceryTemplates);
}
