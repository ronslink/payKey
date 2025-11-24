// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tax_payment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaxPayment _$TaxPaymentFromJson(Map<String, dynamic> json) {
  return _TaxPayment.fromJson(json);
}

/// @nodoc
mixin _$TaxPayment {
  String get id => throw _privateConstructorUsedError;
  TaxType get taxType => throw _privateConstructorUsedError;
  int get paymentYear => throw _privateConstructorUsedError;
  int get paymentMonth => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String? get paymentDate => throw _privateConstructorUsedError;
  PaymentMethod? get paymentMethod => throw _privateConstructorUsedError;
  String? get receiptNumber => throw _privateConstructorUsedError;
  PaymentStatus get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this TaxPayment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaxPayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaxPaymentCopyWith<TaxPayment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaxPaymentCopyWith<$Res> {
  factory $TaxPaymentCopyWith(
    TaxPayment value,
    $Res Function(TaxPayment) then,
  ) = _$TaxPaymentCopyWithImpl<$Res, TaxPayment>;
  @useResult
  $Res call({
    String id,
    TaxType taxType,
    int paymentYear,
    int paymentMonth,
    double amount,
    String? paymentDate,
    PaymentMethod? paymentMethod,
    String? receiptNumber,
    PaymentStatus status,
    String? notes,
    String createdAt,
  });
}

/// @nodoc
class _$TaxPaymentCopyWithImpl<$Res, $Val extends TaxPayment>
    implements $TaxPaymentCopyWith<$Res> {
  _$TaxPaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaxPayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taxType = null,
    Object? paymentYear = null,
    Object? paymentMonth = null,
    Object? amount = null,
    Object? paymentDate = freezed,
    Object? paymentMethod = freezed,
    Object? receiptNumber = freezed,
    Object? status = null,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            taxType: null == taxType
                ? _value.taxType
                : taxType // ignore: cast_nullable_to_non_nullable
                      as TaxType,
            paymentYear: null == paymentYear
                ? _value.paymentYear
                : paymentYear // ignore: cast_nullable_to_non_nullable
                      as int,
            paymentMonth: null == paymentMonth
                ? _value.paymentMonth
                : paymentMonth // ignore: cast_nullable_to_non_nullable
                      as int,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentDate: freezed == paymentDate
                ? _value.paymentDate
                : paymentDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentMethod: freezed == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as PaymentMethod?,
            receiptNumber: freezed == receiptNumber
                ? _value.receiptNumber
                : receiptNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PaymentStatus,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$TaxPaymentImplCopyWith<$Res>
    implements $TaxPaymentCopyWith<$Res> {
  factory _$$TaxPaymentImplCopyWith(
    _$TaxPaymentImpl value,
    $Res Function(_$TaxPaymentImpl) then,
  ) = __$$TaxPaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    TaxType taxType,
    int paymentYear,
    int paymentMonth,
    double amount,
    String? paymentDate,
    PaymentMethod? paymentMethod,
    String? receiptNumber,
    PaymentStatus status,
    String? notes,
    String createdAt,
  });
}

