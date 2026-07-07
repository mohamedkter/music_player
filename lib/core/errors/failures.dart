import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Using sealed classes ensures exhaustive handling at every call site.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Failures from the local storage layer (Isar, shared_preferences).
final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'A storage error occurred.']);
}

/// Failures from the media scanner / MediaStore.
final class MediaScanFailure extends Failure {
  const MediaScanFailure([super.message = 'Failed to scan media library.']);
}

/// Failures related to missing or denied permissions.
final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Required permission was denied.']);
}

/// Failures from the audio playback engine.
final class AudioFailure extends Failure {
  const AudioFailure([super.message = 'Audio playback error.']);
}

/// Failures when a requested resource is not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

/// Catch-all for unexpected failures.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
