sealed class Result<T> {
  const Result();
  R when<R>({required R Function(T) ok, required R Function(AppError) err}) {
    final self = this;
    if (self is Ok<T>) return ok(self.value);
    if (self is Err<T>) return err(self.error);
    throw StateError('Unknown Result subtype');
  }
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.error);
  final AppError error;
}

enum AppErrorType { network, auth, rateLimit, parse, capability, unknown }

class AppError implements Exception {
  AppError(this.type, {this.message, this.cause, this.statusCode});
  final AppErrorType type;
  final String? message;
  final Object? cause;
  final int? statusCode;
  @override
  String toString() => 'AppError(type: $type, code: $statusCode, message: $message, cause: $cause)';
}