/// @nodoc
class __$$TaxPaymentImplCopyWithImpl<$Res>
    extends _$TaxPaymentCopyWithImpl<$Res, _$TaxPaymentImpl>
    implements _$$TaxPaymentImplCopyWith<$Res> {
  __$$TaxPaymentImplCopyWithImpl(
    _$TaxPaymentImpl _value,
    $Res Function(_$TaxPaymentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaxPayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taxType = null,
    Object? paymentYear = null,
    Object? paymentMonth = null,
    Object? amount = null,
    Object? paymentDate = freezed,
    Object? paymentMethod = freezed,
    Object? receiptNumber = freezed,
    Object? status = null,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$TaxPaymentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        taxType: null == taxType
            ? _value.taxType
            : taxType // ignore: cast_nullable_to_non_nullable
                  as TaxType,
        paymentYear: null == paymentYear
            ? _value.paymentYear
            : paymentYear // ignore: cast_nullable_to_non_nullable
                  as int,
        paymentMonth: null == paymentMonth
            ? _value.paymentMonth
            : paymentMonth // ignore: cast_nullable_to_non_nullable
                  as int,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentDate: freezed == paymentDate
            ? _value.paymentDate
            : paymentDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentMethod: freezed == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as PaymentMethod?,
        receiptNumber: freezed == receiptNumber
            ? _value.receiptNumber
            : receiptNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PaymentStatus,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$TaxPaymentImpl implements _TaxPayment {
  const _$TaxPaymentImpl({
    required this.id,
    required this.taxType,
    required this.paymentYear,
    required this.paymentMonth,
    required this.amount,
    this.paymentDate,
    this.paymentMethod,
    this.receiptNumber,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory _$TaxPaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaxPaymentImplFromJson(json);

  @override
  final String id;
  @override
  final TaxType taxType;
  @override
  final int paymentYear;
  @override
  final int paymentMonth;
  @override
  final double amount;
  @override
  final String? paymentDate;
  @override
  final PaymentMethod? paymentMethod;
  @override
  final String? receiptNumber;
  @override
  final PaymentStatus status;
  @override
  final String? notes;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'TaxPayment(id: $id, taxType: $taxType, paymentYear: $paymentYear, paymentMonth: $paymentMonth, amount: $amount, paymentDate: $paymentDate, paymentMethod: $paymentMethod, receiptNumber: $receiptNumber, status: $status, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaxPaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.taxType, taxType) || other.taxType == taxType) &&
            (identical(other.paymentYear, paymentYear) ||
                other.paymentYear == paymentYear) &&
            (identical(other.paymentMonth, paymentMonth) ||
                other.paymentMonth == paymentMonth) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paymentDate, paymentDate) ||
                other.paymentDate == paymentDate) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.receiptNumber, receiptNumber) ||
                other.receiptNumber == receiptNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    taxType,
    paymentYear,
    paymentMonth,
    amount,
    paymentDate,
    paymentMethod,
    receiptNumber,
    status,
    notes,
    createdAt,
  );

  /// Create a copy of TaxPayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaxPaymentImplCopyWith<_$TaxPaymentImpl> get copyWith =>
      __$$TaxPaymentImplCopyWithImpl<_$TaxPaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaxPaymentImplToJson(this);
  }
}

abstract class _TaxPayment implements TaxPayment {
  const factory _TaxPayment({
    required final String id,
    required final TaxType taxType,
    required final int paymentYear,
    required final int paymentMonth,
    required final double amount,
    final String? paymentDate,
    final PaymentMethod? paymentMethod,
    final String? receiptNumber,
    required final PaymentStatus status,
    final String? notes,
    required final String createdAt,
  }) = _$TaxPaymentImpl;

  factory _TaxPayment.fromJson(Map<String, dynamic> json) =
      _$TaxPaymentImpl.fromJson;

  @override
  String get id;
  @override
  TaxType get taxType;
  @override
  int get paymentYear;
  @override
  int get paymentMonth;
  @override
  double get amount;
  @override
  String? get paymentDate;
  @override
  PaymentMethod? get paymentMethod;
  @override
  String? get receiptNumber;
  @override
  PaymentStatus get status;
  @override
  String? get notes;
  @override
  String get createdAt;

  /// Create a copy of TaxPayment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaxPaymentImplCopyWith<_$TaxPaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TaxSummary _$TaxSummaryFromJson(Map<String, dynamic> json) {
  return _TaxSummary.fromJson(json);
}

/// @nodoc
mixin _$TaxSummary {
  TaxType get taxType => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get dueDate => throw _privateConstructorUsedError;

  /// Serializes this TaxSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaxSummaryCopyWith<TaxSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaxSummaryCopyWith<$Res> {
  factory $TaxSummaryCopyWith(
    TaxSummary value,
    $Res Function(TaxSummary) then,
  ) = _$TaxSummaryCopyWithImpl<$Res, TaxSummary>;
  @useResult
  $Res call({TaxType taxType, double amount, String status, String dueDate});
}

