import { Body, Controller, Headers, HttpCode, HttpStatus, Post, Req, Res } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { Request, Response } from 'express';
import { Public } from '../../common/decorators/auth.decorators';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import type { Env } from '../../config/env';
import { AuthService } from './auth.service';
import { RefreshTokenDto, RegisterDto, RequestOtpDto, VerifyOtpDto } from './dto/auth.dto';
import {
  clearRefreshCookie,
  isWebClient,
  readRefreshCookie,
  setRefreshCookie,
  type SessionCookieConfig,
} from './session-cookie';
import type { SessionTokens } from './tokens/tokens.service';

const MINUTE_MS = 60_000;
const DAY_MS = 24 * 60 * MINUTE_MS;

@ApiTags('auth')
@Public()
@Controller('auth')
export class AuthController {
  private readonly cookie: SessionCookieConfig;

  constructor(
    private readonly auth: AuthService,
    config: ConfigService<Env, true>,
  ) {
    this.cookie = {
      secure: config.get('NODE_ENV', { infer: true }) === 'production',
      sameSite: config.get('AUTH_COOKIE_SAMESITE', { infer: true }),
      maxAgeMs: config.get('REFRESH_TOKEN_TTL_DAYS', { infer: true }) * DAY_MS,
    };
  }

  @Post('otp/request')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: MINUTE_MS } })
  requestCode(@Body() dto: RequestOtpDto) {
    return this.auth.requestCode(dto.phone);
  }

  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 10, ttl: MINUTE_MS } })
  async verifyCode(
    @Body() dto: VerifyOtpDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
    @Headers('user-agent') userAgent?: string,
  ) {
    const result = await this.auth.verifyCode(dto.phone, dto.code, userAgent);
    return result.status === 'AUTHENTICATED' ? this.deliver(result, req, res) : result;
  }

  @Post('register')
  @Throttle({ default: { limit: 5, ttl: MINUTE_MS } })
  async register(
    @Body() dto: RegisterDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
    @Headers('user-agent') userAgent?: string,
  ) {
    return this.deliver(await this.auth.register(dto, userAgent), req, res);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 20, ttl: MINUTE_MS } })
  async refresh(
    @Body() dto: RefreshTokenDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
    @Headers('user-agent') userAgent?: string,
  ) {
    const token = this.tokenFrom(dto, req);
    if (!token) {
      throw new AppException(
        ErrorCode.INVALID_REFRESH_TOKEN,
        HttpStatus.UNAUTHORIZED,
        'Tu sesión expiró. Vuelve a ingresar.',
      );
    }
    try {
      return this.deliver(await this.auth.refresh(token, userAgent), req, res);
    } catch (error) {
      // Una cookie vencida o ya usada no debe quedarse en el navegador.
      if (isWebClient(req)) clearRefreshCookie(res, this.cookie);
      throw error;
    }
  }

  /** Público e idempotente: revoca la sesión de ese refresh token. */
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() dto: RefreshTokenDto, @Req() req: Request, @Res({ passthrough: true }) res: Response) {
    const token = this.tokenFrom(dto, req);
    if (isWebClient(req)) clearRefreshCookie(res, this.cookie);
    if (token) await this.auth.logout(token);
  }

  /** El cuerpo manda (las apps); el panel web usa la cookie. */
  private tokenFrom(dto: RefreshTokenDto, req: Request): string | undefined {
    return dto.refreshToken ?? (isWebClient(req) ? readRefreshCookie(req) : undefined);
  }

  /** Al panel web le pone la cookie y le quita el refresh token del cuerpo. */
  private deliver<T extends SessionTokens>(result: T, req: Request, res: Response) {
    if (!isWebClient(req)) return result;
    setRefreshCookie(res, result.refreshToken, this.cookie);
    return { ...result, refreshToken: undefined };
  }
}
