/// Lightweight Either monad for functional error handling.
/// Avoids throwing exceptions across layer boundaries.
///
/// Usage:
/// ```dart
/// Either<Failure, List<Song>> result = await repository.getSongs();
/// result.fold(
///   (failure) => emit(ErrorState(failure.message)),
///   (songs)   => emit(LoadedState(songs)),
/// );
/// ```
sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L get left => (this as Left<L, R>).value;
  R get right => (this as Right<L, R>).value;

  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    return switch (this) {
      Left<L, R>(value: final l) => onLeft(l),
      Right<L, R>(value: final r) => onRight(r),
    };
  }

  Either<L, T> map<T>(T Function(R) transform) {
    return switch (this) {
      Left<L, R>() => Left<L, T>(left),
      Right<L, R>(value: final r) => Right<L, T>(transform(r)),
    };
  }
}

final class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;
}

final class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;
}

/// Convenience constructors
Either<L, R> left<L, R>(L value) => Left(value);
Either<L, R> right<L, R>(R value) => Right(value);
