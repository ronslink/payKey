// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaxBreakdown _$TaxBreakdownFromJson(Map<String, dynamic> json) {
  return _TaxBreakdown.fromJson(json);
}

/// @nodoc
mixin _$TaxBreakdown {
  /// National Social Security Fund contribution
  double get nssf => throw _privateConstructorUsedError;

  /// National Hospital Insurance Fund contribution
  double get nhif => throw _privateConstructorUsedError;

  /// Affordable Housing Levy (1.5% of gross salary)
  double get housingLevy => throw _privateConstructorUsedError;

  /// Pay As You Earn tax
  double get paye => throw _privateConstructorUsedError;

  /// Sum of all deductions (nssf + nhif + housingLevy + paye)
  double get totalDeductions => throw _privateConstructorUsedError;

  /// Serializes this TaxBreakdown to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaxBreakdownCopyWith<TaxBreakdown> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaxBreakdownCopyWith<$Res> {
  factory $TaxBreakdownCopyWith(
    TaxBreakdown value,
    $Res Function(TaxBreakdown) then,
  ) = _$TaxBreakdownCopyWithImpl<$Res, TaxBreakdown>;
  @useResult
  $Res call({
    double nssf,
    double nhif,
    double housingLevy,
    double paye,
    double totalDeductions,
  });
}

