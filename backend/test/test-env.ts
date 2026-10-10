/** Entorno de los tests e2e. Nunca apunta a la base de desarrollo. */
export const TEST_ENV = {
  NODE_ENV: 'test',
  DATABASE_URL: process.env.TEST_DATABASE_URL ?? 'postgresql://apamuy:apamuy@localhost:5433/apamuy_test',
  JWT_ACCESS_SECRET: 'test-secret-test-secret-test-secret-123',
  OTP_SECRET: 'test-otp-secret-test-otp-secret-12345',
  OTP_DEV_CODE: '123456',
  // Sin espera de reenvío: cada test pide códigos seguidos (el límite se prueba en unit tests).
  OTP_RESEND_SECONDS: '0',
  LOG_LEVEL: 'silent',
};

Object.assign(process.env, TEST_ENV);
