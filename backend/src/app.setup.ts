import type { INestApplication } from '@nestjs/common';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import type { Express } from 'express';
import helmet from 'helmet';
import { Logger } from 'nestjs-pino';
import { createValidationPipe } from './common/validation';
import { CorsIoAdapter } from './modules/realtime/socket-io.adapter';
import type { Env } from './config/env';

export const API_PREFIX = 'api/v1';

/** Configuración compartida por `main.ts` y los tests e2e. */
export function configureApp(app: INestApplication): void {
  const config = app.get(ConfigService<Env, true>);
  app.useLogger(app.get(Logger));
  app.use(helmet());
  // 100 KB por defecto no alcanza para importar una carta de 500 filas.
  (app as NestExpressApplication).useBodyParser('json', { limit: '1mb' });
  // Detrás de un proxy (Railway), la IP real del cliente viene en X-Forwarded-For.
  const trustProxy = config.get('TRUST_PROXY', { infer: true });
  if (trustProxy > 0) (app.getHttpAdapter().getInstance() as Express).set('trust proxy', trustProxy);
  const origins = config.get('CORS_ORIGINS', { infer: true });
  // credentials: el panel web manda la cookie del refresh token (solo a /auth).
  app.enableCors({ origin: origins, credentials: true });
  app.useWebSocketAdapter(new CorsIoAdapter(app, origins));
  app.setGlobalPrefix(API_PREFIX);
  app.useGlobalPipes(createValidationPipe());
  app.enableShutdownHooks();

  if (config.get('NODE_ENV', { infer: true }) !== 'production') {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().setTitle('Apamuy API').setVersion('0.1.0').addBearerAuth().build(),
    );
    SwaggerModule.setup('docs', app, document);
  }
}
