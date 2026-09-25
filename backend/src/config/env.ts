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
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  })
  .refine((env) => !(env.NODE_ENV === 'production' && env.OTP_DEV_CODE), {
    message: 'OTP_DEV_CODE no se permite en producción',
    path: ['OTP_DEV_CODE'],
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
