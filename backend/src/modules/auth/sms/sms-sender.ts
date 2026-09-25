import { Injectable, Logger } from '@nestjs/common';

/** Envío de SMS detrás de una abstracción: el proveedor real se enchufa aquí. */
export abstract class SmsSender {
  abstract send(phone: string, message: string): Promise<void>;
}

/**
 * Mientras no hay proveedor de SMS: escribe el mensaje en el log. En
 * producción no se loguea el contenido para no filtrar códigos.
 */
@Injectable()
export class LogSmsSender extends SmsSender {
  private readonly logger = new Logger('SMS');

  constructor(private readonly logContent: boolean) {
    super();
  }

  send(phone: string, message: string): Promise<void> {
    this.logger.log(this.logContent ? `→ ${phone}: ${message}` : `→ ${phone} (contenido oculto)`);
    return Promise.resolve();
  }
}
