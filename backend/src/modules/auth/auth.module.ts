import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import type { Env } from '../../config/env';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { OtpService } from './otp/otp.service';
import { LogSmsSender, SmsSender } from './sms/sms-sender';
import { TokensService } from './tokens/tokens.service';

@Module({
  imports: [JwtModule.register({})],
  controllers: [AuthController],
  providers: [
    AuthService,
    OtpService,
    TokensService,
    {
      provide: SmsSender,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) =>
        new LogSmsSender(config.get('NODE_ENV', { infer: true }) !== 'production'),
    },
  ],
  // El guard JWT global (registrado en AppModule) necesita TokensService.
  exports: [TokensService],
})
export class AuthModule {}
