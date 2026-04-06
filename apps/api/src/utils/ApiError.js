class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }

  static badRequest(message, code = 'VALIDATION_ERROR') {
    return new ApiError(400, code, message);
  }

  static unauthorized(message = 'Unauthorized') {
    return new ApiError(401, 'UNAUTHORIZED', message);
  }

  static forbidden(message = 'Forbidden') {
    return new ApiError(403, 'FORBIDDEN', message);
  }

  static notFound(message = 'Not found') {
    return new ApiError(404, 'NOT_FOUND', message);
  }

  static conflict(message, code = 'DUPLICATE_TRANSACTION') {
    return new ApiError(409, code, message);
  }

  static unprocessable(message, code) {
    return new ApiError(422, code, message);
  }
}

module.exports = ApiError;
