import { Body, Controller, Headers, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Public } from '../../common/decorators/auth.decorators';
import { AuthService } from './auth.service';
import { RefreshTokenDto, RegisterDto, RequestOtpDto, VerifyOtpDto } from './dto/auth.dto';

const MINUTE_MS = 60_000;

@ApiTags('auth')
@Public()
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('otp/request')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: MINUTE_MS } })
  requestCode(@Body() dto: RequestOtpDto) {
    return this.auth.requestCode(dto.phone);
  }

  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 10, ttl: MINUTE_MS } })
  verifyCode(@Body() dto: VerifyOtpDto, @Headers('user-agent') userAgent?: string) {
    return this.auth.verifyCode(dto.phone, dto.code, userAgent);
  }

  @Post('register')
  @Throttle({ default: { limit: 5, ttl: MINUTE_MS } })
  register(@Body() dto: RegisterDto, @Headers('user-agent') userAgent?: string) {
    return this.auth.register(dto, userAgent);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 20, ttl: MINUTE_MS } })
  refresh(@Body() dto: RefreshTokenDto, @Headers('user-agent') userAgent?: string) {
    return this.auth.refresh(dto.refreshToken, userAgent);
  }

  /** Público e idempotente: revoca la sesión de ese refresh token. */
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  logout(@Body() dto: RefreshTokenDto) {
    return this.auth.logout(dto.refreshToken);
  }
}
