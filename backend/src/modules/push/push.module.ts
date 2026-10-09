import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Env } from '../../config/env';
import { PushController } from './push.controller';
import { FcmPushSender, LogPushSender, PushSender, type FcmServiceAccount } from './push-sender';
import { PushService } from './push.service';

@Module({
  controllers: [PushController],
  providers: [
    PushService,
    {
      provide: PushSender,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): PushSender => {
        if (config.get('PUSH_PROVIDER', { infer: true }) === 'log') return new LogPushSender();
        // env.ts ya validó que la cuenta de servicio exista y tenga los campos.
        const raw = config.get('FCM_SERVICE_ACCOUNT_BASE64', { infer: true }) ?? '';
        return new FcmPushSender(JSON.parse(Buffer.from(raw, 'base64').toString('utf8')) as FcmServiceAccount);
      },
    },
  ],
  exports: [PushService],
})
export class PushModule {}
