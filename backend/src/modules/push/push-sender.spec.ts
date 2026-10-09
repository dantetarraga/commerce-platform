import { generateKeyPairSync } from 'node:crypto';
import { FcmPushSender, PushMessage, toFcmMessage } from './push-sender';

const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const account = {
  project_id: 'apamuy-test',
  client_email: 'push@apamuy-test.iam.gserviceaccount.com',
  private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }).toString(),
};

const message: PushMessage = {
  title: 'Pedido confirmado',
  body: 'Doña Rosa recibió tu pedido #2481',
  data: { kind: 'ORDER_CONFIRMED', orderId: 'or_1' },
  channel: 'orders',
};

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

describe('FcmPushSender', () => {
  it('pide un token OAuth una vez y lo reusa para varios envíos', async () => {
    const fetchImpl = jest.fn((url: string) =>
      Promise.resolve(url.includes('oauth2') ? json(200, { access_token: 'ya29.x', expires_in: 3600 }) : json(200, {})),
    );
    const sender = new FcmPushSender(account, fetchImpl);

    await sender.send(['t1', 't2'], message);
    await sender.send(['t3'], message);

    const oauthCalls = fetchImpl.mock.calls.filter(([url]) => url.includes('oauth2'));
    expect(oauthCalls).toHaveLength(1);
    expect(fetchImpl).toHaveBeenCalledTimes(4);
    expect(fetchImpl.mock.calls[1][0]).toBe('https://fcm.googleapis.com/v1/projects/apamuy-test/messages:send');
  });

  it('devuelve los tokens que FCM ya no reconoce', async () => {
    const fetchImpl = jest.fn((url: string, init: RequestInit) => {
      if (url.includes('oauth2')) return Promise.resolve(json(200, { access_token: 'ya29.x', expires_in: 3600 }));
      const token = (JSON.parse(init.body as string) as { message: { token: string } }).message.token;
      return Promise.resolve(
        token === 'viejo'
          ? json(404, {
              error: { message: 'Requested entity was not found.', details: [{ errorCode: 'UNREGISTERED' }] },
            })
          : json(200, {}),
      );
    });
    const sender = new FcmPushSender(account, fetchImpl);

    await expect(sender.send(['nuevo', 'viejo'], message)).resolves.toEqual({ invalidTokens: ['viejo'] });
  });
});

describe('toFcmMessage', () => {
  it('con título va como notificación en su canal de Android', () => {
    expect(toFcmMessage('t1', message)).toMatchObject({
      token: 't1',
      notification: { title: 'Pedido confirmado' },
      android: { priority: 'HIGH', notification: { channel_id: 'orders' } },
    });
  });

  it('la alarma va solo con datos y vence', () => {
    const alarm = toFcmMessage('t1', {
      data: { type: 'NEW_ORDER', orderId: 'or_1' },
      channel: 'order_alarm',
      ttlSeconds: 480,
    });
    expect(alarm).not.toHaveProperty('notification');
    expect(alarm.android).toEqual({ priority: 'HIGH', ttl: '480s' });
  });
});