/// @nodoc
class _$TaxSummaryCopyWithImpl<$Res, $Val extends TaxSummary>
    implements $TaxSummaryCopyWith<$Res> {
  _$TaxSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taxType = null,
    Object? amount = null,
    Object? status = null,
    Object? dueDate = null,
  }) {
    return _then(
      _value.copyWith(
            taxType: null == taxType
                ? _value.taxType
                : taxType // ignore: cast_nullable_to_non_nullable
                      as TaxType,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            dueDate: null == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaxSummaryImplCopyWith<$Res>
    implements $TaxSummaryCopyWith<$Res> {
  factory _$$TaxSummaryImplCopyWith(
    _$TaxSummaryImpl value,
    $Res Function(_$TaxSummaryImpl) then,
  ) = __$$TaxSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TaxType taxType, double amount, String status, String dueDate});
}

/// @nodoc
class __$$TaxSummaryImplCopyWithImpl<$Res>
    extends _$TaxSummaryCopyWithImpl<$Res, _$TaxSummaryImpl>
    implements _$$TaxSummaryImplCopyWith<$Res> {
  __$$TaxSummaryImplCopyWithImpl(
    _$TaxSummaryImpl _value,
    $Res Function(_$TaxSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taxType = null,
    Object? amount = null,
    Object? status = null,
    Object? dueDate = null,
  }) {
    return _then(
      _$TaxSummaryImpl(
        taxType: null == taxType
            ? _value.taxType
            : taxType // ignore: cast_nullable_to_non_nullable
                  as TaxType,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        dueDate: null == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaxSummaryImpl implements _TaxSummary {
  const _$TaxSummaryImpl({
    required this.taxType,
    required this.amount,
    required this.status,
    required this.dueDate,
  });

  factory _$TaxSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaxSummaryImplFromJson(json);

  @override
  final TaxType taxType;
  @override
  final double amount;
  @override
  final String status;
  @override
  final String dueDate;

  @override
  String toString() {
    return 'TaxSummary(taxType: $taxType, amount: $amount, status: $status, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaxSummaryImpl &&
            (identical(other.taxType, taxType) || other.taxType == taxType) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, taxType, amount, status, dueDate);

  /// Create a copy of TaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaxSummaryImplCopyWith<_$TaxSummaryImpl> get copyWith =>
      __$$TaxSummaryImplCopyWithImpl<_$TaxSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaxSummaryImplToJson(this);
  }
}

abstract class _TaxSummary implements TaxSummary {
  const factory _TaxSummary({
    required final TaxType taxType,
    required final double amount,
    required final String status,
    required final String dueDate,
  }) = _$TaxSummaryImpl;

  factory _TaxSummary.fromJson(Map<String, dynamic> json) =
      _$TaxSummaryImpl.fromJson;

  @override
  TaxType get taxType;
  @override
  double get amount;
  @override
  String get status;
  @override
  String get dueDate;

  /// Create a copy of TaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaxSummaryImplCopyWith<_$TaxSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MonthlyTaxSummary _$MonthlyTaxSummaryFromJson(Map<String, dynamic> json) {
  return _MonthlyTaxSummary.fromJson(json);
}

/// @nodoc
mixin _$MonthlyTaxSummary {
  int get year => throw _privateConstructorUsedError;
  int get month => throw _privateConstructorUsedError;
  double get totalDue => throw _privateConstructorUsedError;
  double get totalPaid => throw _privateConstructorUsedError;
  List<TaxSummary> get taxes => throw _privateConstructorUsedError;
  PaymentInstructions get paymentInstructions =>
      throw _privateConstructorUsedError;

  /// Serializes this MonthlyTaxSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonthlyTaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonthlyTaxSummaryCopyWith<MonthlyTaxSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlyTaxSummaryCopyWith<$Res> {
  factory $MonthlyTaxSummaryCopyWith(
    MonthlyTaxSummary value,
    $Res Function(MonthlyTaxSummary) then,
  ) = _$MonthlyTaxSummaryCopyWithImpl<$Res, MonthlyTaxSummary>;
  @useResult
  $Res call({
    int year,
    int month,
    double totalDue,
    double totalPaid,
    List<TaxSummary> taxes,
    PaymentInstructions paymentInstructions,
  });

  $PaymentInstructionsCopyWith<$Res> get paymentInstructions;
}

/// @nodoc
class _$MonthlyTaxSummaryCopyWithImpl<$Res, $Val extends MonthlyTaxSummary>
    implements $MonthlyTaxSummaryCopyWith<$Res> {
  _$MonthlyTaxSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonthlyTaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalDue = null,
    Object? totalPaid = null,
    Object? taxes = null,
    Object? paymentInstructions = null,
  }) {
    return _then(
      _value.copyWith(
            year: null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int,
            month: null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
                      as int,
            totalDue: null == totalDue
                ? _value.totalDue
                : totalDue // ignore: cast_nullable_to_non_nullable
                      as double,
            totalPaid: null == totalPaid
                ? _value.totalPaid
                : totalPaid // ignore: cast_nullable_to_non_nullable
                      as double,
            taxes: null == taxes
                ? _value.taxes
                : taxes // ignore: cast_nullable_to_non_nullable
                      as List<TaxSummary>,
            paymentInstructions: null == paymentInstructions
                ? _value.paymentInstructions
                : paymentInstructions // ignore: cast_nullable_to_non_nullable
                      as PaymentInstructions,
          )
          as $Val,
    );
  }

  /// Create a copy of MonthlyTaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaymentInstructionsCopyWith<$Res> get paymentInstructions {
    return $PaymentInstructionsCopyWith<$Res>(_value.paymentInstructions, (
      value,
    ) {
      return _then(_value.copyWith(paymentInstructions: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MonthlyTaxSummaryImplCopyWith<$Res>
    implements $MonthlyTaxSummaryCopyWith<$Res> {
  factory _$$MonthlyTaxSummaryImplCopyWith(
    _$MonthlyTaxSummaryImpl value,
    $Res Function(_$MonthlyTaxSummaryImpl) then,
  ) = __$$MonthlyTaxSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int year,
    int month,
    double totalDue,
    double totalPaid,
    List<TaxSummary> taxes,
    PaymentInstructions paymentInstructions,
  });

  @override
  $PaymentInstructionsCopyWith<$Res> get paymentInstructions;
}

/// @nodoc
class __$$MonthlyTaxSummaryImplCopyWithImpl<$Res>
    extends _$MonthlyTaxSummaryCopyWithImpl<$Res, _$MonthlyTaxSummaryImpl>
    implements _$$MonthlyTaxSummaryImplCopyWith<$Res> {
  __$$MonthlyTaxSummaryImplCopyWithImpl(
    _$MonthlyTaxSummaryImpl _value,
    $Res Function(_$MonthlyTaxSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonthlyTaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalDue = null,
    Object? totalPaid = null,
    Object? taxes = null,
    Object? paymentInstructions = null,
  }) {
    return _then(
      _$MonthlyTaxSummaryImpl(
        year: null == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _value.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
        totalDue: null == totalDue
            ? _value.totalDue
            : totalDue // ignore: cast_nullable_to_non_nullable
                  as double,
        totalPaid: null == totalPaid
            ? _value.totalPaid
            : totalPaid // ignore: cast_nullable_to_non_nullable
                  as double,
        taxes: null == taxes
            ? _value._taxes
            : taxes // ignore: cast_nullable_to_non_nullable
                  as List<TaxSummary>,
        paymentInstructions: null == paymentInstructions
            ? _value.paymentInstructions
            : paymentInstructions // ignore: cast_nullable_to_non_nullable
                  as PaymentInstructions,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MonthlyTaxSummaryImpl implements _MonthlyTaxSummary {
  const _$MonthlyTaxSummaryImpl({
    required this.year,
    required this.month,
    required this.totalDue,
    required this.totalPaid,
    required final List<TaxSummary> taxes,
    required this.paymentInstructions,
  }) : _taxes = taxes;

  factory _$MonthlyTaxSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonthlyTaxSummaryImplFromJson(json);

  @override
  final int year;
  @override
  final int month;
  @override
  final double totalDue;
  @override
  final double totalPaid;
  final List<TaxSummary> _taxes;
  @override
  List<TaxSummary> get taxes {
    if (_taxes is EqualUnmodifiableListView) return _taxes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_taxes);
  }

  @override
  final PaymentInstructions paymentInstructions;

  @override
  String toString() {
    return 'MonthlyTaxSummary(year: $year, month: $month, totalDue: $totalDue, totalPaid: $totalPaid, taxes: $taxes, paymentInstructions: $paymentInstructions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlyTaxSummaryImpl &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalDue, totalDue) ||
                other.totalDue == totalDue) &&
            (identical(other.totalPaid, totalPaid) ||
                other.totalPaid == totalPaid) &&
            const DeepCollectionEquality().equals(other._taxes, _taxes) &&
            (identical(other.paymentInstructions, paymentInstructions) ||
                other.paymentInstructions == paymentInstructions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    year,
    month,
    totalDue,
    totalPaid,
    const DeepCollectionEquality().hash(_taxes),
    paymentInstructions,
  );

  /// Create a copy of MonthlyTaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlyTaxSummaryImplCopyWith<_$MonthlyTaxSummaryImpl> get copyWith =>
      __$$MonthlyTaxSummaryImplCopyWithImpl<_$MonthlyTaxSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MonthlyTaxSummaryImplToJson(this);
  }
}

abstract class _MonthlyTaxSummary implements MonthlyTaxSummary {
  const factory _MonthlyTaxSummary({
    required final int year,
    required final int month,
    required final double totalDue,
    required final double totalPaid,
    required final List<TaxSummary> taxes,
    required final PaymentInstructions paymentInstructions,
  }) = _$MonthlyTaxSummaryImpl;

  factory _MonthlyTaxSummary.fromJson(Map<String, dynamic> json) =
      _$MonthlyTaxSummaryImpl.fromJson;

  @override
  int get year;
  @override
  int get month;
  @override
  double get totalDue;
  @override
  double get totalPaid;
  @override
  List<TaxSummary> get taxes;
  @override
  PaymentInstructions get paymentInstructions;

  /// Create a copy of MonthlyTaxSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlyTaxSummaryImplCopyWith<_$MonthlyTaxSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PaymentInstructions _$PaymentInstructionsFromJson(Map<String, dynamic> json) {
  return _PaymentInstructions.fromJson(json);
}

/// @nodoc
mixin _$PaymentInstructions {
  MpesaInstructions get mpesa => throw _privateConstructorUsedError;
  String get bank => throw _privateConstructorUsedError;
  String get deadline => throw _privateConstructorUsedError;

  /// Serializes this PaymentInstructions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentInstructions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentInstructionsCopyWith<PaymentInstructions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentInstructionsCopyWith<$Res> {
  factory $PaymentInstructionsCopyWith(
    PaymentInstructions value,
    $Res Function(PaymentInstructions) then,
  ) = _$PaymentInstructionsCopyWithImpl<$Res, PaymentInstructions>;
  @useResult
  $Res call({MpesaInstructions mpesa, String bank, String deadline});

  $MpesaInstructionsCopyWith<$Res> get mpesa;
}

/// @nodoc
class _$PaymentInstructionsCopyWithImpl<$Res, $Val extends PaymentInstructions>
    implements $PaymentInstructionsCopyWith<$Res> {
  _$PaymentInstructionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentInstructions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mpesa = null,
    Object? bank = null,
    Object? deadline = null,
  }) {
    return _then(
      _value.copyWith(
            mpesa: null == mpesa
                ? _value.mpesa
                : mpesa // ignore: cast_nullable_to_non_nullable
                      as MpesaInstructions,
            bank: null == bank
                ? _value.bank
                : bank // ignore: cast_nullable_to_non_nullable
                      as String,
            deadline: null == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of PaymentInstructions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MpesaInstructionsCopyWith<$Res> get mpesa {
    return $MpesaInstructionsCopyWith<$Res>(_value.mpesa, (value) {
      return _then(_value.copyWith(mpesa: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PaymentInstructionsImplCopyWith<$Res>
    implements $PaymentInstructionsCopyWith<$Res> {
  factory _$$PaymentInstructionsImplCopyWith(
    _$PaymentInstructionsImpl value,
    $Res Function(_$PaymentInstructionsImpl) then,
  ) = __$$PaymentInstructionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MpesaInstructions mpesa, String bank, String deadline});

  @override
  $MpesaInstructionsCopyWith<$Res> get mpesa;
}

/// @nodoc
class __$$PaymentInstructionsImplCopyWithImpl<$Res>
    extends _$PaymentInstructionsCopyWithImpl<$Res, _$PaymentInstructionsImpl>
    implements _$$PaymentInstructionsImplCopyWith<$Res> {
  __$$PaymentInstructionsImplCopyWithImpl(
    _$PaymentInstructionsImpl _value,
    $Res Function(_$PaymentInstructionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentInstructions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mpesa = null,
    Object? bank = null,
    Object? deadline = null,
  }) {
    return _then(
      _$PaymentInstructionsImpl(
        mpesa: null == mpesa
            ? _value.mpesa
            : mpesa // ignore: cast_nullable_to_non_nullable
                  as MpesaInstructions,
        bank: null == bank
            ? _value.bank
            : bank // ignore: cast_nullable_to_non_nullable
                  as String,
        deadline: null == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentInstructionsImpl implements _PaymentInstructions {
  const _$PaymentInstructionsImpl({
    required this.mpesa,
    required this.bank,
    required this.deadline,
  });

  factory _$PaymentInstructionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentInstructionsImplFromJson(json);

  @override
  final MpesaInstructions mpesa;
  @override
  final String bank;
  @override
  final String deadline;

  @override
  String toString() {
    return 'PaymentInstructions(mpesa: $mpesa, bank: $bank, deadline: $deadline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentInstructionsImpl &&
            (identical(other.mpesa, mpesa) || other.mpesa == mpesa) &&
            (identical(other.bank, bank) || other.bank == bank) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, mpesa, bank, deadline);

  /// Create a copy of PaymentInstructions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentInstructionsImplCopyWith<_$PaymentInstructionsImpl> get copyWith =>
      __$$PaymentInstructionsImplCopyWithImpl<_$PaymentInstructionsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentInstructionsImplToJson(this);
  }
}

abstract class _PaymentInstructions implements PaymentInstructions {
  const factory _PaymentInstructions({
    required final MpesaInstructions mpesa,
    required final String bank,
    required final String deadline,
  }) = _$PaymentInstructionsImpl;

  factory _PaymentInstructions.fromJson(Map<String, dynamic> json) =
      _$PaymentInstructionsImpl.fromJson;

  @override
  MpesaInstructions get mpesa;
  @override
  String get bank;
  @override
  String get deadline;

  /// Create a copy of PaymentInstructions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentInstructionsImplCopyWith<_$PaymentInstructionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MpesaInstructions _$MpesaInstructionsFromJson(Map<String, dynamic> json) {
  return _MpesaInstructions.fromJson(json);
}

/// @nodoc
mixin _$MpesaInstructions {
  String get paybill => throw _privateConstructorUsedError;
  String get accountNumber => throw _privateConstructorUsedError;

  /// Serializes this MpesaInstructions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MpesaInstructions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MpesaInstructionsCopyWith<MpesaInstructions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MpesaInstructionsCopyWith<$Res> {
  factory $MpesaInstructionsCopyWith(
    MpesaInstructions value,
    $Res Function(MpesaInstructions) then,
  ) = _$MpesaInstructionsCopyWithImpl<$Res, MpesaInstructions>;
  @useResult
  $Res call({String paybill, String accountNumber});
}

/// @nodoc
class _$MpesaInstructionsCopyWithImpl<$Res, $Val extends MpesaInstructions>
    implements $MpesaInstructionsCopyWith<$Res> {
  _$MpesaInstructionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MpesaInstructions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? paybill = null, Object? accountNumber = null}) {
    return _then(
      _value.copyWith(
            paybill: null == paybill
                ? _value.paybill
                : paybill // ignore: cast_nullable_to_non_nullable
                      as String,
            accountNumber: null == accountNumber
                ? _value.accountNumber
                : accountNumber // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MpesaInstructionsImplCopyWith<$Res>
    implements $MpesaInstructionsCopyWith<$Res> {
  factory _$$MpesaInstructionsImplCopyWith(
    _$MpesaInstructionsImpl value,
    $Res Function(_$MpesaInstructionsImpl) then,
  ) = __$$MpesaInstructionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String paybill, String accountNumber});
}

/// @nodoc
class __$$MpesaInstructionsImplCopyWithImpl<$Res>
    extends _$MpesaInstructionsCopyWithImpl<$Res, _$MpesaInstructionsImpl>
    implements _$$MpesaInstructionsImplCopyWith<$Res> {
  __$$MpesaInstructionsImplCopyWithImpl(
    _$MpesaInstructionsImpl _value,
    $Res Function(_$MpesaInstructionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MpesaInstructions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? paybill = null, Object? accountNumber = null}) {
    return _then(
      _$MpesaInstructionsImpl(
        paybill: null == paybill
            ? _value.paybill
            : paybill // ignore: cast_nullable_to_non_nullable
                  as String,
        accountNumber: null == accountNumber
            ? _value.accountNumber
            : accountNumber // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MpesaInstructionsImpl implements _MpesaInstructions {
  const _$MpesaInstructionsImpl({
    required this.paybill,
    required this.accountNumber,
  });

  factory _$MpesaInstructionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MpesaInstructionsImplFromJson(json);

  @override
  final String paybill;
  @override
  final String accountNumber;

  @override
  String toString() {
    return 'MpesaInstructions(paybill: $paybill, accountNumber: $accountNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MpesaInstructionsImpl &&
            (identical(other.paybill, paybill) || other.paybill == paybill) &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, paybill, accountNumber);

  /// Create a copy of MpesaInstructions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MpesaInstructionsImplCopyWith<_$MpesaInstructionsImpl> get copyWith =>
      __$$MpesaInstructionsImplCopyWithImpl<_$MpesaInstructionsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MpesaInstructionsImplToJson(this);
  }
}

abstract class _MpesaInstructions implements MpesaInstructions {
  const factory _MpesaInstructions({
    required final String paybill,
    required final String accountNumber,
  }) = _$MpesaInstructionsImpl;

  factory _MpesaInstructions.fromJson(Map<String, dynamic> json) =
      _$MpesaInstructionsImpl.fromJson;

  @override
  String get paybill;
  @override
  String get accountNumber;

  /// Create a copy of MpesaInstructions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MpesaInstructionsImplCopyWith<_$MpesaInstructionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TaxPaymentRequest _$TaxPaymentRequestFromJson(Map<String, dynamic> json) {
  return _TaxPaymentRequest.fromJson(json);
}

/// @nodoc
mixin _$TaxPaymentRequest {
  TaxType get taxType => throw _privateConstructorUsedError;
  int get paymentYear => throw _privateConstructorUsedError;
  int get paymentMonth => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String? get paymentDate => throw _privateConstructorUsedError;
  PaymentMethod? get paymentMethod => throw _privateConstructorUsedError;
  String? get receiptNumber => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this TaxPaymentRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaxPaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaxPaymentRequestCopyWith<TaxPaymentRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaxPaymentRequestCopyWith<$Res> {
  factory $TaxPaymentRequestCopyWith(
    TaxPaymentRequest value,
    $Res Function(TaxPaymentRequest) then,
  ) = _$TaxPaymentRequestCopyWithImpl<$Res, TaxPaymentRequest>;
  @useResult
  $Res call({
    TaxType taxType,
    int paymentYear,
    int paymentMonth,
    double amount,
    String? paymentDate,
    PaymentMethod? paymentMethod,
    String? receiptNumber,
    String? notes,
  });
}

/// @nodoc
class _$TaxPaymentRequestCopyWithImpl<$Res, $Val extends TaxPaymentRequest>
    implements $TaxPaymentRequestCopyWith<$Res> {
  _$TaxPaymentRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaxPaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taxType = null,
    Object? paymentYear = null,
    Object? paymentMonth = null,
    Object? amount = null,
    Object? paymentDate = freezed,
    Object? paymentMethod = freezed,
    Object? receiptNumber = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            taxType: null == taxType
                ? _value.taxType
                : taxType // ignore: cast_nullable_to_non_nullable
                      as TaxType,
            paymentYear: null == paymentYear
                ? _value.paymentYear
                : paymentYear // ignore: cast_nullable_to_non_nullable
                      as int,
            paymentMonth: null == paymentMonth
                ? _value.paymentMonth
                : paymentMonth // ignore: cast_nullable_to_non_nullable
                      as int,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentDate: freezed == paymentDate
                ? _value.paymentDate
                : paymentDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentMethod: freezed == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as PaymentMethod?,
            receiptNumber: freezed == receiptNumber
                ? _value.receiptNumber
                : receiptNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaxPaymentRequestImplCopyWith<$Res>
    implements $TaxPaymentRequestCopyWith<$Res> {
  factory _$$TaxPaymentRequestImplCopyWith(
    _$TaxPaymentRequestImpl value,
    $Res Function(_$TaxPaymentRequestImpl) then,
  ) = __$$TaxPaymentRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    TaxType taxType,
    int paymentYear,
    int paymentMonth,
    double amount,
    String? paymentDate,
    PaymentMethod? paymentMethod,
    String? receiptNumber,
    String? notes,
  });
}

/// @nodoc
class __$$TaxPaymentRequestImplCopyWithImpl<$Res>
    extends _$TaxPaymentRequestCopyWithImpl<$Res, _$TaxPaymentRequestImpl>
    implements _$$TaxPaymentRequestImplCopyWith<$Res> {
  __$$TaxPaymentRequestImplCopyWithImpl(
    _$TaxPaymentRequestImpl _value,
    $Res Function(_$TaxPaymentRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaxPaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taxType = null,
    Object? paymentYear = null,
    Object? paymentMonth = null,
    Object? amount = null,
    Object? paymentDate = freezed,
    Object? paymentMethod = freezed,
    Object? receiptNumber = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$TaxPaymentRequestImpl(
        taxType: null == taxType
            ? _value.taxType
            : taxType // ignore: cast_nullable_to_non_nullable
                  as TaxType,
        paymentYear: null == paymentYear
            ? _value.paymentYear
            : paymentYear // ignore: cast_nullable_to_non_nullable
                  as int,
        paymentMonth: null == paymentMonth
            ? _value.paymentMonth
            : paymentMonth // ignore: cast_nullable_to_non_nullable
                  as int,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentDate: freezed == paymentDate
            ? _value.paymentDate
            : paymentDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentMethod: freezed == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as PaymentMethod?,
        receiptNumber: freezed == receiptNumber
            ? _value.receiptNumber
            : receiptNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaxPaymentRequestImpl implements _TaxPaymentRequest {
  const _$TaxPaymentRequestImpl({
    required this.taxType,
    required this.paymentYear,
    required this.paymentMonth,
    required this.amount,
    this.paymentDate,
    this.paymentMethod,
    this.receiptNumber,
    this.notes,
  });

  factory _$TaxPaymentRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaxPaymentRequestImplFromJson(json);

  @override
  final TaxType taxType;
  @override
  final int paymentYear;
  @override
  final int paymentMonth;
  @override
  final double amount;
  @override
  final String? paymentDate;
  @override
  final PaymentMethod? paymentMethod;
  @override
  final String? receiptNumber;
  @override
  final String? notes;

  @override
  String toString() {
    return 'TaxPaymentRequest(taxType: $taxType, paymentYear: $paymentYear, paymentMonth: $paymentMonth, amount: $amount, paymentDate: $paymentDate, paymentMethod: $paymentMethod, receiptNumber: $receiptNumber, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaxPaymentRequestImpl &&
            (identical(other.taxType, taxType) || other.taxType == taxType) &&
            (identical(other.paymentYear, paymentYear) ||
                other.paymentYear == paymentYear) &&
            (identical(other.paymentMonth, paymentMonth) ||
                other.paymentMonth == paymentMonth) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paymentDate, paymentDate) ||
                other.paymentDate == paymentDate) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.receiptNumber, receiptNumber) ||
                other.receiptNumber == receiptNumber) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    taxType,
    paymentYear,
    paymentMonth,
    amount,
    paymentDate,
    paymentMethod,
    receiptNumber,
    notes,
  );

  /// Create a copy of TaxPaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaxPaymentRequestImplCopyWith<_$TaxPaymentRequestImpl> get copyWith =>
      __$$TaxPaymentRequestImplCopyWithImpl<_$TaxPaymentRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TaxPaymentRequestImplToJson(this);
  }
}

abstract class _TaxPaymentRequest implements TaxPaymentRequest {
  const factory _TaxPaymentRequest({
    required final TaxType taxType,
    required final int paymentYear,
    required final int paymentMonth,
    required final double amount,
    final String? paymentDate,
    final PaymentMethod? paymentMethod,
    final String? receiptNumber,
    final String? notes,
  }) = _$TaxPaymentRequestImpl;

  factory _TaxPaymentRequest.fromJson(Map<String, dynamic> json) =
      _$TaxPaymentRequestImpl.fromJson;

  @override
  TaxType get taxType;
  @override
  int get paymentYear;
  @override
  int get paymentMonth;
  @override
  double get amount;
  @override
  String? get paymentDate;
  @override
  PaymentMethod? get paymentMethod;
  @override
  String? get receiptNumber;
  @override
  String? get notes;

  /// Create a copy of TaxPaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaxPaymentRequestImplCopyWith<_$TaxPaymentRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
