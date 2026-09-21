/// Helpers for sending date ranges to the API.
///
/// The API parses a bare ISO string with no timezone offset as UTC, so sending
/// a local `DateTime` with `toIso8601String()` shifts the window by the device's
/// UTC offset — a device at UTC+3 asking for "today" between 00:00 and 00:00
/// actually asks for 03:00 today until 03:00 tomorrow, which silently drops the
/// entries either side of the range.
///
/// Always describe the intended local day and convert the boundary to a real
/// UTC instant with these helpers.
class ApiDateRange {
  const ApiDateRange._();

  /// Start of [date]'s local day, as a UTC instant.
  static String startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day).toUtc().toIso8601String();

  /// End of [date]'s local day, as a UTC instant.
  static String endOfDay(DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      ).toUtc().toIso8601String();

  /// The whole local day [date] as the API's two bounds.
  static (String, String) day(DateTime date) =>
      (startOfDay(date), endOfDay(date));
}
