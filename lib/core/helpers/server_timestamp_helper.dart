import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

class ServerNullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const ServerNullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is String) return DateTime.tryParse(json);
    return null;
  }

  @override
  Object? toJson(DateTime? date) {
    return date != null ? Timestamp.fromDate(date) : null;
  }
}

class ServerTimestampOnNullConverter implements JsonConverter<DateTime?, Object?> {
  const ServerTimestampOnNullConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is String) return DateTime.tryParse(json);
    return null;
  }

  @override
  Object? toJson(DateTime? date) {
    return date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp();
  }
}
class ServerTimestampListConverter implements JsonConverter<List<DateTime>, List<dynamic>> {
  const ServerTimestampListConverter();

  @override
  List<DateTime> fromJson(List<dynamic> json) {
    return json.map((e) {
      if (e is Timestamp) return e.toDate();
      if (e is DateTime) return e;
      if (e is String) return DateTime.tryParse(e)!;
      throw ArgumentError('Unsupported date type in list: $e');
    }).toList();
  }

  @override
  List<dynamic> toJson(List<DateTime> dates) {
    return dates.map((e) => Timestamp.fromDate(e)).toList();
  }
}

final dateFormat = DateFormat('yyyy-MM-dd');

final monthKeyFormat = DateFormat('yyyy-MM');
