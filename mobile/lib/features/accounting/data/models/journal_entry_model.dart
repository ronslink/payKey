import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry_model.freezed.dart';
part 'journal_entry_model.g.dart';

@freezed
abstract class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required String accountCode,
    required String accountName,
    required double amount,
    required DateTime date,
    String? description,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}

@freezed
abstract class JournalEntrySet with _$JournalEntrySet {
  const factory JournalEntrySet({
    required List<JournalEntry> entries,
  }) = _JournalEntrySet;

  factory JournalEntrySet.fromJson(Map<String, dynamic> json) =>
      _$JournalEntrySetFromJson(json);
}
