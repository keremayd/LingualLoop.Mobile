import 'package:json_annotation/json_annotation.dart';

part 'ApiResponse.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final T? data;
  final String? message;
  final String? errorCode;
  final String? code;

  ApiResponse({
    this.data,
    this.message,
    this.errorCode,
    this.code,
  });

  // JSON'dan dönüştürme
  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT,) =>
      _$ApiResponseFromJson(json, fromJsonT);

  // JSON'a dönüştürme
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}
