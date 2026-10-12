import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Env } from '../../config/env';
import { DisabledObjectStorage, ObjectStorage, R2ObjectStorage } from './object-storage';
import { UploadsController } from './uploads.controller';
import { UploadsService } from './uploads.service';

@Module({
  controllers: [UploadsController],
  providers: [
    UploadsService,
    {
      provide: ObjectStorage,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): ObjectStorage => {
        if (config.get('STORAGE_PROVIDER', { infer: true }) === 'none') return new DisabledObjectStorage();
        // env.ts ya validó que estén todas.
        return new R2ObjectStorage({
          accountId: config.get('R2_ACCOUNT_ID', { infer: true }),
          accessKeyId: config.get('R2_ACCESS_KEY_ID', { infer: true }),
          secretAccessKey: config.get('R2_SECRET_ACCESS_KEY', { infer: true }),
          bucket: config.get('R2_BUCKET', { infer: true }),
          publicUrl: config.get('R2_PUBLIC_URL', { infer: true }),
        });
      },
    },
  ],
})
export class UploadsModule {}
