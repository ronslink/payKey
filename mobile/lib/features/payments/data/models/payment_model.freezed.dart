// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return _Transaction.fromJson(json);
}

/// @nodoc
mixin _$Transaction {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get workerId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  TransactionType get type => throw _privateConstructorUsedError;
  TransactionStatus get status => throw _privateConstructorUsedError;
  String? get providerRef => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionCopyWith<Transaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionCopyWith<$Res> {
  factory $TransactionCopyWith(
    Transaction value,
    $Res Function(Transaction) then,
  ) = _$TransactionCopyWithImpl<$Res, Transaction>;
  @useResult
  $Res call({
    String id,
    String userId,
    String? workerId,
    double amount,
    String currency,
    TransactionType type,
    TransactionStatus status,
    String? providerRef,
    Map<String, dynamic>? metadata,
    String createdAt,
  });
}

/// @nodoc
class _$TransactionCopyWithImpl<$Res, $Val extends Transaction>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? workerId = freezed,
    Object? amount = null,
    Object? currency = null,
    Object? type = null,
    Object? status = null,
    Object? providerRef = freezed,
    Object? metadata = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            workerId: freezed == workerId
                ? _value.workerId
                : workerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as TransactionType,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TransactionStatus,
            providerRef: freezed == providerRef
                ? _value.providerRef
                : providerRef // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransactionImplCopyWith<$Res>
    implements $TransactionCopyWith<$Res> {
  factory _$$TransactionImplCopyWith(
    _$TransactionImpl value,
    $Res Function(_$TransactionImpl) then,
  ) = __$$TransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String? workerId,
    double amount,
    String currency,
    TransactionType type,
    TransactionStatus status,
    String? providerRef,
    Map<String, dynamic>? metadata,
    String createdAt,
  });
}

/// @nodoc
class __$$TransactionImplCopyWithImpl<$Res>
    extends _$TransactionCopyWithImpl<$Res, _$TransactionImpl>
    implements _$$TransactionImplCopyWith<$Res> {
  __$$TransactionImplCopyWithImpl(
    _$TransactionImpl _value,
    $Res Function(_$TransactionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? workerId = freezed,
    Object? amount = null,
    Object? currency = null,
    Object? type = null,
    Object? status = null,
    Object? providerRef = freezed,
    Object? metadata = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$TransactionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        workerId: freezed == workerId
            ? _value.workerId
            : workerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as TransactionType,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TransactionStatus,
        providerRef: freezed == providerRef
            ? _value.providerRef
            : providerRef // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionImpl implements _Transaction {
  const _$TransactionImpl({
    required this.id,
    required this.userId,
    this.workerId,
    required this.amount,
    this.currency = 'KES',
    required this.type,
    required this.status,
    this.providerRef,
    final Map<String, dynamic>? metadata,
    required this.createdAt,
  }) : _metadata = metadata;

  factory _$TransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? workerId;
  @override
  final double amount;
  @override
  @JsonKey()
  final String currency;
  @override
  final TransactionType type;
  @override
  final TransactionStatus status;
  @override
  final String? providerRef;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String createdAt;

  @override
  String toString() {
    return 'Transaction(id: $id, userId: $userId, workerId: $workerId, amount: $amount, currency: $currency, type: $type, status: $status, providerRef: $providerRef, metadata: $metadata, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.providerRef, providerRef) ||
                other.providerRef == providerRef) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    workerId,
    amount,
    currency,
    type,
    status,
    providerRef,
    const DeepCollectionEquality().hash(_metadata),
    createdAt,
  );

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      __$$TransactionImplCopyWithImpl<_$TransactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionImplToJson(this);
  }
}

abstract class _Transaction implements Transaction {
  const factory _Transaction({
    required final String id,
    required final String userId,
    final String? workerId,
    required final double amount,
    final String currency,
    required final TransactionType type,
    required final TransactionStatus status,
    final String? providerRef,
    final Map<String, dynamic>? metadata,
    required final String createdAt,
  }) = _$TransactionImpl;

