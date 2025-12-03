// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_entry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

JournalEntry _$JournalEntryFromJson(Map<String, dynamic> json) {
  return _JournalEntry.fromJson(json);
}

/// @nodoc
mixin _$JournalEntry {
  String get id => throw _privateConstructorUsedError;
  String get accountCode => throw _privateConstructorUsedError;
  String get accountName => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this JournalEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JournalEntryCopyWith<JournalEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JournalEntryCopyWith<$Res> {
  factory $JournalEntryCopyWith(
    JournalEntry value,
    $Res Function(JournalEntry) then,
  ) = _$JournalEntryCopyWithImpl<$Res, JournalEntry>;
  @useResult
  $Res call({
    String id,
    String accountCode,
    String accountName,
    double amount,
    DateTime date,
    String? description,
  });
}

/// @nodoc
class _$JournalEntryCopyWithImpl<$Res, $Val extends JournalEntry>
    implements $JournalEntryCopyWith<$Res> {
  _$JournalEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountCode = null,
    Object? accountName = null,
    Object? amount = null,
    Object? date = null,
    Object? description = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            accountCode: null == accountCode
                ? _value.accountCode
                : accountCode // ignore: cast_nullable_to_non_nullable
                      as String,
            accountName: null == accountName
                ? _value.accountName
                : accountName // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JournalEntryImplCopyWith<$Res>
    implements $JournalEntryCopyWith<$Res> {
  factory _$$JournalEntryImplCopyWith(
    _$JournalEntryImpl value,
    $Res Function(_$JournalEntryImpl) then,
  ) = __$$JournalEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String accountCode,
    String accountName,
    double amount,
    DateTime date,
    String? description,
  });
}

/// @nodoc
class __$$JournalEntryImplCopyWithImpl<$Res>
    extends _$JournalEntryCopyWithImpl<$Res, _$JournalEntryImpl>
    implements _$$JournalEntryImplCopyWith<$Res> {
  __$$JournalEntryImplCopyWithImpl(
    _$JournalEntryImpl _value,
    $Res Function(_$JournalEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountCode = null,
    Object? accountName = null,
    Object? amount = null,
    Object? date = null,
    Object? description = freezed,
  }) {
    return _then(
      _$JournalEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        accountCode: null == accountCode
            ? _value.accountCode
            : accountCode // ignore: cast_nullable_to_non_nullable
                  as String,
        accountName: null == accountName
            ? _value.accountName
            : accountName // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JournalEntryImpl implements _JournalEntry {
  const _$JournalEntryImpl({
    required this.id,
    required this.accountCode,
    required this.accountName,
    required this.amount,
    required this.date,
    this.description,
  });

  factory _$JournalEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$JournalEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String accountCode;
  @override
  final String accountName;
  @override
  final double amount;
  @override
  final DateTime date;
  @override
  final String? description;

  @override
  String toString() {
    return 'JournalEntry(id: $id, accountCode: $accountCode, accountName: $accountName, amount: $amount, date: $date, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JournalEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.accountCode, accountCode) ||
                other.accountCode == accountCode) &&
            (identical(other.accountName, accountName) ||
                other.accountName == accountName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    accountCode,
    accountName,
    amount,
    date,
    description,
  );

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JournalEntryImplCopyWith<_$JournalEntryImpl> get copyWith =>
      __$$JournalEntryImplCopyWithImpl<_$JournalEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JournalEntryImplToJson(this);
  }
}

abstract class _JournalEntry implements JournalEntry {
  const factory _JournalEntry({
    required final String id,
    required final String accountCode,
    required final String accountName,
    required final double amount,
    required final DateTime date,
    final String? description,
  }) = _$JournalEntryImpl;

  factory _JournalEntry.fromJson(Map<String, dynamic> json) =
      _$JournalEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get accountCode;
  @override
  String get accountName;
  @override
  double get amount;
  @override
  DateTime get date;
  @override
  String? get description;

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JournalEntryImplCopyWith<_$JournalEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JournalEntrySet _$JournalEntrySetFromJson(Map<String, dynamic> json) {
  return _JournalEntrySet.fromJson(json);
}

/// @nodoc
mixin _$JournalEntrySet {
  List<JournalEntry> get entries => throw _privateConstructorUsedError;

  /// Serializes this JournalEntrySet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JournalEntrySet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JournalEntrySetCopyWith<JournalEntrySet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JournalEntrySetCopyWith<$Res> {
  factory $JournalEntrySetCopyWith(
    JournalEntrySet value,
    $Res Function(JournalEntrySet) then,
  ) = _$JournalEntrySetCopyWithImpl<$Res, JournalEntrySet>;
  @useResult
  $Res call({List<JournalEntry> entries});
}

/// @nodoc
class _$JournalEntrySetCopyWithImpl<$Res, $Val extends JournalEntrySet>
    implements $JournalEntrySetCopyWith<$Res> {
  _$JournalEntrySetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JournalEntrySet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? entries = null}) {
    return _then(
      _value.copyWith(
            entries: null == entries
                ? _value.entries
                : entries // ignore: cast_nullable_to_non_nullable
                      as List<JournalEntry>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JournalEntrySetImplCopyWith<$Res>
    implements $JournalEntrySetCopyWith<$Res> {
  factory _$$JournalEntrySetImplCopyWith(
    _$JournalEntrySetImpl value,
    $Res Function(_$JournalEntrySetImpl) then,
  ) = __$$JournalEntrySetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<JournalEntry> entries});
}

/// @nodoc
class __$$JournalEntrySetImplCopyWithImpl<$Res>
    extends _$JournalEntrySetCopyWithImpl<$Res, _$JournalEntrySetImpl>
    implements _$$JournalEntrySetImplCopyWith<$Res> {
  __$$JournalEntrySetImplCopyWithImpl(
    _$JournalEntrySetImpl _value,
    $Res Function(_$JournalEntrySetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JournalEntrySet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? entries = null}) {
    return _then(
      _$JournalEntrySetImpl(
        entries: null == entries
            ? _value._entries
            : entries // ignore: cast_nullable_to_non_nullable
                  as List<JournalEntry>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JournalEntrySetImpl implements _JournalEntrySet {
  const _$JournalEntrySetImpl({required final List<JournalEntry> entries})
    : _entries = entries;

  factory _$JournalEntrySetImpl.fromJson(Map<String, dynamic> json) =>
      _$$JournalEntrySetImplFromJson(json);

  final List<JournalEntry> _entries;
  @override
  List<JournalEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @override
  String toString() {
    return 'JournalEntrySet(entries: $entries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JournalEntrySetImpl &&
            const DeepCollectionEquality().equals(other._entries, _entries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_entries));

  /// Create a copy of JournalEntrySet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JournalEntrySetImplCopyWith<_$JournalEntrySetImpl> get copyWith =>
      __$$JournalEntrySetImplCopyWithImpl<_$JournalEntrySetImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$JournalEntrySetImplToJson(this);
  }
}

abstract class _JournalEntrySet implements JournalEntrySet {
  const factory _JournalEntrySet({required final List<JournalEntry> entries}) =
      _$JournalEntrySetImpl;

  factory _JournalEntrySet.fromJson(Map<String, dynamic> json) =
      _$JournalEntrySetImpl.fromJson;

  @override
  List<JournalEntry> get entries;

  /// Create a copy of JournalEntrySet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JournalEntrySetImplCopyWith<_$JournalEntrySetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
