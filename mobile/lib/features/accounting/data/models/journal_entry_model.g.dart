// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JournalEntryImpl _$$JournalEntryImplFromJson(Map<String, dynamic> json) =>
    _$JournalEntryImpl(
      id: json['id'] as String,
      accountCode: json['accountCode'] as String,
      accountName: json['accountName'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$JournalEntryImplToJson(_$JournalEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountCode': instance.accountCode,
      'accountName': instance.accountName,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'description': instance.description,
    };

_$JournalEntrySetImpl _$$JournalEntrySetImplFromJson(
  Map<String, dynamic> json,
) => _$JournalEntrySetImpl(
  entries: (json['entries'] as List<dynamic>)
      .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$JournalEntrySetImplToJson(
  _$JournalEntrySetImpl instance,
) => <String, dynamic>{'entries': instance.entries};
