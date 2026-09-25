/** Entorno de los tests e2e. Nunca apunta a la base de desarrollo. */
export const TEST_ENV = {
  NODE_ENV: 'test',
  DATABASE_URL: process.env.TEST_DATABASE_URL ?? 'postgresql://chaski:chaski@localhost:5433/chaski_test',
  JWT_ACCESS_SECRET: 'test-secret-test-secret-test-secret-123',
  OTP_DEV_CODE: '123456',
  // Sin espera de reenvío: cada test pide códigos seguidos (el límite se prueba en unit tests).
  OTP_RESEND_SECONDS: '0',
  LOG_LEVEL: 'silent',
};

Object.assign(process.env, TEST_ENV);