/// @nodoc
class _$TaxBreakdownCopyWithImpl<$Res, $Val extends TaxBreakdown>
    implements $TaxBreakdownCopyWith<$Res> {
  _$TaxBreakdownCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nssf = null,
    Object? nhif = null,
    Object? housingLevy = null,
    Object? paye = null,
    Object? totalDeductions = null,
  }) {
    return _then(
      _value.copyWith(
            nssf: null == nssf
                ? _value.nssf
                : nssf // ignore: cast_nullable_to_non_nullable
                      as double,
            nhif: null == nhif
                ? _value.nhif
                : nhif // ignore: cast_nullable_to_non_nullable
                      as double,
            housingLevy: null == housingLevy
                ? _value.housingLevy
                : housingLevy // ignore: cast_nullable_to_non_nullable
                      as double,
            paye: null == paye
                ? _value.paye
                : paye // ignore: cast_nullable_to_non_nullable
                      as double,
            totalDeductions: null == totalDeductions
                ? _value.totalDeductions
                : totalDeductions // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaxBreakdownImplCopyWith<$Res>
    implements $TaxBreakdownCopyWith<$Res> {
  factory _$$TaxBreakdownImplCopyWith(
    _$TaxBreakdownImpl value,
    $Res Function(_$TaxBreakdownImpl) then,
  ) = __$$TaxBreakdownImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double nssf,
    double nhif,
    double housingLevy,
    double paye,
    double totalDeductions,
  });
}

/// @nodoc
class __$$TaxBreakdownImplCopyWithImpl<$Res>
    extends _$TaxBreakdownCopyWithImpl<$Res, _$TaxBreakdownImpl>
    implements _$$TaxBreakdownImplCopyWith<$Res> {
  __$$TaxBreakdownImplCopyWithImpl(
    _$TaxBreakdownImpl _value,
    $Res Function(_$TaxBreakdownImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nssf = null,
    Object? nhif = null,
    Object? housingLevy = null,
    Object? paye = null,
    Object? totalDeductions = null,
  }) {
    return _then(
      _$TaxBreakdownImpl(
        nssf: null == nssf
            ? _value.nssf
            : nssf // ignore: cast_nullable_to_non_nullable
                  as double,
        nhif: null == nhif
            ? _value.nhif
            : nhif // ignore: cast_nullable_to_non_nullable
                  as double,
        housingLevy: null == housingLevy
            ? _value.housingLevy
            : housingLevy // ignore: cast_nullable_to_non_nullable
                  as double,
        paye: null == paye
            ? _value.paye
            : paye // ignore: cast_nullable_to_non_nullable
                  as double,
        totalDeductions: null == totalDeductions
            ? _value.totalDeductions
            : totalDeductions // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaxBreakdownImpl extends _TaxBreakdown {
  const _$TaxBreakdownImpl({
    required this.nssf,
    required this.nhif,
    required this.housingLevy,
    required this.paye,
    required this.totalDeductions,
  }) : super._();

  factory _$TaxBreakdownImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaxBreakdownImplFromJson(json);

  /// National Social Security Fund contribution
  @override
  final double nssf;

  /// National Hospital Insurance Fund contribution
  @override
  final double nhif;

  /// Affordable Housing Levy (1.5% of gross salary)
  @override
  final double housingLevy;

  /// Pay As You Earn tax
  @override
  final double paye;

  /// Sum of all deductions (nssf + nhif + housingLevy + paye)
  @override
  final double totalDeductions;

  @override
  String toString() {
    return 'TaxBreakdown(nssf: $nssf, nhif: $nhif, housingLevy: $housingLevy, paye: $paye, totalDeductions: $totalDeductions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaxBreakdownImpl &&
            (identical(other.nssf, nssf) || other.nssf == nssf) &&
            (identical(other.nhif, nhif) || other.nhif == nhif) &&
            (identical(other.housingLevy, housingLevy) ||
                other.housingLevy == housingLevy) &&
            (identical(other.paye, paye) || other.paye == paye) &&
            (identical(other.totalDeductions, totalDeductions) ||
                other.totalDeductions == totalDeductions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, nssf, nhif, housingLevy, paye, totalDeductions);

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaxBreakdownImplCopyWith<_$TaxBreakdownImpl> get copyWith =>
      __$$TaxBreakdownImplCopyWithImpl<_$TaxBreakdownImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaxBreakdownImplToJson(this);
  }
}

abstract class _TaxBreakdown extends TaxBreakdown {
  const factory _TaxBreakdown({
    required final double nssf,
    required final double nhif,
    required final double housingLevy,
    required final double paye,
    required final double totalDeductions,
  }) = _$TaxBreakdownImpl;
  const _TaxBreakdown._() : super._();

  factory _TaxBreakdown.fromJson(Map<String, dynamic> json) =
      _$TaxBreakdownImpl.fromJson;

  /// National Social Security Fund contribution
  @override
  double get nssf;

  /// National Hospital Insurance Fund contribution
  @override
  double get nhif;

  /// Affordable Housing Levy (1.5% of gross salary)
  @override
  double get housingLevy;

  /// Pay As You Earn tax
  @override
  double get paye;

  /// Sum of all deductions (nssf + nhif + housingLevy + paye)
  @override
  double get totalDeductions;

  /// Create a copy of TaxBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaxBreakdownImplCopyWith<_$TaxBreakdownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollCalculation _$PayrollCalculationFromJson(Map<String, dynamic> json) {
  return _PayrollCalculation.fromJson(json);
}

/// @nodoc
mixin _$PayrollCalculation {
  /// Unique identifier. Null for new/unsaved calculations.
  String? get id => throw _privateConstructorUsedError;

  /// Reference to the worker this calculation belongs to.
  String get workerId => throw _privateConstructorUsedError;

  /// Worker's display name (denormalized for convenience).
  String get workerName => throw _privateConstructorUsedError;

  /// Base salary before any additions or deductions.
  double get grossSalary => throw _privateConstructorUsedError;

  /// Additional bonus payments.
  double get bonuses => throw _privateConstructorUsedError;

  /// Other earnings (allowances, overtime, etc.).
  double get otherEarnings => throw _privateConstructorUsedError;

  /// Additional deductions (loans, advances, etc.).
  double get otherDeductions => throw _privateConstructorUsedError;

  /// Breakdown of statutory tax deductions.
  TaxBreakdown get taxBreakdown => throw _privateConstructorUsedError;

  /// Final amount payable to worker.
  double get netPay => throw _privateConstructorUsedError;

  /// Current status in the payroll workflow.
  String get status => throw _privateConstructorUsedError;

  /// Whether this calculation has been manually edited.
  bool get isEdited => throw _privateConstructorUsedError;

  /// Serializes this PayrollCalculation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollCalculation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollCalculationCopyWith<PayrollCalculation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollCalculationCopyWith<$Res> {
  factory $PayrollCalculationCopyWith(
    PayrollCalculation value,
    $Res Function(PayrollCalculation) then,
  ) = _$PayrollCalculationCopyWithImpl<$Res, PayrollCalculation>;
  @useResult
  $Res call({
    String? id,
    String workerId,
    String workerName,
    double grossSalary,
    double bonuses,
    double otherEarnings,
    double otherDeductions,
    TaxBreakdown taxBreakdown,
    double netPay,
    String status,
    bool isEdited,
  });

  $TaxBreakdownCopyWith<$Res> get taxBreakdown;
}

/// @nodoc
class _$PayrollCalculationCopyWithImpl<$Res, $Val extends PayrollCalculation>
    implements $PayrollCalculationCopyWith<$Res> {
  _$PayrollCalculationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollCalculation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? workerId = null,
    Object? workerName = null,
    Object? grossSalary = null,
    Object? bonuses = null,
    Object? otherEarnings = null,
    Object? otherDeductions = null,
    Object? taxBreakdown = null,
    Object? netPay = null,
    Object? status = null,
    Object? isEdited = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            workerId: null == workerId
                ? _value.workerId
                : workerId // ignore: cast_nullable_to_non_nullable
                      as String,
            workerName: null == workerName
                ? _value.workerName
                : workerName // ignore: cast_nullable_to_non_nullable
                      as String,
            grossSalary: null == grossSalary
                ? _value.grossSalary
                : grossSalary // ignore: cast_nullable_to_non_nullable
                      as double,
            bonuses: null == bonuses
                ? _value.bonuses
                : bonuses // ignore: cast_nullable_to_non_nullable
                      as double,
            otherEarnings: null == otherEarnings
                ? _value.otherEarnings
                : otherEarnings // ignore: cast_nullable_to_non_nullable
                      as double,
            otherDeductions: null == otherDeductions
                ? _value.otherDeductions
                : otherDeductions // ignore: cast_nullable_to_non_nullable
                      as double,
            taxBreakdown: null == taxBreakdown
                ? _value.taxBreakdown
                : taxBreakdown // ignore: cast_nullable_to_non_nullable
                      as TaxBreakdown,
            netPay: null == netPay
                ? _value.netPay
                : netPay // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            isEdited: null == isEdited
                ? _value.isEdited
                : isEdited // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of PayrollCalculation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TaxBreakdownCopyWith<$Res> get taxBreakdown {
    return $TaxBreakdownCopyWith<$Res>(_value.taxBreakdown, (value) {
      return _then(_value.copyWith(taxBreakdown: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PayrollCalculationImplCopyWith<$Res>
    implements $PayrollCalculationCopyWith<$Res> {
  factory _$$PayrollCalculationImplCopyWith(
    _$PayrollCalculationImpl value,
    $Res Function(_$PayrollCalculationImpl) then,
  ) = __$$PayrollCalculationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    String workerId,
    String workerName,
    double grossSalary,
    double bonuses,
    double otherEarnings,
    double otherDeductions,
    TaxBreakdown taxBreakdown,
    double netPay,
    String status,
    bool isEdited,
  });

  @override
  $TaxBreakdownCopyWith<$Res> get taxBreakdown;
}

/// @nodoc
class __$$PayrollCalculationImplCopyWithImpl<$Res>
    extends _$PayrollCalculationCopyWithImpl<$Res, _$PayrollCalculationImpl>
    implements _$$PayrollCalculationImplCopyWith<$Res> {
  __$$PayrollCalculationImplCopyWithImpl(
    _$PayrollCalculationImpl _value,
    $Res Function(_$PayrollCalculationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollCalculation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? workerId = null,
    Object? workerName = null,
    Object? grossSalary = null,
    Object? bonuses = null,
    Object? otherEarnings = null,
    Object? otherDeductions = null,
    Object? taxBreakdown = null,
    Object? netPay = null,
    Object? status = null,
    Object? isEdited = null,
  }) {
    return _then(
      _$PayrollCalculationImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        workerId: null == workerId
            ? _value.workerId
            : workerId // ignore: cast_nullable_to_non_nullable
                  as String,
        workerName: null == workerName
            ? _value.workerName
            : workerName // ignore: cast_nullable_to_non_nullable
                  as String,
        grossSalary: null == grossSalary
            ? _value.grossSalary
            : grossSalary // ignore: cast_nullable_to_non_nullable
                  as double,
        bonuses: null == bonuses
            ? _value.bonuses
            : bonuses // ignore: cast_nullable_to_non_nullable
                  as double,
        otherEarnings: null == otherEarnings
            ? _value.otherEarnings
            : otherEarnings // ignore: cast_nullable_to_non_nullable
                  as double,
        otherDeductions: null == otherDeductions
            ? _value.otherDeductions
            : otherDeductions // ignore: cast_nullable_to_non_nullable
                  as double,
        taxBreakdown: null == taxBreakdown
            ? _value.taxBreakdown
            : taxBreakdown // ignore: cast_nullable_to_non_nullable
                  as TaxBreakdown,
        netPay: null == netPay
            ? _value.netPay
            : netPay // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        isEdited: null == isEdited
            ? _value.isEdited
            : isEdited // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollCalculationImpl extends _PayrollCalculation {
  const _$PayrollCalculationImpl({
    this.id,
    required this.workerId,
    required this.workerName,
    required this.grossSalary,
    this.bonuses = 0,
    this.otherEarnings = 0,
    this.otherDeductions = 0,
    required this.taxBreakdown,
    required this.netPay,
    this.status = PayrollStatus.draft,
    this.isEdited = false,
  }) : super._();

  factory _$PayrollCalculationImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollCalculationImplFromJson(json);

  /// Unique identifier. Null for new/unsaved calculations.
  @override
  final String? id;

  /// Reference to the worker this calculation belongs to.
  @override
  final String workerId;

  /// Worker's display name (denormalized for convenience).
  @override
  final String workerName;

  /// Base salary before any additions or deductions.
  @override
  final double grossSalary;

  /// Additional bonus payments.
  @override
  @JsonKey()
  final double bonuses;

  /// Other earnings (allowances, overtime, etc.).
  @override
  @JsonKey()
  final double otherEarnings;

  /// Additional deductions (loans, advances, etc.).
  @override
  @JsonKey()
  final double otherDeductions;

  /// Breakdown of statutory tax deductions.
  @override
  final TaxBreakdown taxBreakdown;

  /// Final amount payable to worker.
  @override
  final double netPay;

  /// Current status in the payroll workflow.
  @override
  @JsonKey()
  final String status;

  /// Whether this calculation has been manually edited.
  @override
  @JsonKey()
  final bool isEdited;

  @override
  String toString() {
    return 'PayrollCalculation(id: $id, workerId: $workerId, workerName: $workerName, grossSalary: $grossSalary, bonuses: $bonuses, otherEarnings: $otherEarnings, otherDeductions: $otherDeductions, taxBreakdown: $taxBreakdown, netPay: $netPay, status: $status, isEdited: $isEdited)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollCalculationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.workerName, workerName) ||
                other.workerName == workerName) &&
            (identical(other.grossSalary, grossSalary) ||
                other.grossSalary == grossSalary) &&
            (identical(other.bonuses, bonuses) || other.bonuses == bonuses) &&
            (identical(other.otherEarnings, otherEarnings) ||
                other.otherEarnings == otherEarnings) &&
            (identical(other.otherDeductions, otherDeductions) ||
                other.otherDeductions == otherDeductions) &&
            (identical(other.taxBreakdown, taxBreakdown) ||
                other.taxBreakdown == taxBreakdown) &&
            (identical(other.netPay, netPay) || other.netPay == netPay) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    workerId,
    workerName,
    grossSalary,
    bonuses,
    otherEarnings,
    otherDeductions,
    taxBreakdown,
    netPay,
    status,
    isEdited,
  );

  /// Create a copy of PayrollCalculation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollCalculationImplCopyWith<_$PayrollCalculationImpl> get copyWith =>
      __$$PayrollCalculationImplCopyWithImpl<_$PayrollCalculationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollCalculationImplToJson(this);
  }
}

abstract class _PayrollCalculation extends PayrollCalculation {
  const factory _PayrollCalculation({
    final String? id,
    required final String workerId,
    required final String workerName,
    required final double grossSalary,
    final double bonuses,
    final double otherEarnings,
    final double otherDeductions,
    required final TaxBreakdown taxBreakdown,
    required final double netPay,
    final String status,
    final bool isEdited,
  }) = _$PayrollCalculationImpl;
  const _PayrollCalculation._() : super._();

  factory _PayrollCalculation.fromJson(Map<String, dynamic> json) =
      _$PayrollCalculationImpl.fromJson;

  /// Unique identifier. Null for new/unsaved calculations.
  @override
  String? get id;

  /// Reference to the worker this calculation belongs to.
  @override
  String get workerId;

  /// Worker's display name (denormalized for convenience).
  @override
  String get workerName;

  /// Base salary before any additions or deductions.
  @override
  double get grossSalary;

  /// Additional bonus payments.
  @override
  double get bonuses;

  /// Other earnings (allowances, overtime, etc.).
  @override
  double get otherEarnings;

  /// Additional deductions (loans, advances, etc.).
  @override
  double get otherDeductions;

  /// Breakdown of statutory tax deductions.
  @override
  TaxBreakdown get taxBreakdown;

  /// Final amount payable to worker.
  @override
  double get netPay;

  /// Current status in the payroll workflow.
  @override
  String get status;

  /// Whether this calculation has been manually edited.
  @override
  bool get isEdited;

  /// Create a copy of PayrollCalculation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollCalculationImplCopyWith<_$PayrollCalculationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollRequest _$PayrollRequestFromJson(Map<String, dynamic> json) {
  return _PayrollRequest.fromJson(json);
}

/// @nodoc
mixin _$PayrollRequest {
  /// List of worker IDs to calculate payroll for.
  List<String> get workerIds => throw _privateConstructorUsedError;

  /// Serializes this PayrollRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollRequestCopyWith<PayrollRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollRequestCopyWith<$Res> {
  factory $PayrollRequestCopyWith(
    PayrollRequest value,
    $Res Function(PayrollRequest) then,
  ) = _$PayrollRequestCopyWithImpl<$Res, PayrollRequest>;
  @useResult
  $Res call({List<String> workerIds});
}

/// @nodoc
class _$PayrollRequestCopyWithImpl<$Res, $Val extends PayrollRequest>
    implements $PayrollRequestCopyWith<$Res> {
  _$PayrollRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? workerIds = null}) {
    return _then(
      _value.copyWith(
            workerIds: null == workerIds
                ? _value.workerIds
                : workerIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollRequestImplCopyWith<$Res>
    implements $PayrollRequestCopyWith<$Res> {
  factory _$$PayrollRequestImplCopyWith(
    _$PayrollRequestImpl value,
    $Res Function(_$PayrollRequestImpl) then,
  ) = __$$PayrollRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> workerIds});
}

/// @nodoc
class __$$PayrollRequestImplCopyWithImpl<$Res>
    extends _$PayrollRequestCopyWithImpl<$Res, _$PayrollRequestImpl>
    implements _$$PayrollRequestImplCopyWith<$Res> {
  __$$PayrollRequestImplCopyWithImpl(
    _$PayrollRequestImpl _value,
    $Res Function(_$PayrollRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? workerIds = null}) {
    return _then(
      _$PayrollRequestImpl(
        workerIds: null == workerIds
            ? _value._workerIds
            : workerIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollRequestImpl extends _PayrollRequest {
  const _$PayrollRequestImpl({required final List<String> workerIds})
    : _workerIds = workerIds,
      super._();

  factory _$PayrollRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollRequestImplFromJson(json);

  /// List of worker IDs to calculate payroll for.
  final List<String> _workerIds;

  /// List of worker IDs to calculate payroll for.
  @override
  List<String> get workerIds {
    if (_workerIds is EqualUnmodifiableListView) return _workerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workerIds);
  }

  @override
  String toString() {
    return 'PayrollRequest(workerIds: $workerIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollRequestImpl &&
            const DeepCollectionEquality().equals(
              other._workerIds,
              _workerIds,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_workerIds));

  /// Create a copy of PayrollRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollRequestImplCopyWith<_$PayrollRequestImpl> get copyWith =>
      __$$PayrollRequestImplCopyWithImpl<_$PayrollRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollRequestImplToJson(this);
  }
}

abstract class _PayrollRequest extends PayrollRequest {
  const factory _PayrollRequest({required final List<String> workerIds}) =
      _$PayrollRequestImpl;
  const _PayrollRequest._() : super._();

  factory _PayrollRequest.fromJson(Map<String, dynamic> json) =
      _$PayrollRequestImpl.fromJson;

  /// List of worker IDs to calculate payroll for.
  @override
  List<String> get workerIds;

  /// Create a copy of PayrollRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollRequestImplCopyWith<_$PayrollRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PayrollSummary _$PayrollSummaryFromJson(Map<String, dynamic> json) {
  return _PayrollSummary.fromJson(json);
}

/// @nodoc
mixin _$PayrollSummary {
  /// Individual payroll calculations.
  List<PayrollCalculation> get calculations =>
      throw _privateConstructorUsedError;

  /// Sum of all gross salaries.
  double get totalGross => throw _privateConstructorUsedError;

  /// Sum of all deductions.
  double get totalDeductions => throw _privateConstructorUsedError;

  /// Sum of all net pay amounts.
  double get totalNet => throw _privateConstructorUsedError;

  /// Serializes this PayrollSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollSummaryCopyWith<PayrollSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollSummaryCopyWith<$Res> {
  factory $PayrollSummaryCopyWith(
    PayrollSummary value,
    $Res Function(PayrollSummary) then,
  ) = _$PayrollSummaryCopyWithImpl<$Res, PayrollSummary>;
  @useResult
  $Res call({
    List<PayrollCalculation> calculations,
    double totalGross,
    double totalDeductions,
    double totalNet,
  });
}

/// @nodoc
class _$PayrollSummaryCopyWithImpl<$Res, $Val extends PayrollSummary>
    implements $PayrollSummaryCopyWith<$Res> {
  _$PayrollSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calculations = null,
    Object? totalGross = null,
    Object? totalDeductions = null,
    Object? totalNet = null,
  }) {
    return _then(
      _value.copyWith(
            calculations: null == calculations
                ? _value.calculations
                : calculations // ignore: cast_nullable_to_non_nullable
                      as List<PayrollCalculation>,
            totalGross: null == totalGross
                ? _value.totalGross
                : totalGross // ignore: cast_nullable_to_non_nullable
                      as double,
            totalDeductions: null == totalDeductions
                ? _value.totalDeductions
                : totalDeductions // ignore: cast_nullable_to_non_nullable
                      as double,
            totalNet: null == totalNet
                ? _value.totalNet
                : totalNet // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollSummaryImplCopyWith<$Res>
    implements $PayrollSummaryCopyWith<$Res> {
  factory _$$PayrollSummaryImplCopyWith(
    _$PayrollSummaryImpl value,
    $Res Function(_$PayrollSummaryImpl) then,
  ) = __$$PayrollSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<PayrollCalculation> calculations,
    double totalGross,
    double totalDeductions,
    double totalNet,
  });
}

/// @nodoc
class __$$PayrollSummaryImplCopyWithImpl<$Res>
    extends _$PayrollSummaryCopyWithImpl<$Res, _$PayrollSummaryImpl>
    implements _$$PayrollSummaryImplCopyWith<$Res> {
  __$$PayrollSummaryImplCopyWithImpl(
    _$PayrollSummaryImpl _value,
    $Res Function(_$PayrollSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calculations = null,
    Object? totalGross = null,
    Object? totalDeductions = null,
    Object? totalNet = null,
  }) {
    return _then(
      _$PayrollSummaryImpl(
        calculations: null == calculations
            ? _value._calculations
            : calculations // ignore: cast_nullable_to_non_nullable
                  as List<PayrollCalculation>,
        totalGross: null == totalGross
            ? _value.totalGross
            : totalGross // ignore: cast_nullable_to_non_nullable
                  as double,
        totalDeductions: null == totalDeductions
            ? _value.totalDeductions
            : totalDeductions // ignore: cast_nullable_to_non_nullable
                  as double,
        totalNet: null == totalNet
            ? _value.totalNet
            : totalNet // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollSummaryImpl extends _PayrollSummary {
  const _$PayrollSummaryImpl({
    required final List<PayrollCalculation> calculations,
    required this.totalGross,
    required this.totalDeductions,
    required this.totalNet,
  }) : _calculations = calculations,
       super._();

  factory _$PayrollSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollSummaryImplFromJson(json);

  /// Individual payroll calculations.
  final List<PayrollCalculation> _calculations;

  /// Individual payroll calculations.
  @override
  List<PayrollCalculation> get calculations {
    if (_calculations is EqualUnmodifiableListView) return _calculations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_calculations);
  }

  /// Sum of all gross salaries.
  @override
  final double totalGross;

  /// Sum of all deductions.
  @override
  final double totalDeductions;

  /// Sum of all net pay amounts.
  @override
  final double totalNet;

  @override
  String toString() {
    return 'PayrollSummary(calculations: $calculations, totalGross: $totalGross, totalDeductions: $totalDeductions, totalNet: $totalNet)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollSummaryImpl &&
            const DeepCollectionEquality().equals(
              other._calculations,
              _calculations,
            ) &&
            (identical(other.totalGross, totalGross) ||
                other.totalGross == totalGross) &&
            (identical(other.totalDeductions, totalDeductions) ||
                other.totalDeductions == totalDeductions) &&
            (identical(other.totalNet, totalNet) ||
                other.totalNet == totalNet));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_calculations),
    totalGross,
    totalDeductions,
    totalNet,
  );

  /// Create a copy of PayrollSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollSummaryImplCopyWith<_$PayrollSummaryImpl> get copyWith =>
      __$$PayrollSummaryImplCopyWithImpl<_$PayrollSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollSummaryImplToJson(this);
  }
}

abstract class _PayrollSummary extends PayrollSummary {
  const factory _PayrollSummary({
    required final List<PayrollCalculation> calculations,
    required final double totalGross,
    required final double totalDeductions,
    required final double totalNet,
  }) = _$PayrollSummaryImpl;
  const _PayrollSummary._() : super._();

  factory _PayrollSummary.fromJson(Map<String, dynamic> json) =
      _$PayrollSummaryImpl.fromJson;

  /// Individual payroll calculations.
  @override
  List<PayrollCalculation> get calculations;

  /// Sum of all gross salaries.
  @override
  double get totalGross;

  /// Sum of all deductions.
  @override
  double get totalDeductions;

  /// Sum of all net pay amounts.
  @override
  double get totalNet;

  /// Create a copy of PayrollSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollSummaryImplCopyWith<_$PayrollSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
