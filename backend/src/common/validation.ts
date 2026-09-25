import { HttpStatus, ValidationError, ValidationPipe } from '@nestjs/common';
import { AppException, ErrorCode } from './exceptions/app.exception';

/**
 * ValidationPipe global. Los errores salen como `VALIDATION_ERROR` con
 * `details.fields = { campo: mensaje }`, que la app convierte en errores por campo.
 */
export function createValidationPipe() {
  return new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    exceptionFactory: (errors) =>
      new AppException(ErrorCode.VALIDATION_ERROR, HttpStatus.BAD_REQUEST, 'Revisa los datos enviados.', {
        fields: flattenErrors(errors),
      }),
  });
}

export function flattenErrors(errors: ValidationError[], parent = ''): Record<string, string> {
  const fields: Record<string, string> = {};
  for (const error of errors) {
    const path = parent ? `${parent}.${error.property}` : error.property;
    const first = error.constraints ? Object.values(error.constraints)[0] : undefined;
    if (first) fields[path] = first;
    if (error.children?.length) Object.assign(fields, flattenErrors(error.children, path));
  }
  return fields;
}
