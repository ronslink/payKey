import 'package:freezed_annotation/freezed_annotation.dart';

part 'holiday_model.freezed.dart';
part 'holiday_model.g.dart';

@freezed
abstract class HolidayModel with _$HolidayModel {
  const factory HolidayModel({
    required String id,
    required String name,
    required DateTime date,
    required bool isRecurring,
    String? description,
  }) = _HolidayModel;

  factory HolidayModel.fromJson(Map<String, dynamic> json) =>
      _$HolidayModelFromJson(json);
}
