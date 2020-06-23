import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_failure.freezed.dart';

// Something went wrong on the backend 
@freezed
abstract class PhotoFailure with _$PhotoFailure {
  const factory PhotoFailure.serverError() = _ServerError;
  const factory PhotoFailure.invalidPhoto() = _InvalidPhoto;
}