import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { ThrottlerException } from '@nestjs/throttler';
import type { Request, Response } from 'express';
import { Prisma } from '../../generated/prisma/client';
import { AppException, ErrorCode } from '../exceptions/app.exception';

interface ErrorBody {
  statusCode: number;
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

const byStatus: Record<number, { code: ErrorCode; message: string }> = {
  400: { code: ErrorCode.BAD_REQUEST, message: 'La solicitud no es válida.' },
  401: { code: ErrorCode.UNAUTHORIZED, message: 'Inicia sesión para continuar.' },
  403: { code: ErrorCode.FORBIDDEN, message: 'No tienes permiso para hacer esto.' },
  404: { code: ErrorCode.NOT_FOUND, message: 'No encontramos lo que buscas.' },
  409: { code: ErrorCode.CONFLICT, message: 'Hubo un conflicto con los datos actuales.' },
  429: { code: ErrorCode.RATE_LIMITED, message: 'Demasiados intentos. Espera un momento y vuelve a intentarlo.' },
};

/**
 * Formato de error único para toda la API:
 * `{ statusCode, code, message, details?, requestId }`.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const http = host.switchToHttp();
    const request = http.getRequest<Request & { id?: string }>();
    const response = http.getResponse<Response>();

    const body = this.toBody(exception);
    if (body.statusCode >= 500) {
      this.logger.error(exception instanceof Error ? (exception.stack ?? exception.message) : String(exception));
    }
    response.status(body.statusCode).json({ ...body, requestId: request.id });
  }

  private toBody(exception: unknown): ErrorBody {
    if (exception instanceof AppException) {
      return {
        statusCode: exception.getStatus(),
        code: exception.code,
        message: exception.message,
        details: exception.details,
      };
    }
    if (exception instanceof ThrottlerException) {
      return { statusCode: HttpStatus.TOO_MANY_REQUESTS, ...byStatus[429] };
    }
    if (exception instanceof HttpException) {
      const statusCode = exception.getStatus();
      const known = byStatus[statusCode];
      if (known) return { statusCode, ...known };
      return statusCode >= 500
        ? internal()
        : { statusCode, code: ErrorCode.BAD_REQUEST, message: byStatus[400].message };
    }
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') return { statusCode: HttpStatus.CONFLICT, ...byStatus[409] };
      if (exception.code === 'P2025') return { statusCode: HttpStatus.NOT_FOUND, ...byStatus[404] };
    }
    return internal();
  }
}

function internal(): ErrorBody {
  return {
    statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
    code: ErrorCode.INTERNAL_ERROR,
    message: 'Algo salió mal de nuestro lado. Inténtalo de nuevo en un momento.',
  };
}
