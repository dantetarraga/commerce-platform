import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types';

export const API = '/api/v1';
export const OTP_CODE = '123456'; // OTP_DEV_CODE del entorno de test

export interface TestSession {
  accessToken: string;
  refreshToken: string;
  user: { id: string };
  auth: { Authorization: string };
}

/** Crea una cuenta CUSTOMER con ese celular y devuelve su sesión. */
export async function signUp(app: INestApplication<App>, phone: string): Promise<TestSession> {
  const http = () => request(app.getHttpServer());
  await http().post(`${API}/auth/otp/request`).send({ phone }).expect(200);
  const verified = await http().post(`${API}/auth/otp/verify`).send({ phone, code: OTP_CODE }).expect(200);
  const { body } = await http()
    .post(`${API}/auth/register`)
    .send({ registrationToken: verified.body.registrationToken, firstName: 'Test', lastName: 'User' })
    .expect(201);
  const session = body as Omit<TestSession, 'auth'>;
  return { ...session, auth: { Authorization: `Bearer ${session.accessToken}` } };
}

/** Entra con una cuenta que ya existe (usuarios del seed: merchant, courier, admin). */
export async function logIn(app: INestApplication<App>, phone: string): Promise<TestSession> {
  const http = () => request(app.getHttpServer());
  await http().post(`${API}/auth/otp/request`).send({ phone }).expect(200);
  const { body } = await http().post(`${API}/auth/otp/verify`).send({ phone, code: OTP_CODE }).expect(200);
  const session = body as Omit<TestSession, 'auth'> & { status: string };
  if (session.status !== 'AUTHENTICATED') throw new Error(`${phone} no tiene cuenta en el seed`);
  return { ...session, auth: { Authorization: `Bearer ${session.accessToken}` } };
}
