import { validateEnv } from './env';

const base = {
  DATABASE_URL: 'postgresql://u:p@localhost:5432/db',
  JWT_ACCESS_SECRET: 'j'.repeat(32),
  OTP_SECRET: 'o'.repeat(32),
};
const twilio = {
  SMS_PROVIDER: 'twilio',
  TWILIO_ACCOUNT_SID: `AC${'a'.repeat(32)}`,
  TWILIO_AUTH_TOKEN: 't'.repeat(32),
  TWILIO_MESSAGING_SERVICE_SID: `MG${'b'.repeat(32)}`,
};

describe('validateEnv', () => {
  it('desarrollo arranca con SMS al log', () => {
    expect(validateEnv(base)).toMatchObject({ NODE_ENV: 'development', SMS_PROVIDER: 'log', TRUST_PROXY: 0 });
  });

  it('producción exige Twilio y prohíbe el código fijo', () => {
    expect(() => validateEnv({ ...base, NODE_ENV: 'production' })).toThrow(/SMS_PROVIDER/);
    expect(() => validateEnv({ ...base, ...twilio, NODE_ENV: 'production', OTP_DEV_CODE: '123456' })).toThrow(
      /OTP_DEV_CODE/,
    );
    expect(validateEnv({ ...base, ...twilio, NODE_ENV: 'production' }).SMS_PROVIDER).toBe('twilio');
  });

  it('Twilio sin credenciales no arranca', () => {
    expect(() => validateEnv({ ...base, SMS_PROVIDER: 'twilio' })).toThrow(/TWILIO_ACCOUNT_SID/);
  });

  it('el secreto del OTP no puede ser el del JWT', () => {
    expect(() => validateEnv({ ...base, OTP_SECRET: base.JWT_ACCESS_SECRET })).toThrow(/OTP_SECRET/);
  });
});
