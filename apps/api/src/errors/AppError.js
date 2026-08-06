export class AppError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.name = 'AppError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export function assertFound(value, message = 'Resource not found') {
  if (!value) throw new AppError(404, 'not_found', message);
  return value;
}
