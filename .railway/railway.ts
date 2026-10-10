// Infraestructura de Apamuy en Railway. Aplicar con `railway config plan` y `railway config apply`.
// Los secretos no van aquí: preserve() conserva el valor cargado en Railway (ver backend/README.md).
import { defineRailway, github, postgres, preserve, project, service } from 'railway/iac';

export default defineRailway(() => {
  const db = postgres('postgres');

  const api = service('api', {
    source: github('dantetarraga/commerce-platform', { branch: 'main', rootDirectory: 'backend' }),
    build: {
      builder: 'DOCKERFILE',
      dockerfilePath: 'Dockerfile',
      watchPatterns: ['/backend/**'],
    },
    deploy: {
      // Migraciones pendientes antes de poner la versión nueva en línea.
      preDeployCommand: ['npx prisma migrate deploy'],
      healthcheckPath: '/api/v1/health',
      healthcheckTimeout: 60,
      restartPolicyType: 'ON_FAILURE',
    },
    env: {
      NODE_ENV: 'production',
      DATABASE_URL: db.env.DATABASE_URL,
      TRUST_PROXY: '1',
      LOG_LEVEL: 'info',
      SMS_PROVIDER: 'twilio',
      SMS_COUNTRY_CODE: '+51',
      PUSH_PROVIDER: 'fcm',
      JWT_ACCESS_SECRET: preserve(),
      OTP_SECRET: preserve(),
      TWILIO_ACCOUNT_SID: preserve(),
      TWILIO_AUTH_TOKEN: preserve(),
      TWILIO_MESSAGING_SERVICE_SID: preserve(),
      FCM_SERVICE_ACCOUNT_BASE64: preserve(),
    },
  });

  return project('apamuy', { resources: [db, api] });
});