  factory _Transaction.fromJson(Map<String, dynamic> json) =
      _$TransactionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get workerId;
  @override
  double get amount;
  @override
  String get currency;
  @override
  TransactionType get type;
  @override
  TransactionStatus get status;
  @override
  String? get providerRef;
  @override
  Map<String, dynamic>? get metadata;
  @override
  String get createdAt;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TopupRequest _$TopupRequestFromJson(Map<String, dynamic> json) {
  return _TopupRequest.fromJson(json);
}

/// @nodoc
mixin _$TopupRequest {
  String get phoneNumber => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;

  /// Serializes this TopupRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopupRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopupRequestCopyWith<TopupRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopupRequestCopyWith<$Res> {
  factory $TopupRequestCopyWith(
    TopupRequest value,
    $Res Function(TopupRequest) then,
  ) = _$TopupRequestCopyWithImpl<$Res, TopupRequest>;
  @useResult
  $Res call({String phoneNumber, double amount});
}

/// @nodoc
class _$TopupRequestCopyWithImpl<$Res, $Val extends TopupRequest>
    implements $TopupRequestCopyWith<$Res> {
  _$TopupRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopupRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? phoneNumber = null, Object? amount = null}) {
    return _then(
      _value.copyWith(
            phoneNumber: null == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TopupRequestImplCopyWith<$Res>
    implements $TopupRequestCopyWith<$Res> {
  factory _$$TopupRequestImplCopyWith(
    _$TopupRequestImpl value,
    $Res Function(_$TopupRequestImpl) then,
  ) = __$$TopupRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String phoneNumber, double amount});
}

/// @nodoc
class __$$TopupRequestImplCopyWithImpl<$Res>
    extends _$TopupRequestCopyWithImpl<$Res, _$TopupRequestImpl>
    implements _$$TopupRequestImplCopyWith<$Res> {
  __$$TopupRequestImplCopyWithImpl(
    _$TopupRequestImpl _value,
    $Res Function(_$TopupRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TopupRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? phoneNumber = null, Object? amount = null}) {
    return _then(
      _$TopupRequestImpl(
        phoneNumber: null == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TopupRequestImpl implements _TopupRequest {
  const _$TopupRequestImpl({required this.phoneNumber, required this.amount});

  factory _$TopupRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopupRequestImplFromJson(json);

  @override
  final String phoneNumber;
  @override
  final double amount;

  @override
  String toString() {
    return 'TopupRequest(phoneNumber: $phoneNumber, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopupRequestImpl &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, phoneNumber, amount);

  /// Create a copy of TopupRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopupRequestImplCopyWith<_$TopupRequestImpl> get copyWith =>
      __$$TopupRequestImplCopyWithImpl<_$TopupRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopupRequestImplToJson(this);
  }
}

abstract class _TopupRequest implements TopupRequest {
  const factory _TopupRequest({
    required final String phoneNumber,
    required final double amount,
  }) = _$TopupRequestImpl;

  factory _TopupRequest.fromJson(Map<String, dynamic> json) =
      _$TopupRequestImpl.fromJson;

  @override
  String get phoneNumber;
  @override
  double get amount;

  /// Create a copy of TopupRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopupRequestImplCopyWith<_$TopupRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PaymentResponse _$PaymentResponseFromJson(Map<String, dynamic> json) {
  return _PaymentResponse.fromJson(json);
}

/// @nodoc
mixin _$PaymentResponse {
  String get message => throw _privateConstructorUsedError;
  String? get checkoutRequestId => throw _privateConstructorUsedError;
  Transaction? get transaction => throw _privateConstructorUsedError;

  /// Serializes this PaymentResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentResponseCopyWith<PaymentResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentResponseCopyWith<$Res> {
  factory $PaymentResponseCopyWith(
    PaymentResponse value,
    $Res Function(PaymentResponse) then,
  ) = _$PaymentResponseCopyWithImpl<$Res, PaymentResponse>;
  @useResult
  $Res call({
    String message,
    String? checkoutRequestId,
    Transaction? transaction,
  });

  $TransactionCopyWith<$Res>? get transaction;
}

/// @nodoc
class _$PaymentResponseCopyWithImpl<$Res, $Val extends PaymentResponse>
    implements $PaymentResponseCopyWith<$Res> {
  _$PaymentResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? checkoutRequestId = freezed,
    Object? transaction = freezed,
  }) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            checkoutRequestId: freezed == checkoutRequestId
                ? _value.checkoutRequestId
                : checkoutRequestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            transaction: freezed == transaction
                ? _value.transaction
                : transaction // ignore: cast_nullable_to_non_nullable
                      as Transaction?,
          )
          as $Val,
    );
  }

  /// Create a copy of PaymentResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TransactionCopyWith<$Res>? get transaction {
    if (_value.transaction == null) {
      return null;
    }

    return $TransactionCopyWith<$Res>(_value.transaction!, (value) {
      return _then(_value.copyWith(transaction: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PaymentResponseImplCopyWith<$Res>
    implements $PaymentResponseCopyWith<$Res> {
  factory _$$PaymentResponseImplCopyWith(
    _$PaymentResponseImpl value,
    $Res Function(_$PaymentResponseImpl) then,
  ) = __$$PaymentResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String message,
    String? checkoutRequestId,
    Transaction? transaction,
  });

  @override
  $TransactionCopyWith<$Res>? get transaction;
}

/// @nodoc
class __$$PaymentResponseImplCopyWithImpl<$Res>
    extends _$PaymentResponseCopyWithImpl<$Res, _$PaymentResponseImpl>
    implements _$$PaymentResponseImplCopyWith<$Res> {
  __$$PaymentResponseImplCopyWithImpl(
    _$PaymentResponseImpl _value,
    $Res Function(_$PaymentResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? checkoutRequestId = freezed,
    Object? transaction = freezed,
  }) {
    return _then(
      _$PaymentResponseImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        checkoutRequestId: freezed == checkoutRequestId
            ? _value.checkoutRequestId
            : checkoutRequestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        transaction: freezed == transaction
            ? _value.transaction
            : transaction // ignore: cast_nullable_to_non_nullable
                  as Transaction?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentResponseImpl implements _PaymentResponse {
  const _$PaymentResponseImpl({
    required this.message,
    this.checkoutRequestId,
    this.transaction,
  });

  factory _$PaymentResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentResponseImplFromJson(json);

  @override
  final String message;
  @override
  final String? checkoutRequestId;
  @override
  final Transaction? transaction;

  @override
  String toString() {
    return 'PaymentResponse(message: $message, checkoutRequestId: $checkoutRequestId, transaction: $transaction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentResponseImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.checkoutRequestId, checkoutRequestId) ||
                other.checkoutRequestId == checkoutRequestId) &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, message, checkoutRequestId, transaction);

  /// Create a copy of PaymentResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentResponseImplCopyWith<_$PaymentResponseImpl> get copyWith =>
      __$$PaymentResponseImplCopyWithImpl<_$PaymentResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentResponseImplToJson(this);
  }
}

abstract class _PaymentResponse implements PaymentResponse {
  const factory _PaymentResponse({
    required final String message,
    final String? checkoutRequestId,
    final Transaction? transaction,
  }) = _$PaymentResponseImpl;

  factory _PaymentResponse.fromJson(Map<String, dynamic> json) =
      _$PaymentResponseImpl.fromJson;

  @override
  String get message;
  @override
  String? get checkoutRequestId;
  @override
  Transaction? get transaction;

  /// Create a copy of PaymentResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentResponseImplCopyWith<_$PaymentResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
