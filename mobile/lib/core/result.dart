/// Encapsula el resultado de una operación que puede ser exitosa o fallar.
class Result<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  factory Result.failure(String error, {int? statusCode}) {
    return Result._(
      error: error,
      statusCode: statusCode,
      isSuccess: false,
    );
  }

  /// Ejecuta [onSuccess] si la operación tuvo éxito o [onFailure] si falló.
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(String error, int? statusCode) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    } else {
      return onFailure(error ?? 'Error desconocido', statusCode);
    }
  }
}
