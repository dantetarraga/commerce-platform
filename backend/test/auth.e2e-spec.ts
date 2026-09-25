import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';
import { createTestApp } from './test-app';

const API = '/api/v1';
const CODE = '123456'; // OTP_DEV_CODE del entorno de test

describe('Auth (e2e)', () => {
  let app: INestApplication<App>;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  async function verify(phone: string) {
    await http().post(`${API}/auth/otp/request`).send({ phone }).expect(200);
    return http().post(`${API}/auth/otp/verify`).send({ phone, code: CODE }).expect(200);
  }

  /** Cuenta nueva con un celular distinto por test (hay tope de códigos por hora). */
  let nextPhone = 955000000;
  async function signUp() {
    const phone = String(nextPhone++);
    const { body } = await verify(phone);
    const res = await http()
      .post(`${API}/auth/register`)
      .send({ registrationToken: body.registrationToken, firstName: 'Test', lastName: 'User' })
      .expect(201);
    return res.body as { accessToken: string; refreshToken: string; user: { id: string } };
  }

  it('número nuevo: OTP → PROFILE_REQUIRED → registro → /users/me', async () => {
    const challenge = await http().post(`${API}/auth/otp/request`).send({ phone: '911 222 333' }).expect(200);
    expect(challenge.body).toEqual({ phone: '911222333', resendAfterSeconds: expect.any(Number), codeLength: 6 });

    const verified = await http().post(`${API}/auth/otp/verify`).send({ phone: '911222333', code: CODE }).expect(200);
    expect(verified.body).toEqual({ status: 'PROFILE_REQUIRED', registrationToken: expect.any(String) });

    const registered = await http()
      .post(`${API}/auth/register`)
      .send({ registrationToken: verified.body.registrationToken, firstName: ' Rosa ', lastName: 'Huamán' })
      .expect(201);
    expect(registered.body).toEqual({
      user: {
        id: expect.any(String),
        phone: '911222333',
        firstName: 'Rosa',
        lastName: 'Huamán',
        email: null,
        avatarUrl: null,
        roles: ['CUSTOMER'],
      },
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
    });

    const me = await http()
      .get(`${API}/users/me`)
      .set('Authorization', `Bearer ${registered.body.accessToken}`)
      .expect(200);
    expect(me.body.id).toBe(registered.body.user.id);
  });

  it('cuenta existente: entra directo', async () => {
    const res = await verify('984123456');
    expect(res.body).toMatchObject({
      status: 'AUTHENTICATED',
      user: { id: 'usr_demo_customer', firstName: 'Alex', roles: ['CUSTOMER'] },
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
    });
  });

  it('código incorrecto, sin pedir código y código ya usado', async () => {
    await http().post(`${API}/auth/otp/request`).send({ phone: '922333444' }).expect(200);

    const wrong = await http().post(`${API}/auth/otp/verify`).send({ phone: '922333444', code: '000000' }).expect(422);
    expect(wrong.body).toMatchObject({ code: 'OTP_INVALID', requestId: expect.any(String) });

    const never = await http().post(`${API}/auth/otp/verify`).send({ phone: '933444555', code: CODE }).expect(409);
    expect(never.body.code).toBe('OTP_NOT_REQUESTED');

    // El código se consume: no sirve dos veces.
    await http().post(`${API}/auth/otp/verify`).send({ phone: '922333444', code: CODE }).expect(200);
    await http().post(`${API}/auth/otp/verify`).send({ phone: '922333444', code: CODE }).expect(409);
  });

  it('valida el celular con mensaje por campo', async () => {
    const res = await http().post(`${API}/auth/otp/request`).send({ phone: '12345' }).expect(400);
    expect(res.body).toMatchObject({
      statusCode: 400,
      code: 'VALIDATION_ERROR',
      details: { fields: { phone: 'Ingresa un celular de 9 dígitos que empiece con 9.' } },
    });
  });

  it('registration token no sirve como access token, ni al revés', async () => {
    const { body } = await verify('944555666');
    await http().get(`${API}/users/me`).set('Authorization', `Bearer ${body.registrationToken}`).expect(401);

    const session = await signUp();
    const res = await http()
      .post(`${API}/auth/register`)
      .send({ registrationToken: session.accessToken, firstName: 'X', lastName: 'Y' })
      .expect(401);
    expect(res.body.code).toBe('REGISTRATION_EXPIRED');
  });

  it('refresh rota el token y reusar uno viejo revoca la sesión', async () => {
    const first = (await signUp()).refreshToken;

    const rotated = await http().post(`${API}/auth/refresh`).send({ refreshToken: first }).expect(200);
    expect(rotated.body).toEqual({ accessToken: expect.any(String), refreshToken: expect.any(String) });
    expect(rotated.body.refreshToken).not.toBe(first);

    const reuse = await http().post(`${API}/auth/refresh`).send({ refreshToken: first }).expect(401);
    expect(reuse.body.code).toBe('INVALID_REFRESH_TOKEN');
    // Toda la familia quedó revocada, incluido el token nuevo.
    await http().post(`${API}/auth/refresh`).send({ refreshToken: rotated.body.refreshToken }).expect(401);
  });

  it('logout es idempotente y revoca el refresh token', async () => {
    const { refreshToken } = await signUp();
    await http().post(`${API}/auth/logout`).send({ refreshToken }).expect(204);
    await http().post(`${API}/auth/logout`).send({ refreshToken }).expect(204);
    await http().post(`${API}/auth/refresh`).send({ refreshToken }).expect(401);
  });

  it('PATCH /users/me no deja cambiar roles ni teléfono', async () => {
    const auth = { Authorization: `Bearer ${(await signUp()).accessToken}` };

    const denied = await http()
      .patch(`${API}/users/me`)
      .set(auth)
      .send({ roles: ['ADMIN'], phone: '999999999' })
      .expect(400);
    expect(Object.keys(denied.body.details.fields).sort()).toEqual(['phone', 'roles']);

    const updated = await http().patch(`${API}/users/me`).set(auth).send({ email: ' Test@Mail.com ' }).expect(200);
    expect(updated.body).toMatchObject({ email: 'test@mail.com', roles: ['CUSTOMER'] });
  });

  it('sin token → 401 con el formato estándar', async () => {
    const res = await http().get(`${API}/users/me`).set('X-Request-Id', 'e2e-request-0001').expect(401);
    expect(res.body).toEqual({
      statusCode: 401,
      code: 'UNAUTHORIZED',
      message: 'Inicia sesión para continuar.',
      requestId: 'e2e-request-0001',
    });
    expect(res.headers['x-request-id']).toBe('e2e-request-0001');
  });
});
