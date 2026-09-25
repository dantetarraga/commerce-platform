import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import type { Env } from '../../config/env';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { OtpService } from './otp/otp.service';
import { LogSmsSender, SmsSender, TwilioSmsSender } from './sms/sms-sender';
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
      useFactory: (config: ConfigService<Env, true>): SmsSender => {
        if (config.get('SMS_PROVIDER', { infer: true }) === 'log') {
          return new LogSmsSender(config.get('NODE_ENV', { infer: true }) !== 'production');
        }
        // env.ts ya validó que existan las credenciales.
        return new TwilioSmsSender({
          accountSid: config.get('TWILIO_ACCOUNT_SID', { infer: true }),
          authToken: config.get('TWILIO_AUTH_TOKEN', { infer: true }),
          countryCode: config.get('SMS_COUNTRY_CODE', { infer: true }),
          messagingServiceSid: config.get('TWILIO_MESSAGING_SERVICE_SID', { infer: true }),
          from: config.get('TWILIO_FROM', { infer: true }),
        });
      },
    },
  ],
  // El guard JWT global (registrado en AppModule) necesita TokensService.
  exports: [TokensService],
})
export class AuthModule {}
