/// Base class for all data-layer exceptions.
/// These are caught in repositories and converted to [Failure]s.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class StorageException extends AppException {
  const StorageException([super.message = 'Storage operation failed.']);
}

final class MediaScanException extends AppException {
  const MediaScanException([super.message = 'Media scan failed.']);
}

final class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied.']);
}

final class AudioException extends AppException {
  const AudioException([super.message = 'Audio engine error.']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found.']);
}
