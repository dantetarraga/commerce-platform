import { SmsDeliveryError, SmsInvalidNumberError, TwilioSmsSender } from './sms-sender';

const SID = `AC${'a'.repeat(32)}`;
const MG = `MG${'b'.repeat(32)}`;

function sender(response: Response | Error) {
  const fetchImpl = jest.fn(() => (response instanceof Error ? Promise.reject(response) : Promise.resolve(response)));
  const twilio = new TwilioSmsSender(
    { accountSid: SID, authToken: 'token-token-token-1', countryCode: '+51', messagingServiceSid: MG },
    fetchImpl,
  );
  return { twilio, fetchImpl };
}

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

describe('TwilioSmsSender', () => {
  it('envía al número con prefijo del país por el Messaging Service', async () => {
    const { twilio, fetchImpl } = sender(json(201, { sid: 'SM1' }));
    await twilio.send('987654321', 'Tu código es 123456');

    const [url, init] = fetchImpl.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe(`https://api.twilio.com/2010-04-01/Accounts/${SID}/Messages.json`);
    expect(init.method).toBe('POST');
    expect((init.headers as Record<string, string>).Authorization).toBe(
      `Basic ${Buffer.from(`${SID}:token-token-token-1`).toString('base64')}`,
    );
    const body = init.body as URLSearchParams;
    expect(body.get('To')).toBe('+51987654321');
    expect(body.get('MessagingServiceSid')).toBe(MG);
    expect(body.get('Body')).toBe('Tu código es 123456');
  });

  it('número inválido → SmsInvalidNumberError', async () => {
    const { twilio } = sender(json(400, { code: 21211, message: "The 'To' number is not a valid phone number." }));
    await expect(twilio.send('987654321', 'x')).rejects.toBeInstanceOf(SmsInvalidNumberError);
  });

  it('error del servicio o sin respuesta → SmsDeliveryError', async () => {
    await expect(sender(json(500, {})).twilio.send('987654321', 'x')).rejects.toBeInstanceOf(SmsDeliveryError);
    await expect(sender(new Error('ECONNRESET')).twilio.send('987654321', 'x')).rejects.toBeInstanceOf(
      SmsDeliveryError,
    );
  });
});
