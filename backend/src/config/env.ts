import { z } from 'zod';

const port = z.coerce.number().int().positive();

export const envSchema = z
  .object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: port.default(3000),
    DATABASE_URL: z.url({ protocol: /^postgres(ql)?$/ }),
    CORS_ORIGINS: z
      .string()
      .default('')
      .transform((value) =>
        value
          .split(',')
          .map((origin) => origin.trim())
          .filter(Boolean),
      ),
    JWT_ACCESS_SECRET: z.string().min(32),
    JWT_ACCESS_TTL_SECONDS: port.default(900),
    REFRESH_TOKEN_TTL_DAYS: port.default(30),
    OTP_TTL_SECONDS: port.default(300),
    OTP_RESEND_SECONDS: z.coerce.number().int().nonnegative().default(30),
    OTP_MAX_ATTEMPTS: port.default(5),
    OTP_DEV_CODE: z
      .string()
      .regex(/^\d{6}$/)
      .optional(),
    /** HMAC de los códigos OTP; distinto del JWT para poder rotarlos por separado. */
    OTP_SECRET: z.string().min(32),
    SMS_PROVIDER: z.enum(['log', 'twilio']).default('log'),
    SMS_COUNTRY_CODE: z
      .string()
      .regex(/^\+\d{1,3}$/)
      .default('+51'),
    TWILIO_ACCOUNT_SID: z
      .string()
      .regex(/^AC\w{32}$/)
      .optional(),
    TWILIO_AUTH_TOKEN: z.string().min(16).optional(),
    /** Número remitente (+1…) o, mejor, un Messaging Service (MG…). */
    TWILIO_FROM: z
      .string()
      .regex(/^\+\d{6,15}$/)
      .optional(),
    TWILIO_MESSAGING_SERVICE_SID: z
      .string()
      .regex(/^MG\w{32}$/)
      .optional(),
    /** Saltos de proxy delante de la API (Railway: 1). Sin esto, el rate limit ve una sola IP. */
    TRUST_PROXY: z.coerce.number().int().nonnegative().default(0),
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  })
  .superRefine((env, ctx) => {
    const fail = (path: string, message: string) => ctx.addIssue({ code: 'custom', path: [path], message });
    if (env.NODE_ENV === 'production') {
      if (env.OTP_DEV_CODE) fail('OTP_DEV_CODE', 'OTP_DEV_CODE no se permite en producción');
      if (env.SMS_PROVIDER !== 'twilio') fail('SMS_PROVIDER', 'En producción los códigos se envían por Twilio');
    }
    if (env.SMS_PROVIDER === 'twilio') {
      if (!env.TWILIO_ACCOUNT_SID) fail('TWILIO_ACCOUNT_SID', 'Requerido con SMS_PROVIDER=twilio');
      if (!env.TWILIO_AUTH_TOKEN) fail('TWILIO_AUTH_TOKEN', 'Requerido con SMS_PROVIDER=twilio');
      if (!env.TWILIO_FROM && !env.TWILIO_MESSAGING_SERVICE_SID) {
        fail('TWILIO_MESSAGING_SERVICE_SID', 'Configura TWILIO_MESSAGING_SERVICE_SID o TWILIO_FROM');
      }
    }
    if (env.OTP_SECRET === env.JWT_ACCESS_SECRET) fail('OTP_SECRET', 'Debe ser distinto de JWT_ACCESS_SECRET');
  });

export type Env = z.infer<typeof envSchema>;

/** Si falta o es inválida una variable, la app no arranca. */
export function validateEnv(raw: Record<string, unknown>): Env {
  const result = envSchema.safeParse(raw);
  if (!result.success) {
    throw new Error(`Variables de entorno inválidas:\n${z.prettifyError(result.error)}`);
  }
  return result.data;
}
