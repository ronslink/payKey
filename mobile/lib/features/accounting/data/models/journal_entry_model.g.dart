// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JournalEntry _$JournalEntryFromJson(Map<String, dynamic> json) =>
    _JournalEntry(
      id: json['id'] as String,
      accountCode: json['accountCode'] as String,
      accountName: json['accountName'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$JournalEntryToJson(_JournalEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountCode': instance.accountCode,
      'accountName': instance.accountName,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'description': instance.description,
    };

_JournalEntrySet _$JournalEntrySetFromJson(Map<String, dynamic> json) =>
    _JournalEntrySet(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JournalEntrySetToJson(_JournalEntrySet instance) =>
    <String, dynamic>{'entries': instance.entries};
