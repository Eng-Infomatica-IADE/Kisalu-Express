import 'dotenv/config';

function num(name: string, fallback: number): number {
  const v = process.env[name];
  return v === undefined || v === '' ? fallback : Number(v);
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: num('PORT', 3000),
  db: {
    host: process.env.DB_HOST ?? 'localhost',
    port: num('DB_PORT', 3306),
    user: process.env.DB_USER ?? 'root',
    password: process.env.DB_PASSWORD ?? '',
    database: process.env.DB_NAME ?? 'kisalu_express',
  },
  jwtSecret: process.env.JWT_SECRET ?? 'dev-secret-mudar',
  jwtExpiresDays: num('JWT_EXPIRES_DAYS', 30),
  codigoExpiresMin: num('CODIGO_EXPIRES_MIN', 10),
  codigoMaxPer10Min: num('CODIGO_MAX_POR_10MIN', process.env.NODE_ENV === 'test' ? 1000 : 3),
  sms: {
    expiraMin: num('SMS_EXPIRES_MIN', 5), // validade do código enviado por SMS
    reenviarS: num('SMS_REENVIAR_S', 60), // espera mínima entre dois pedidos de código
  },
  /** Fora de produção, o código alternativo ao QR pode ser fixo (ex.: 482173) para demonstrações */
  codigoQrFixoDev: /^\d{6}$/.test(process.env.CODIGO_QR_FIXO_DEV ?? '') && process.env.NODE_ENV !== 'production'
    ? process.env.CODIGO_QR_FIXO_DEV!
    : null,
  qrValidadeMin: num('QR_VALIDADE_MIN', 10),
  desfazerAceitacaoMin: num('DESFAZER_ACEITACAO_MIN', 5),
  smtp: {
    host: process.env.SMTP_HOST ?? '',
    port: num('SMTP_PORT', 587),
    secure: process.env.SMTP_SECURE === 'true', // true para a porta 465
    user: process.env.SMTP_USER ?? '',
    password: process.env.SMTP_PASSWORD ?? '',
  },
  emailFrom: process.env.EMAIL_FROM ?? 'Kisalu Express <nao-responder@kisalu.ao>',
  uploadDir: process.env.UPLOAD_DIR ?? 'uploads',
  /** Documentos de identidade e fotos de reclamações: fora da pasta pública, só servidos ao admin */
  privadoDir: process.env.PRIVADO_DIR ?? 'privado',
  /** Origens autorizadas pelo CORS (separadas por vírgulas). Vazio = todas, só fora de produção. */
  corsOrigins: (process.env.CORS_ORIGINS ?? '').split(',').map((o) => o.trim()).filter(Boolean),
  uploadMaxMb: num('UPLOAD_MAX_MB', 5),
};

export const isProduction = env.nodeEnv === 'production';

if (isProduction && env.jwtSecret === 'dev-secret-mudar') {
  throw new Error('Defina JWT_SECRET no ambiente de produção.');
}

if (isProduction && env.corsOrigins.length === 0) {
  throw new Error('Defina CORS_ORIGINS no ambiente de produção (ex.: https://app.kisalu.ao).');
}
