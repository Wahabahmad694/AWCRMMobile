class ApiResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final String? errorCode;

  const ApiResult.success(this.data)
      : error = null,
        statusCode = null,
        errorCode = null;

  const ApiResult.failure(this.error, {this.statusCode, this.errorCode})
      : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => !isSuccess;
}
