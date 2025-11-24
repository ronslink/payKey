// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaxPaymentImpl _$$TaxPaymentImplFromJson(Map<String, dynamic> json) =>
    _$TaxPaymentImpl(
      id: json['id'] as String,
      taxType: $enumDecode(_$TaxTypeEnumMap, json['taxType']),
      paymentYear: (json['paymentYear'] as num).toInt(),
      paymentMonth: (json['paymentMonth'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['paymentDate'] as String?,
      paymentMethod: $enumDecodeNullable(
        _$PaymentMethodEnumMap,
        json['paymentMethod'],
      ),
      receiptNumber: json['receiptNumber'] as String?,
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$TaxPaymentImplToJson(_$TaxPaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taxType': _$TaxTypeEnumMap[instance.taxType]!,
      'paymentYear': instance.paymentYear,
      'paymentMonth': instance.paymentMonth,
      'amount': instance.amount,
      'paymentDate': instance.paymentDate,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
      'receiptNumber': instance.receiptNumber,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
    };

const _$TaxTypeEnumMap = {
  TaxType.paye: 'PAYE',
  TaxType.shif: 'SHIF',
  TaxType.nssfTier1: 'NSSF_TIER1',
  TaxType.nssfTier2: 'NSSF_TIER2',
  TaxType.housingLevy: 'HOUSING_LEVY',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.mpesa: 'MPESA',
  PaymentMethod.bank: 'BANK',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'PENDING',
  PaymentStatus.paid: 'PAID',
  PaymentStatus.overdue: 'OVERDUE',
};

_$TaxSummaryImpl _$$TaxSummaryImplFromJson(Map<String, dynamic> json) =>
    _$TaxSummaryImpl(
      taxType: $enumDecode(_$TaxTypeEnumMap, json['taxType']),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      dueDate: json['dueDate'] as String,
    );

Map<String, dynamic> _$$TaxSummaryImplToJson(_$TaxSummaryImpl instance) =>
    <String, dynamic>{
      'taxType': _$TaxTypeEnumMap[instance.taxType]!,
      'amount': instance.amount,
      'status': instance.status,
      'dueDate': instance.dueDate,
    };

_$MonthlyTaxSummaryImpl _$$MonthlyTaxSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$MonthlyTaxSummaryImpl(
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  totalDue: (json['totalDue'] as num).toDouble(),
  totalPaid: (json['totalPaid'] as num).toDouble(),
  taxes: (json['taxes'] as List<dynamic>)
      .map((e) => TaxSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  paymentInstructions: PaymentInstructions.fromJson(
    json['paymentInstructions'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$MonthlyTaxSummaryImplToJson(
  _$MonthlyTaxSummaryImpl instance,
) => <String, dynamic>{
  'year': instance.year,
  'month': instance.month,
  'totalDue': instance.totalDue,
  'totalPaid': instance.totalPaid,
  'taxes': instance.taxes,
  'paymentInstructions': instance.paymentInstructions,
};

_$PaymentInstructionsImpl _$$PaymentInstructionsImplFromJson(
  Map<String, dynamic> json,
) => _$PaymentInstructionsImpl(
  mpesa: MpesaInstructions.fromJson(json['mpesa'] as Map<String, dynamic>),
  bank: json['bank'] as String,
  deadline: json['deadline'] as String,
);

Map<String, dynamic> _$$PaymentInstructionsImplToJson(
  _$PaymentInstructionsImpl instance,
) => <String, dynamic>{
  'mpesa': instance.mpesa,
  'bank': instance.bank,
  'deadline': instance.deadline,
};

_$MpesaInstructionsImpl _$$MpesaInstructionsImplFromJson(
  Map<String, dynamic> json,
) => _$MpesaInstructionsImpl(
  paybill: json['paybill'] as String,
  accountNumber: json['accountNumber'] as String,
);

Map<String, dynamic> _$$MpesaInstructionsImplToJson(
  _$MpesaInstructionsImpl instance,
) => <String, dynamic>{
  'paybill': instance.paybill,
  'accountNumber': instance.accountNumber,
};

_$TaxPaymentRequestImpl _$$TaxPaymentRequestImplFromJson(
  Map<String, dynamic> json,
) => _$TaxPaymentRequestImpl(
  taxType: $enumDecode(_$TaxTypeEnumMap, json['taxType']),
  paymentYear: (json['paymentYear'] as num).toInt(),
  paymentMonth: (json['paymentMonth'] as num).toInt(),
  amount: (json['amount'] as num).toDouble(),
  paymentDate: json['paymentDate'] as String?,
  paymentMethod: $enumDecodeNullable(
    _$PaymentMethodEnumMap,
    json['paymentMethod'],
  ),
  receiptNumber: json['receiptNumber'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$TaxPaymentRequestImplToJson(
  _$TaxPaymentRequestImpl instance,
) => <String, dynamic>{
  'taxType': _$TaxTypeEnumMap[instance.taxType]!,
  'paymentYear': instance.paymentYear,
  'paymentMonth': instance.paymentMonth,
  'amount': instance.amount,
  'paymentDate': instance.paymentDate,
  'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
  'receiptNumber': instance.receiptNumber,
  'notes': instance.notes,
};
